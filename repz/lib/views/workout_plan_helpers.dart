import 'package:flutter/material.dart';
import 'package:repz/model/workout.dart';
import 'package:repz/model/workout_catalog.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pose_detector_view.dart';

class WorkoutPlanHelpers {
  static List<Exercise> supportedExercisesForPlan(WorkoutPlan plan) {
    final exercises = <Exercise>[];

    for (final planExercise in plan.exercises) {
      final catalogExercise = WorkoutCatalog.byKey(planExercise.exerciseKey);
      final runtimeExercise = catalogExercise?.toRuntimeExercise(planExercise);
      if (runtimeExercise != null) {
        exercises.add(runtimeExercise);
      }
    }

    return exercises;
  }

  static Future<bool> startPlan(
    BuildContext context,
    WorkoutPlan plan,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final workoutRepository = WorkoutRepository();
    final exercises = supportedExercisesForPlan(plan);
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'This plan has no exercises supported by the live workout flow yet.',
            ),
          ),
        );
      return false;
    }

    final initialIndex =
        userId == null || plan.id == null
            ? 0
            : await workoutRepository.fetchWorkoutProgress(
                userId,
                workoutPlanId: plan.id,
              );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PoseDetectorView(
          exercises: exercises,
          initialIndex: initialIndex,
          onProgressSaved:
              userId == null || plan.id == null
                  ? null
                  : (savedIndex) async {
                      await workoutRepository.syncWorkoutProgress(
                        userId,
                        savedIndex,
                        workoutPlanId: plan.id,
                      );
                    },
          isDarkMode: isDarkMode,
        ),
      ),
    );
    return true;
  }
}
