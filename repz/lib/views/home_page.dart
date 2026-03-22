import 'package:flutter/material.dart';
import 'package:repz/main.dart';
import 'package:repz/model/workout.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/exercise_repository.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/views/pose_detector_view.dart';
import 'package:repz/views/prebuilt_workout_plans_page.dart';
import 'package:repz/views/weekly_schedule_page.dart';
import 'package:repz/views/workout_plan_helpers.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final String? avatarUrl;
  final String userId;
  final WorkoutGateway workoutGateway;

  const HomePage({
    super.key,
    required this.isDarkMode,
    this.avatarUrl,
    required this.userId,
    required this.workoutGateway,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WorkoutPlanRepository _planRepository = WorkoutPlanRepository();

  int _currentWorkoutIndex = 0;
  bool _isLoading = true;
  WorkoutPlan? _todaysPlan;
  PrebuiltWorkoutPlan? _recommendedPlan;

  List<Exercise> _exercises = [];
  bool _isLoadingExercises = true;

  int get _todayWeekday => DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);

    try {
      final todayPlan = await _planRepository.fetchScheduledPlanForDay(
        _todayWeekday,
      );

      final recommendedPlan =
      todayPlan == null
          ? await _planRepository.fetchRecommendedPrebuiltPlan()
          : null;

      int savedIndex = 0;
      if (todayPlan?.id != null) {
        savedIndex = await widget.workoutGateway.fetchWorkoutProgress(
          widget.userId,
          workoutPlanId: todayPlan!.id,
        );
      }

      final maxIndex =
      todayPlan == null
          ? 0
          : (todayPlan.exercises.isEmpty
          ? 0
          : todayPlan.exercises.length - 1);

      if (!mounted) return;

      setState(() {
        _todaysPlan = todayPlan;
        _recommendedPlan = recommendedPlan;
        _currentWorkoutIndex = savedIndex.clamp(0, maxIndex).toInt();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not load today\'s workout data.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadExercises() async {
    try {
      final repo = ExerciseRepository();
      final data = await repo.fetchExercises();

      if (!mounted) return;

      setState(() {
        _exercises = data;
        _isLoadingExercises = false;
      });
    } catch (e) {
      debugPrint('Error loading exercises: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingExercises = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not load exercises.')),
        );
    }
  }

  Future<void> _startTodaysPlan() async {
    final plan = _todaysPlan;
    if (plan == null) return;

    final started = await WorkoutPlanHelpers.startPlan(context, plan);
    if (started && mounted) {
      await _loadHomeData();
    }
  }

  Future<void> _followRecommendedPlan() async {
    final recommendation = _recommendedPlan;
    if (recommendation == null) return;

    try {
      final copied = await _planRepository.copyPrebuiltPlanToUser(
        recommendation.id,
        setActive: true,
      );

      await _planRepository.setScheduleForDay(_todayWeekday, copied.id);

      await widget.workoutGateway.syncWorkoutProgress(
        widget.userId,
        0,
        workoutPlanId: copied.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '"${copied.name}" is now your active plan for today.',
            ),
          ),
        );

      await _loadHomeData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not follow the recommended plan.')),
        );
    }
  }

  Future<void> _openPrebuiltPlans() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => PrebuiltWorkoutPlansPage(
          highlightPlanId: _recommendedPlan?.id,
        ),
      ),
    );

    if (mounted) {
      await _loadHomeData();
    }
  }

  Future<void> _openWeeklySchedule() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const WeeklySchedulePage()));

    if (mounted) {
      await _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isLoadingExercises) {
      return const Center(child: CircularProgressIndicator());
    }

    final accentColor =
    widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor =
    widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadExercises();
          await _loadHomeData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Plan",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
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
              const SizedBox(height: 20),
              if (_todaysPlan != null)
                _TodaysPlanCard(
                  plan: _todaysPlan!,
                  currentWorkoutIndex: _currentWorkoutIndex,
                  accentColor: accentColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  onStart: _startTodaysPlan,
                )
              else
                _EmptyPlanCard(
                  accentColor: accentColor,
                  cardColor: cardColor,
                  onOpenSchedule: _openWeeklySchedule,
                ),
              const SizedBox(height: 14),
              if (_todaysPlan == null && _recommendedPlan != null) ...[
                _RecommendedPlanCard(
                  plan: _recommendedPlan!,
                  accentColor: accentColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  onFollow: _followRecommendedPlan,
                  onViewPlans: _openPrebuiltPlans,
                ),
                const SizedBox(height: 14),
              ],
              _BrowsePrebuiltCard(
                accentColor: accentColor,
                cardColor: cardColor,
                onTap: _openPrebuiltPlans,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Workouts\nCompleted',
                      value: '4/6',
                      accentColor: accentColor,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Streak\nScore',
                      value: '75',
                      accentColor: accentColor,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Next Rest in',
                      value: '2',
                      subtitle: 'Days',
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InfoCard(
                      title: 'Calory\nGoal',
                      value: '350',
                      subtitle: '',
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}