import 'package:flutter/material.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/views/workout_builder_page.dart';
import 'package:repz/views/workout_plan_helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedWorkoutPlansPage extends StatefulWidget {
  const SavedWorkoutPlansPage({super.key});

  @override
  State<SavedWorkoutPlansPage> createState() => _SavedWorkoutPlansPageState();
}

class _SavedWorkoutPlansPageState extends State<SavedWorkoutPlansPage> {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  bool _isLoading = true;
  List<WorkoutPlan> _plans = const <WorkoutPlan>[];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _repository.fetchPlans();
      if (!mounted) return;
      setState(() => _plans = plans);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not load saved plans.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBuilder({WorkoutPlan? plan}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => WorkoutBuilderPage(initialPlan: plan),
      ),
    );

    if (changed == true) {
      await _loadPlans();
    }
  }

  Future<void> _deletePlan(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Delete "${plan.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deletePlan(plan.id!);
      await _loadPlans();
      _showMessage('Plan deleted.');
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not delete the plan.');
    }
  }

  Future<void> _startPlan(WorkoutPlan plan) async {
    try {
      final saved = await _repository.savePlan(plan, setActive: true);
      if (!mounted) return;
      final started = await WorkoutPlanHelpers.startPlan(context, saved);
      if (!started) return;
      await _loadPlans();
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not start this plan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Plans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBuilder(),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlans,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _plans.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Icon(
                        Icons.playlist_add_check_circle_outlined,
                        size: 72,
                        color: accentColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved workout plans yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a plan from the camera menu or with the button below.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final subtitle =
                          '${plan.exercises.length} exercises | ${plan.exercises.fold<int>(0, (sum, exercise) => sum + exercise.sets.length)} sets';

                      return Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: plan.isActive
                                ? accentColor
                                : accentColor.withValues(alpha: 0.18),
                            width: plan.isActive ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(subtitle),
                                      ],
                                    ),
                                  ),
                                  if (plan.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? accentColor
                                              : Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if ((plan.notes ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(plan.notes!),
                              ],
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: plan.exercises
                                    .take(4)
                                    .map(
                                      (exercise) =>
                                          Chip(label: Text(exercise.displayName)),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openBuilder(plan: plan),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Edit'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _startPlan(plan),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.black,
                                      ),
                                      icon: const Icon(Icons.play_arrow_rounded),
                                      label: const Text('Start'),
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
