import 'package:flutter/material.dart';
import 'package:repz/main.dart';
import 'package:repz/views/main_page.dart';

Widget buildMainPageApp({
  required bool isCoach,
  Future<void> Function()? onOpenWorkoutBuilderOverride,
  Future<void> Function()? onOpenTrainerPlanLibraryOverride,
  Future<void> Function()? onOpenObjectDetectionOverride,
  Future<void> Function()? onStartTodaysPlanOverride,
}) {
  return MaterialApp(
    home: MainPage(
      isDarkMode: true,
      isCoach: isCoach,
      onThemeChanged: (_) {},
      userId: 'perf-user',
      workoutGateway: FakeWorkoutGateway(),
      userName: isCoach ? 'Coach Perf' : 'Trainee Perf',
      pageOverrides: <int, Widget>{
        0: PerfShellPage(label: isCoach ? 'Trainer Home' : 'Trainee Home'),
        1: PerfShellPage(
          label: isCoach ? 'Client Management' : 'Trainer Management',
        ),
        3: const PerfShellPage(label: 'Feed Page'),
        4: const PerfShellPage(label: 'Profile Page'),
      },
      onOpenWorkoutBuilderOverride: onOpenWorkoutBuilderOverride,
      onOpenObjectDetectionOverride: onOpenObjectDetectionOverride ?? () async {},
      onOpenTrainerPlanLibraryOverride: onOpenTrainerPlanLibraryOverride,
      onStartTodaysPlanOverride: onStartTodaysPlanOverride ?? () async {},
    ),
  );
}

class PerfShellPage extends StatelessWidget {
  const PerfShellPage({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class FakeWorkoutGateway implements WorkoutGateway {
  @override
  Future<int> fetchWorkoutProgress(
    String userId, {
    String? workoutPlanId,
  }) async => 0;

  @override
  Future<void> syncWorkoutProgress(
    String userId,
    int index, {
    String? workoutPlanId,
  }) async {}
}
