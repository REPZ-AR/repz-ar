import 'package:flutter/material.dart';
import 'package:repz/views/pose_detector_view.dart';

import '../model/workout.dart';

class HomePage extends StatelessWidget {
  final bool isDarkMode;
  final List<Exercise> todaysPlan = [
    Exercise(
      name: 'Bicep Curls',
      duration: '10 min',
      sets: '5 sets',
      type: WorkoutType.curls,
      assetPath: 'assets/data/baseline_curls.json',
      targetJoints: ['leftShoulder', 'leftElbow', 'leftWrist'],
    ),
    Exercise(
      name: 'Lateral Raises',
      duration: '5 min',
      sets: '3 sets',
      type: WorkoutType.curls,
      assetPath: 'assets/data/baseline_curls.json',
      targetJoints: ['leftShoulder', 'leftElbow'],
    ),
  ];

  HomePage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final featuredExercise = todaysPlan.first;
    final accentColor = isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile icon
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
                  child: Icon(
                    Icons.person,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's workout card
        Container(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        featuredExercise.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Intensity: High\n• Duration: ${featuredExercise.duration}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PoseDetectorView(
                            exercises: todaysPlan,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // workout list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: todaysPlan.length,
                  itemBuilder: (context, index) {
                    final ex = todaysPlan[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: _ExerciseItem(ex.name, ex.duration, ex.sets),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Workouts\nCompleted',
                    value: '4/6',
                    accentColor: accentColor,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Streak\nScore',
                    value: '75',
                    accentColor: accentColor,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rest and Calory cards
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Next Rest in',
                    value: '2',
                    subtitle: 'Days',
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    title: 'Calory\nGoal',
                    value: '350',
                    subtitle: '',
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
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
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(duration, style: const TextStyle(fontSize: 12)),
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

