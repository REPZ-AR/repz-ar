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

  Future<void> _startSingleExercise(Exercise exercise) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => PoseDetectorView(
          exercises: [exercise],
          initialIndex: 0,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
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
              const SizedBox(height: 20),
              Text(
                'Available Exercises',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              if (_exercises.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No exercises available.',
                    style: TextStyle(color: textColor),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AvailableExerciseCard(
                        exercise: exercise,
                        accentColor: accentColor,
                        cardColor: cardColor,
                        textColor: textColor,
                        isDarkMode: widget.isDarkMode,
                        onStart: () => _startSingleExercise(exercise),
                      ),
                    );
                  },
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

class _TodaysPlanCard extends StatelessWidget {
  const _TodaysPlanCard({
    required this.plan,
    required this.currentWorkoutIndex,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.onStart,
  });

  final WorkoutPlan plan;
  final int currentWorkoutIndex;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final safeIndex =
    plan.exercises.isEmpty
        ? 0
        : currentWorkoutIndex.clamp(0, plan.exercises.length - 1).toInt();

    final featuredExercise =
    plan.exercises.isEmpty ? null : plan.exercises[safeIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      featuredExercise == null
                          ? 'No exercises added yet.'
                          : 'Current focus: ${featuredExercise.displayName}\nExercises: ${plan.exercises.length}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.68),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onStart,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: plan.exercises.length,
              itemBuilder: (context, index) {
                final exercise = plan.exercises[index];
                final totalReps = exercise.sets.fold<int>(
                  0,
                      (sum, set) => sum + set.reps,
                );
                final setCount = exercise.sets.length;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _ExerciseItem(
                    exercise.displayName,
                    '${(setCount * 3).clamp(3, 60)} min',
                    '$setCount sets / $totalReps reps',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard({
    required this.accentColor,
    required this.cardColor,
    required this.onOpenSchedule,
  });

  final Color accentColor;
  final Color cardColor;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No active plan for today',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set one of your saved plans for this weekday to see it here.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onOpenSchedule,
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}

class _RecommendedPlanCard extends StatelessWidget {
  const _RecommendedPlanCard({
    required this.plan,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.onFollow,
    required this.onViewPlans,
  });

  final PrebuiltWorkoutPlan plan;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onFollow;
  final VoidCallback onViewPlans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No active plans for today. Would you like to follow this plan?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.description ?? 'A recommended pre-built plan for today.',
            style: TextStyle(color: textColor.withOpacity(0.72)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((plan.difficulty ?? '').isNotEmpty)
                Chip(label: Text(plan.difficulty!)),
              if ((plan.goalTag ?? '').isNotEmpty)
                Chip(label: Text(plan.goalTag!)),
              Chip(label: Text('${plan.exercises.length} exercises')),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.exercises.take(3).map(
                (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ExerciseItem(
                exercise.displayName,
                '${exercise.sets.length} sets',
                '${exercise.sets.fold<int>(0, (sum, set) => sum + set.reps)} reps',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onFollow,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Follow Plan'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewPlans,
                  child: const Text('View Plans'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrowsePrebuiltCard extends StatelessWidget {
  const _BrowsePrebuiltCard({
    required this.accentColor,
    required this.cardColor,
    required this.onTap,
  });

  final Color accentColor;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accentColor.withOpacity(0.16),
              child: const Icon(Icons.auto_awesome_outlined, color: Colors.black),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore pre-built plans',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Browse curated templates and copy one into your own schedule.',
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _AvailableExerciseCard extends StatelessWidget {
  const _AvailableExerciseCard({
    required this.exercise,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDarkMode,
    required this.onStart,
  });

  final Exercise exercise;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDarkMode;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.16),
            child: const Icon(Icons.fitness_center, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.duration} • ${exercise.sets}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.type.dbValue,
                  style: TextStyle(
                    color: textColor.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: onStart,
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final String name;
  final String duration;
  final String sets;

  const _ExerciseItem(this.name, this.duration, this.sets);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(duration, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 10),
        Text(sets, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;
  final bool isDarkMode;

  const _StatCard({
    required this.title,
    required this.value,
    required this.accentColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool isDarkMode;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}