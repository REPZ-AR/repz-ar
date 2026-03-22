import 'package:flutter/material.dart';
import 'package:repz/model/workout.dart';
import 'package:repz/model/workout_catalog.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pose_detector_view.dart';

class WorkoutPlanHelpers {
  static List<WorkoutCatalogExercise> supportedExercisesForPlan(WorkoutPlan plan) {
    final exercises = <WorkoutCatalogExercise>[];

    for (final planExercise in plan.exercises) {
      final catalogExercise = WorkoutCatalog.byKey(planExercise.exerciseKey);
      if (catalogExercise != null && catalogExercise.isSupportedForWorkoutFlow) {
        exercises.add(catalogExercise);
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
    final supportedCatalogExercises = supportedExercisesForPlan(plan);

    if (supportedCatalogExercises.isEmpty) {
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Plan launch is being migrated to Supabase exercise data. Start workouts from the DB-backed exercise flow for now.',
          ),
        ),
      );

    return false;
  }
}