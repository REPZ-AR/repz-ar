import 'package:flutter/material.dart';
import 'package:repz/model/client.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/services/client_service.dart';
import 'package:repz/views/client_detail_page.dart';

class TrainerHomePage extends StatefulWidget {
  const TrainerHomePage({
    super.key,
    required this.isDarkMode,
    this.avatarUrl,
  });

  final bool isDarkMode;
  final String? avatarUrl;

  @override
  State<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends State<TrainerHomePage> {
  final ClientService _clientService = ClientService();
  final WorkoutPlanRepository _planRepository = WorkoutPlanRepository();

  bool _isLoading = true;
  List<_TrainerClientOverview> _overviews = const <_TrainerClientOverview>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _clientService.fetchClients();
      final overviews = <_TrainerClientOverview>[];

      for (final client in clients) {
        final activeStatus = await _planRepository.fetchClientActivePlanStatus(
          client.id,
        );
        final assignments = await _planRepository.fetchAssignmentsForClient(
          client.id,
        );

        overviews.add(
          _TrainerClientOverview(
            client: client,
            activeStatus: activeStatus,
            assignments: assignments,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _overviews = overviews);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not load trainer dashboard.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openClient(_TrainerClientOverview overview) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ClientDetailPage(
              client: overview.client,
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
      return const Center(child: CircularProgressIndicator());
    }

    final accentColor =
        widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = widget.isDarkMode ? Colors.white : Colors.black;
    final clientsWithActivePlan =
        _overviews.where((overview) => overview.activeStatus.todaysPlan != null).length;
    final clientsNeedingAttention = _overviews.where((overview) {
      final plan = overview.activeStatus.todaysPlan;
      if (plan == null || plan.exercises.isEmpty) return true;
      return overview.activeStatus.currentWorkoutIndex <= 0;
    }).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Client Progress',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: primaryText,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accentColor,
                  backgroundImage:
                      (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                  child:
                      (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                          ? const Icon(Icons.person, color: Colors.black)
                          : null,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TrainerStatCard(
                    title: 'Active Clients',
                    value: '${_overviews.length}',
                    accentColor: accentColor,
                    cardColor: cardColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrainerStatCard(
                    title: 'Following Plans',
                    value: '$clientsWithActivePlan',
                    accentColor: accentColor,
                    cardColor: cardColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrainerStatCard(
                    title: 'Need Attention',
                    value: '$clientsNeedingAttention',
                    accentColor: accentColor,
                    cardColor: cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spotlight Clients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_overviews.isEmpty)
                    const Text('No clients connected yet.')
                  else
                    ..._overviews.take(4).map(
                      (overview) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _openClient(overview),
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: accentColor.withValues(alpha: 0.2),
                                  child: Text(
                                    overview.client.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: widget.isDarkMode
                                          ? accentColor
                                          : Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        overview.client.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        overview.activeStatus.todaysPlan?.name ??
                                            'No active plan today',
                                        style: TextStyle(
                                          color: primaryText.withValues(alpha: 0.68),
                                          fontSize: 12,
                                        ),
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

class _TrainerClientOverview {
  const _TrainerClientOverview({
    required this.client,
    required this.activeStatus,
    required this.assignments,
  });

  final Client client;
  final ClientActivePlanStatus activeStatus;
  final List<WorkoutPlanAssignment> assignments;
}

class _TrainerStatCard extends StatelessWidget {
  const _TrainerStatCard({
    required this.title,
    required this.value,
    required this.accentColor,
    required this.cardColor,
  });

  final String title;
  final String value;
  final Color accentColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
