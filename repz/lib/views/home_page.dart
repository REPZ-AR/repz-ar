import 'package:flutter/material.dart';
import 'package:repz/main.dart';
import 'package:repz/model/profile_data.dart';
import 'package:repz/model/trainer.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/services/profile_service.dart';
import 'package:repz/services/trainer_service.dart';
import 'package:repz/views/prebuilt_workout_plans_page.dart';
import 'package:repz/views/weekly_schedule_page.dart';
import 'package:repz/views/workout_plan_helpers.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final String? avatarUrl;
  final String? userName;
  final String userId;
  final WorkoutGateway workoutGateway;

  const HomePage({
    super.key,
    required this.isDarkMode,
    this.avatarUrl,
    this.userName,
    required this.userId,
    required this.workoutGateway,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WorkoutPlanRepository _planRepository = WorkoutPlanRepository();
  final ProfileService _profileService = ProfileService();
  final TrainerService _trainerService = TrainerService();

  int _currentWorkoutIndex = 0;
  bool _isLoading = true;
  WorkoutPlan? _todaysPlan;
  PrebuiltWorkoutPlan? _recommendedPlan;
  ProfileData? _profile;
  List<Trainer> _trainers = [];

  final int _caloriesBurnt = 320;
  int _caloriesGoal = 500;

  int get _todayWeekday => DateTime.now().weekday;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'there';
    return name.trim().split(' ').first;
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

  Future<void> _editCalorieGoal() async {
    final controller =
    TextEditingController(text: '$_caloriesGoal');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Calorie Goal',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily calorie goal (kcal)',
            border: OutlineInputBorder(),
            suffixText: 'kcal',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value =
              int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _caloriesGoal = result);
    }
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _planRepository.fetchScheduledPlanForDay(_todayWeekday),
        _profileService.fetchCurrentUserProfile(),
        _trainerService.fetchTrainers(),
      ]);

      final todayPlan = results[0] as WorkoutPlan?;
      final profile = results[1] as ProfileData?;
      final trainers = results[2] as List<Trainer>;

      final recommendedPlan = todayPlan == null
          ? await _planRepository.fetchRecommendedPrebuiltPlan()
          : null;

      int savedIndex = 0;
      if (todayPlan?.id != null) {
        savedIndex =
        await widget.workoutGateway.fetchWorkoutProgress(
          widget.userId,
          workoutPlanId: todayPlan!.id,
        );
      }

      final maxIndex = todayPlan == null
          ? 0
          : (todayPlan.exercises.isEmpty
          ? 0
          : todayPlan.exercises.length - 1);

      if (!mounted) return;
      setState(() {
        _todaysPlan = todayPlan;
        _recommendedPlan = recommendedPlan;
        _currentWorkoutIndex =
            savedIndex.clamp(0, maxIndex).toInt();
        _profile = profile;
        _trainers = trainers;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
              content:
              Text('Could not load today\'s workout data.')),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _startTodaysPlan() async {
    final plan = _todaysPlan;
    if (plan == null) return;
    final started =
    await WorkoutPlanHelpers.startPlan(context, plan);
    if (started && mounted) await _loadHomeData();
  }

  Future<void> _followRecommendedPlan() async {
    final recommendation = _recommendedPlan;
    if (recommendation == null) return;
    try {
      final copied = await _planRepository.copyPrebuiltPlanToUser(
        recommendation.id,
        setActive: true,
      );
      await _planRepository.setScheduleForDay(
          _todayWeekday, copied.id);
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
                  '"${copied.name}" is now your active plan for today.')),
        );
      await _loadHomeData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
              content:
              Text('Could not follow the recommended plan.')),
        );
    }
  }

  Future<void> _openPrebuiltPlans() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrebuiltWorkoutPlansPage(
            highlightPlanId: _recommendedPlan?.id),
      ),
    );
    if (mounted) await _loadHomeData();
  }

  Future<void> _openWeeklySchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => const WeeklySchedulePage()),
    );
    if (mounted) await _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final accentColor = widget.isDarkMode
        ? const Color(0xFFCFF500)
        : const Color(0xFFA66CFF);
    final cardColor =
    widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor =
    widget.isDarkMode ? Colors.white : Colors.black;
    final subColor = widget.isDarkMode
        ? Colors.white54
        : const Color(0xFF888888);

    final bmi = _profile?.bmi;
    final calorieProgress = _caloriesBurnt / _caloriesGoal;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        color: accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: TextStyle(
                                fontSize: 14, color: subColor)),
                        const SizedBox(height: 2),
                        Text(
                          _firstName(widget.userName),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(_formattedDate(),
                            style: TextStyle(
                                fontSize: 12, color: subColor)),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: accentColor, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: accentColor.withAlpha(40),
                      backgroundImage: (widget.avatarUrl != null &&
                          widget.avatarUrl!.isNotEmpty)
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      child: (widget.avatarUrl == null ||
                          widget.avatarUrl!.isEmpty)
                          ? Icon(Icons.person,
                          color: accentColor, size: 26)
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Stats row ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'Workouts',
                      value: '4/6',
                      borderColor: accentColor,
                      accentColor: accentColor,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Streak',
                      value: '75',
                      borderColor: const Color(0xFFFF7043),
                      accentColor: accentColor,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.bolt_rounded,
                      title: 'Calories',
                      value: '$_caloriesBurnt',
                      borderColor: const Color(0xFFFFC107),
                      accentColor: accentColor,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Calories burnt progress bar ────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                                Icons
                                    .local_fire_department_rounded,
                                color: Color(0xFFFF7043),
                                size: 20),
                            const SizedBox(width: 8),
                            Text('Calories Burnt',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$_caloriesBurnt / $_caloriesGoal kcal',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subColor),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _editCalorieGoal,
                              child: Icon(Icons.edit_outlined,
                                  size: 16, color: subColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: calorieProgress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor:
                        const Color(0xFFFF7043).withAlpha(30),
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF7043)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_caloriesGoal - _caloriesBurnt).clamp(0, _caloriesGoal)} kcal remaining to reach your goal',
                      style: TextStyle(
                          fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Recommended plan card ──────────────────
              if (_recommendedPlan != null) ...[
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

              // ── Today's Plan / Empty plan card ─────────
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

              const SizedBox(height: 16),

              // ── Body stats card ────────────────────────
              if (_profile != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined,
                              color: accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text('Body Stats',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          _BodyStatItem(
                            label: 'Height',
                            value: _profile!.heightCm != null
                                ? '${_profile!.heightCm!.toStringAsFixed(0)} cm'
                                : '--',
                            icon: Icons.height_rounded,
                            color: const Color(0xFF42A5F5),
                            isDarkMode: widget.isDarkMode,
                          ),
                          _BodyStatItem(
                            label: 'Weight',
                            value: _profile!.weightKg != null
                                ? '${_profile!.weightKg!.toStringAsFixed(1)} kg'
                                : '--',
                            icon: Icons.monitor_weight_outlined,
                            color: const Color(0xFF26A69A),
                            isDarkMode: widget.isDarkMode,
                          ),
                          _BodyStatItem(
                            label: 'BMI',
                            value: bmi != null
                                ? bmi.toStringAsFixed(1)
                                : '--',
                            icon: Icons.calculate_outlined,
                            color: bmi == null
                                ? accentColor
                                : bmi < 18.5
                                ? const Color(0xFF42A5F5)
                                : bmi < 25
                                ? const Color(0xFF4CAF50)
                                : bmi < 30
                                ? const Color(
                                0xFFFFC107)
                                : const Color(
                                0xFFEF5350),
                            isDarkMode: widget.isDarkMode,
                          ),
                          _BodyStatItem(
                            label: 'Days/Week',
                            value: _profile!.frequency != null
                                ? '${_profile!.frequency}x'
                                : '--',
                            icon: Icons.calendar_today_rounded,
                            color: const Color(0xFFAB47BC),
                            isDarkMode: widget.isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Info cards row ─────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Next Rest in',
                      value: '2',
                      subtitle: 'Days',
                      icon: Icons.hotel_rounded,
                      borderColor: const Color(0xFF42A5F5),
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _editCalorieGoal,
                      child: _InfoCard(
                        title: 'Calory Goal',
                        value: '$_caloriesGoal',
                        subtitle: 'kcal',
                        icon: Icons.flag_rounded,
                        borderColor: const Color(0xFFFFC107),
                        isDarkMode: widget.isDarkMode,
                        showEditIcon: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Connected Trainers ─────────────────────
              if (_trainers.isNotEmpty) ...[
                Text(
                  'Your Trainer${_trainers.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                ..._trainers.map(
                      (trainer) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: accentColor.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                            accentColor.withAlpha(40),
                            backgroundImage:
                            trainer.avatarUrl != null
                                ? NetworkImage(
                                trainer.avatarUrl!)
                                : null,
                            child: trainer.avatarUrl == null
                                ? Text(
                              trainer.name
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trainer.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Your Trainer',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: subColor),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(20),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Explore pre-built plans (BOTTOM) ───────
              _BrowsePrebuiltCard(
                accentColor: accentColor,
                cardColor: cardColor,
                onTap: _openPrebuiltPlans,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color borderColor;
  final Color accentColor;
  final bool isDarkMode;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.borderColor,
    required this.accentColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
    isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
        Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: accentColor)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color borderColor;
  final bool isDarkMode;
  final bool showEditIcon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.borderColor,
    required this.isDarkMode,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
    isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
        Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 18),
              const Spacer(),
              if (showEditIcon)
                Icon(Icons.edit_outlined,
                    size: 14,
                    color: isDarkMode
                        ? Colors.white38
                        : Colors.black26),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BodyStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const _BodyStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey)),
      ],
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
    final safeIndex = plan.exercises.isEmpty
        ? 0
        : currentWorkoutIndex
        .clamp(0, plan.exercises.length - 1)
        .toInt();
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
                    Text(plan.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const SizedBox(height: 8),
                    Text(
                      featuredExercise == null
                          ? 'No exercises added yet.'
                          : 'Current focus: ${featuredExercise.displayName}\nExercises: ${plan.exercises.length}',
                      style: TextStyle(
                          color:
                          textColor.withValues(alpha: 0.68),
                          fontSize: 12),
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
                      shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.black, size: 32),
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
                final totalReps = exercise.sets
                    .fold<int>(0, (sum, set) => sum + set.reps);
                final setCount = exercise.sets.length;
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 6),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border:
        Border.all(color: accentColor.withAlpha(30), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.calendar_today_rounded,
                color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No active plan for today',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color:
                    Theme.of(context).brightness ==
                        Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set one of your saved plans for this weekday to see it here.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness ==
                        Brightness.dark
                        ? Colors.white54
                        : const Color(0xFF888888),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onOpenSchedule,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Schedule',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
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
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border:
        Border.all(color: accentColor.withAlpha(60), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Colored header banner ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No active plan today — try this one',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Plan info ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan.description ??
                      'A recommended pre-built plan for today.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.60),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Tags ──────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((plan.difficulty ?? '').isNotEmpty)
                      _PlanTag(
                          label: plan.difficulty!,
                          color: const Color(0xFF42A5F5)),
                    if ((plan.goalTag ?? '').isNotEmpty)
                      _PlanTag(
                          label: plan.goalTag!,
                          color: const Color(0xFF26A69A)),
                    _PlanTag(
                      label:
                      '${plan.exercises.length} exercises',
                      color: const Color(0xFFAB47BC),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Exercise list ──────────────────────────
                ...plan.exercises.take(3).map(
                      (exercise) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(10),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            exercise.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          '${exercise.sets.length} sets',
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(
                                  alpha: 0.5)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${exercise.sets.fold<int>(0, (sum, set) => sum + set.reps)} reps',
                          style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(
                                  alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Action buttons ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: onFollow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Follow Plan',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onViewPlans,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: accentColor.withAlpha(80),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          'View Plans',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
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
    );
  }
}

class _PlanTag extends StatelessWidget {
  final String label;
  final Color color;

  const _PlanTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
          border: Border.all(
              color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              accentColor.withValues(alpha: 0.16),
              child: const Icon(Icons.auto_awesome_outlined,
                  color: Colors.black),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore pre-built plans',
                      style: TextStyle(
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                      'Browse curated templates and copy one into your own schedule.'),
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
          child: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 10),
        Text(duration, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 10),
        Text(sets, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}