import 'package:flutter/material.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/views/weekly_schedule_page.dart';
import 'package:repz/views/workout_plan_helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrebuiltWorkoutPlansPage extends StatefulWidget {
  const PrebuiltWorkoutPlansPage({
    super.key,
    this.highlightPlanId,
  });

  final String? highlightPlanId;

  @override
  State<PrebuiltWorkoutPlansPage> createState() => _PrebuiltWorkoutPlansPageState();
}

class _PrebuiltWorkoutPlansPageState extends State<PrebuiltWorkoutPlansPage> {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  bool _isLoading = true;
  List<PrebuiltWorkoutPlan> _plans = const <PrebuiltWorkoutPlan>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _repository.fetchPrebuiltPlans();
      if (!mounted) return;
      setState(() => _plans = plans);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not load pre-built plans.');
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

  Future<WorkoutPlan?> _copyPlan(
    PrebuiltWorkoutPlan plan, {
    bool setActive = false,
  }) async {
    try {
      final copied = await _repository.copyPrebuiltPlanToUser(
        plan.id,
        setActive: setActive,
      );
      _showMessage('"${plan.name}" added to your plans.');
      return copied;
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not copy the pre-built plan.');
    }
    return null;
  }

  Future<void> _startPlan(PrebuiltWorkoutPlan plan) async {
    final copied = await _copyPlan(plan, setActive: true);
    if (copied == null || !mounted) return;
    await WorkoutPlanHelpers.startPlan(context, copied);
  }

  Future<void> _schedulePlan(PrebuiltWorkoutPlan plan) async {
    final copied = await _copyPlan(plan);
    if (copied == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WeeklySchedulePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-built Plans')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final isHighlighted = widget.highlightPlanId == plan.id;

                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isHighlighted
                          ? accentColor
                          : accentColor.withValues(alpha: 0.16),
                      width: isHighlighted ? 2 : 1,
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
                              child: Text(
                                plan.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (plan.isFeatured)
                              Chip(
                                label: const Text('Recommended'),
                                backgroundColor: accentColor.withValues(alpha: 0.18),
                              ),
                          ],
                        ),
                        if ((plan.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(plan.description!),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if ((plan.difficulty ?? '').isNotEmpty)
                              Chip(label: Text(plan.difficulty!)),
                            if ((plan.goalTag ?? '').isNotEmpty)
                              Chip(label: Text(plan.goalTag!)),
                            Chip(
                              label: Text(
                                '${plan.exercises.length} exercises',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                                onPressed: () => _copyPlan(plan),
                                icon: const Icon(Icons.playlist_add_rounded),
                                label: const Text('Follow'),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _schedulePlan(plan),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('Copy and Schedule'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
