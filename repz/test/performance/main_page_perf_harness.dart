import 'package:flutter/material.dart';
import 'package:repz/main.dart';
import 'package:repz/views/main_page.dart';

Widget buildMainPageApp({
  required bool isCoach,
  bool isDarkMode = true,
  Future<void> Function()? onOpenWorkoutBuilderOverride,
  Future<void> Function()? onOpenTrainerPlanLibraryOverride,
  Future<void> Function()? onOpenObjectDetectionOverride,
  Future<void> Function()? onStartTodaysPlanOverride,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFFA66CFF),
      scaffoldBackgroundColor: Colors.grey[100],
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFCFF500),
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
    ),
    themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    home: MainPage(
      isDarkMode: isDarkMode,
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
