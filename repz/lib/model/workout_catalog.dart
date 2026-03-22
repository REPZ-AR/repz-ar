import 'package:flutter/material.dart';

import 'workout.dart';
import 'workout_plan.dart';

class WorkoutCatalogExercise {
  const WorkoutCatalogExercise({
    required this.key,
    required this.name,
    required this.icon,
    required this.variations,
    this.workoutType,
    // this.assetPath,
    this.targetJoints = const <String>[],
    this.defaultReps = 12,
    this.defaultSetCount = 3,
  });

  final String key;
  final String name;
  final IconData icon;
  final List<String> variations;
  final WorkoutType? workoutType;
  // final String? assetPath;
  final List<String> targetJoints;
  final int defaultReps;
  final int defaultSetCount;

  bool get isSupportedForWorkoutFlow =>
      workoutType != null && targetJoints.isNotEmpty;

  WorkoutPlanExercise createPlanExercise({required int sortOrder}) {
    return WorkoutPlanExercise(
      sortOrder: sortOrder,
      exerciseKey: key,
      displayName: name,
      workoutType: workoutType,
      targetJoints: targetJoints,
      sets: List<WorkoutPlanSet>.generate(
        defaultSetCount,
        (index) => WorkoutPlanSet(
          sortOrder: index,
          reps: defaultReps,
          variation: variations.first,
        ),
      ),
    );
  }
}

class WorkoutCatalog {
  static const List<String> commonVariations = <String>[
    'Standard',
    'Slow Eccentric',
    'Pause Reps',
    'Tempo',
    'Drop Set',
    'Single Arm',
    'Single Leg',
    'Incline',
    'Decline',
  ];

  static const List<WorkoutCatalogExercise> exercises =
      <WorkoutCatalogExercise>[
        WorkoutCatalogExercise(
          key: 'hammer_curl',
          name: 'Hammer Curl',
          icon: Icons.fitness_center,
          workoutType: WorkoutType.curls,
          targetJoints: <String>['leftShoulder', 'leftElbow', 'leftWrist'],
          variations: <String>[
            'Standard',
            'Slow Eccentric',
            'Tempo',
            'Single Arm',
          ],
        ),
        WorkoutCatalogExercise(
          key: 'lateral_raise',
          name: 'Lateral Raise',
          icon: Icons.accessibility_new,
          workoutType: WorkoutType.curls,
          targetJoints: <String>['leftShoulder', 'leftElbow'],
          variations: commonVariations,
        ),
        WorkoutCatalogExercise(
          key: 'bodyweight_squat',
          name: 'Bodyweight Squat',
          icon: Icons.airline_seat_recline_normal,
          workoutType: WorkoutType.squats,
          targetJoints: <String>['leftHip', 'leftKnee', 'leftAnkle'],
          variations: <String>[
            'Standard',
            'Pause Reps',
            'Tempo',
            'Single Leg',
          ],
        ),
        WorkoutCatalogExercise(
          key: 'plank_hold',
          name: 'Plank Hold',
          icon: Icons.horizontal_rule,
          workoutType: WorkoutType.planks,
          targetJoints: <String>['leftShoulder', 'leftHip', 'leftAnkle'],
          variations: <String>['Standard', 'Tempo', 'Single Arm', 'Single Leg'],
          defaultReps: 30,
        ),
        WorkoutCatalogExercise(
          key: 'dumbbell_rows',
          name: 'Dumbbell Rows',
          icon: Icons.rowing,
          variations: commonVariations,
        ),
        WorkoutCatalogExercise(
          key: 'treadmill',
          name: 'Treadmill',
          icon: Icons.directions_run,
          variations: <String>['Standard', 'Incline', 'Tempo'],
          defaultReps: 10,
        ),
        WorkoutCatalogExercise(
          key: 'cable_pulldown',
          name: 'Cable Pulldown',
          icon: Icons.sports_gymnastics,
          variations: commonVariations,
        ),
        WorkoutCatalogExercise(
          key: 'wrist_curl',
          name: 'Wrist Curl',
          icon: Icons.front_hand,
          variations: commonVariations,
        ),
      ];

  static WorkoutCatalogExercise? byKey(String key) {
    for (final exercise in exercises) {
      if (exercise.key == key) return exercise;
    }
    return null;
  }
}
