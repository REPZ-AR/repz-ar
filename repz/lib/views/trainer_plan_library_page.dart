import 'package:flutter/material.dart';
import 'package:repz/model/client.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/services/client_service.dart';
import 'package:repz/views/workout_builder_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerPlanLibraryPage extends StatefulWidget {
  const TrainerPlanLibraryPage({
    super.key,
    required this.isDarkMode,
    this.preselectedClientId,
  });

  final bool isDarkMode;
  final String? preselectedClientId;

  @override
  State<TrainerPlanLibraryPage> createState() => _TrainerPlanLibraryPageState();
}

class _TrainerPlanLibraryPageState extends State<TrainerPlanLibraryPage> {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  final ClientService _clientService = ClientService();

  bool _isLoading = true;
  List<WorkoutPlan> _plans = const <WorkoutPlan>[];
  List<Client> _clients = const <Client>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _repository.fetchTrainerTemplates();
      final clients = await _clientService.fetchClients();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _clients = clients;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not load client plans.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openBuilder({WorkoutPlan? plan}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => WorkoutBuilderPage(
              initialPlan: plan,
              planScope: WorkoutPlanScope.trainerTemplate,
            ),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _deletePlan(WorkoutPlan plan) async {
    try {
      await _repository.deletePlan(plan.id!);
      await _load();
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this client plan.')),
      );
    }
  }

  Future<void> _assignPlan(WorkoutPlan plan) async {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clients are connected yet.')),
      );
      return;
    }

    final selectedClientIds = <String>{
      if (widget.preselectedClientId != null) widget.preselectedClientId!,
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Assign Plan to Clients'),
                content: SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _clients.map((client) {
                        return CheckboxListTile(
                          value: selectedClientIds.contains(client.id),
                          contentPadding: EdgeInsets.zero,
                          title: Text(client.name),
                          subtitle: Text(client.subtitle),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                selectedClientIds.add(client.id);
                              } else {
                                selectedClientIds.remove(client.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed:
                        selectedClientIds.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(true),
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          ),
    );

    if (confirmed != true) return;

    try {
      for (final clientId in selectedClientIds) {
        await _repository.assignTrainerPlanToClient(
          clientId: clientId,
          trainerPlan: plan,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Assigned "${plan.name}" to ${selectedClientIds.length} client${selectedClientIds.length == 1 ? '' : 's'}.',
            ),
          ),
        );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not assign this plan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Client Plan Library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBuilder(),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Client Plan'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child:
                    _plans.isEmpty
                        ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No trainer plans yet. Create one to assign to clients.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _plans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${plan.exercises.length} exercises',
                                    ),
                                    if ((plan.notes ?? '').trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(plan.notes!),
                                    ],
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          plan.exercises
                                              .take(4)
                                              .map(
                                                (exercise) => Chip(
                                                  label: Text(exercise.displayName),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () => _assignPlan(plan),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: accentColor,
                                              foregroundColor: Colors.black,
                                            ),
                                            icon: const Icon(
                                              Icons.playlist_add_check_rounded,
                                            ),
                                            label: const Text('Assign'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _openBuilder(plan: plan),
                                            icon: const Icon(Icons.edit_outlined),
                                            label: const Text('Edit'),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _deletePlan(plan),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
