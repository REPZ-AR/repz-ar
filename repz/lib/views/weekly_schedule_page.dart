import 'package:flutter/material.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/views/prebuilt_workout_plans_page.dart';
import 'package:repz/views/workout_builder_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklySchedulePage extends StatefulWidget {
  const WeeklySchedulePage({super.key});

  @override
  State<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends State<WeeklySchedulePage> {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  bool _isLoading = true;
  List<WorkoutPlan> _plans = const <WorkoutPlan>[];
  Map<int, WorkoutPlanScheduleEntry> _scheduleByDay =
      const <int, WorkoutPlanScheduleEntry>{};

  static const Map<int, String> _weekdayLabels = <int, String>{
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.fetchPlans(),
        _repository.fetchSchedule(),
      ]);

      final plans = results[0] as List<WorkoutPlan>;
      final schedule = results[1] as List<WorkoutPlanScheduleEntry>;

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _scheduleByDay = {
          for (final entry in schedule) entry.dayOfWeek: entry,
        };
      });
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not load your weekly schedule.');
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

  Future<void> _setSchedule(int dayOfWeek, String? workoutPlanId) async {
    try {
      await _repository.setScheduleForDay(dayOfWeek, workoutPlanId);
      await _load();
      _showMessage(
        workoutPlanId == null
            ? '${_weekdayLabels[dayOfWeek]} cleared.'
            : '${_weekdayLabels[dayOfWeek]} updated.',
      );
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not update the schedule.');
    }
  }

  Future<void> _openBuilder() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const WorkoutBuilderPage()),
    );
    if (changed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assign one plan to each day',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Today\'s home card will automatically show the plan scheduled for that weekday.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrebuiltWorkoutPlansPage(),
                              ),
                            );
                            if (mounted) {
                              await _load();
                            }
                          },
                          child: const Text('Pre-built'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._weekdayLabels.entries.map((entry) {
                    final scheduleEntry = _scheduleByDay[entry.key];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: entry.key == today
                                ? accentColor
                                : accentColor.withValues(alpha: 0.16),
                            width: entry.key == today ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  entry.value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if (entry.key == today) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? accentColor
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              initialValue: scheduleEntry?.workoutPlanId,
                              decoration: const InputDecoration(
                                labelText: 'Assigned plan',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('No plan assigned'),
                                ),
                                ..._plans.map(
                                  (plan) => DropdownMenuItem<String?>(
                                    value: plan.id,
                                    child: Text(
                                      plan.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) => _setSchedule(entry.key, value),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
