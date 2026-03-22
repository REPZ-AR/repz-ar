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
    this.userName,
    this.onNavigateToClients,
  });

  final bool isDarkMode;
  final String? avatarUrl;
  final String? userName;
  final VoidCallback? onNavigateToClients;

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
        overviews.add(_TrainerClientOverview(
          client: client,
          activeStatus: activeStatus,
          assignments: assignments,
        ));
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openClient(_TrainerClientOverview overview) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDetailPage(
          client: overview.client,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
    if (mounted) await _load();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Coach';
    return name.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final accentColor =
    widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor =
    widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor =
    widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F4F4);
    final primaryText = widget.isDarkMode ? Colors.white : Colors.black;
    final subText = widget.isDarkMode
        ? Colors.white54
        : const Color(0xFF888888);

    final clientsWithActivePlan = _overviews
        .where((o) => o.activeStatus.todaysPlan != null)
        .length;
    final clientsNeedingAttention = _overviews.where((o) {
      final plan = o.activeStatus.todaysPlan;
      if (plan == null || plan.exercises.isEmpty) return true;
      return o.activeStatus.currentWorkoutIndex <= 0;
    }).length;

    // insight message
    String insightMessage = '';
    if (_overviews.isEmpty) {
      insightMessage = 'Add your first client to get started!';
    } else if (clientsNeedingAttention > 0) {
      insightMessage =
      '$clientsNeedingAttention client${clientsNeedingAttention > 1 ? 's' : ''} haven\'t started their plan today.';
    } else {
      insightMessage = 'All clients are on track today. Great work!';
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: accentColor,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(fontSize: 14, color: subText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _firstName(widget.userName),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        _formattedDate(),
                        style: TextStyle(fontSize: 12, color: subText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Larger avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: accentColor.withAlpha(40),
                    backgroundImage:
                    (widget.avatarUrl != null &&
                        widget.avatarUrl!.isNotEmpty)
                        ? NetworkImage(widget.avatarUrl!)
                        : null,
                    child: (widget.avatarUrl == null ||
                        widget.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, color: accentColor, size: 28)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Insight card ─────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(
                    clientsNeedingAttention > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insightMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats cards ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _TrainerStatCard(
                    title: 'Clients',
                    value: '${_overviews.length}',
                    icon: Icons.people_rounded,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    borderColor: const Color(0xFF42A5F5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrainerStatCard(
                    title: 'On Plan',
                    value: '$clientsWithActivePlan',
                    icon: Icons.check_circle_rounded,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    borderColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrainerStatCard(
                    title: 'Attention',
                    value: '$clientsNeedingAttention',
                    icon: Icons.warning_rounded,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    borderColor: const Color(0xFFFFC107),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Spotlight Clients ────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spotlight Clients',
                        style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_overviews.isNotEmpty)
                        GestureDetector(
                          onTap: widget.onNavigateToClients,
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_overviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No clients connected yet.',
                        style: TextStyle(color: subText),
                      ),
                    )
                  else
                    ..._overviews.take(4).map((overview) {
                      final plan = overview.activeStatus.todaysPlan;
                      final total = plan?.exercises.length ?? 0;
                      final completed =
                          overview.activeStatus.currentWorkoutIndex;
                      final progress =
                      total > 0 ? completed / total : 0.0;
                      final needsAttention = plan == null ||
                          plan.exercises.isEmpty ||
                          overview.activeStatus.currentWorkoutIndex <= 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _openClient(overview),
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Avatar with status dot
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                          accentColor.withAlpha(40),
                                          backgroundImage: overview
                                              .client.avatarUrl !=
                                              null
                                              ? NetworkImage(
                                              overview.client.avatarUrl!)
                                              : null,
                                          child:
                                          overview.client.avatarUrl == null
                                              ? Text(
                                            overview.client.name
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: widget.isDarkMode
                                                  ? accentColor
                                                  : Colors.black,
                                              fontWeight:
                                              FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: needsAttention
                                                  ? const Color(0xFFFFC107)
                                                  : const Color(0xFF4CAF50),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: cardColor,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            overview.client.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            plan?.name ?? 'No active plan today',
                                            style: TextStyle(
                                              color: subText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Exercises count
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          total > 0
                                              ? '$completed/$total'
                                              : '-',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: accentColor,
                                          ),
                                        ),
                                        Text(
                                          'exercises',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: subText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 20),
                                  ],
                                ),
                                // Progress bar
                                if (total > 0) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor:
                                      accentColor.withAlpha(30),
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          accentColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick Actions ────────────────────────────────
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'Add Client',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add Client — coming soon')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Create Plan',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Create Plan — coming soon')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.calendar_month_rounded,
                    label: 'Schedule',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Schedule — coming soon')),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Today's Sessions ─────────────────────────────
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
                    "Today's Sessions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_overviews.isEmpty)
                    Text('No sessions today.',
                        style: TextStyle(color: subText))
                  else
                    ..._overviews.map((o) {
                      final plan = o.activeStatus.todaysPlan;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.fitness_center_rounded,
                                  color: accentColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.client.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    plan?.name ?? 'No plan assigned',
                                    style: TextStyle(
                                        fontSize: 12, color: subText),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: plan != null
                                    ? const Color(0xFF4CAF50).withAlpha(30)
                                    : const Color(0xFFFFC107).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan != null ? 'Active' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: plan != null
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFFC107),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    final days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

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
    required this.icon,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.cardColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}