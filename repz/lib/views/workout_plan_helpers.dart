import 'package:flutter/material.dart';
import 'package:repz/model/workout.dart';
import 'package:repz/model/workout_catalog.dart';
import 'package:repz/model/workout_plan.dart';

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

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PoseDetectorView(exercises: exercises),
      ),
    );
    return true;
  }
}
