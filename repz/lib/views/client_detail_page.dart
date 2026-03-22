import 'package:flutter/material.dart';
import 'package:repz/model/client.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/views/trainer_plan_library_page.dart';
import 'package:repz/views/trainer_schedule_editor_page.dart';

class ClientDetailPage extends StatefulWidget {
  const ClientDetailPage({
    super.key,
    required this.client,
    required this.isDarkMode,
  });

  final Client client;
  final bool isDarkMode;

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();

  bool _isLoading = true;
  ClientActivePlanStatus? _activeStatus;
  List<WorkoutPlanAssignment> _assignments = const <WorkoutPlanAssignment>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final activeStatus = await _repository.fetchClientActivePlanStatus(
        widget.client.id,
      );
      final assignments = await _repository.fetchAssignmentsForClient(
        widget.client.id,
      );

      if (!mounted) return;
      setState(() {
        _activeStatus = activeStatus;
        _assignments = assignments;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not load client details.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openPlanLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => TrainerPlanLibraryPage(
              isDarkMode: widget.isDarkMode,
              preselectedClientId: widget.client.id,
            ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openScheduleEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => TrainerScheduleEditorPage(
              client: widget.client,
              isDarkMode: widget.isDarkMode,
            ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final accentColor =
        widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final activeStatus = _activeStatus;

    return Scaffold(
      appBar: AppBar(title: Text(widget.client.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client\'s Active Schedule / Current Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activeStatus?.activeSourceLabel ?? 'No active schedule',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (activeStatus?.todaysPlan != null) ...[
                    Text(
                      activeStatus!.todaysPlan!.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Progress index: ${activeStatus.currentWorkoutIndex}/${activeStatus.todaysPlan!.exercises.isEmpty ? 0 : activeStatus.todaysPlan!.exercises.length - 1}',
                    ),
                  ] else
                    const Text('This client has no plan scheduled for today.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _openPlanLibrary,
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.playlist_add_check_rounded),
                          label: const Text('Assign Plan'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openScheduleEditor,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: const Text('Propose Schedule'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plans Assigned By You',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_assignments.isEmpty)
                    const Text('No plans assigned to this client yet.')
                  else
                    ..._assignments.map(
                      (assignment) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: accentColor.withValues(alpha: 0.08),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assignment.trainerPlan?.name ??
                                          assignment.clientPlan?.name ??
                                          'Assigned Plan',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${assignment.clientPlan?.exercises.length ?? 0} exercises',
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
