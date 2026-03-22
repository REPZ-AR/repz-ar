import 'package:flutter/material.dart';
import 'package:repz/model/workout.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/exercise_repository.dart';
import 'package:repz/repositories/workout_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pose_detector_view.dart';

class WorkoutPlanHelpers {
  static Future<List<Exercise>> supportedExercisesForPlan(
      WorkoutPlan plan,
      ) async {
    final exerciseIds =
    plan.exercises
        .map((e) => e.exerciseKey)
        .where((id) => id.isNotEmpty)
        .toList();

    final repo = ExerciseRepository();
    final dbExercises = await repo.fetchExercisesByIds(exerciseIds);

    final byId = <String, Exercise>{
      for (final exercise in dbExercises) exercise.id: exercise,
    };

    final orderedExercises = <Exercise>[];
    for (final planExercise in plan.exercises) {
      final match = byId[planExercise.exerciseKey];
      if (match != null) {
        orderedExercises.add(match);
      }
    }

    return orderedExercises;
  }

  static Future<bool> startPlan(
      BuildContext context,
      WorkoutPlan plan,
      ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final workoutRepository = WorkoutRepository();

    final exercises = await supportedExercisesForPlan(plan);

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
        builder:
            (context) => PoseDetectorView(
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