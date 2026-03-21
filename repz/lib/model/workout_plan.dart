import 'workout.dart';

class WorkoutPlanSet {
  const WorkoutPlanSet({
    this.id,
    required this.sortOrder,
    required this.reps,
    required this.variation,
  });

  final String? id;
  final int sortOrder;
  final int reps;
  final String variation;

  WorkoutPlanSet copyWith({
    String? id,
    int? sortOrder,
    int? reps,
    String? variation,
  }) {
    return WorkoutPlanSet(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      reps: reps ?? this.reps,
      variation: variation ?? this.variation,
    );
  }

  factory WorkoutPlanSet.fromMap(Map<String, dynamic> map) {
    return WorkoutPlanSet(
      id: map['id'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      reps: map['reps'] as int? ?? 0,
      variation: (map['variation'] as String?) ?? 'Standard',
    );
  }

  Map<String, dynamic> toInsertMap({required String workoutPlanExerciseId}) {
    return {
      'workout_plan_exercise_id': workoutPlanExerciseId,
      'sort_order': sortOrder,
      'reps': reps,
      'variation': variation,
    };
  }
}

class WorkoutPlanExercise {
  const WorkoutPlanExercise({
    this.id,
    required this.sortOrder,
    required this.exerciseKey,
    required this.displayName,
    this.workoutType,
    this.assetPath,
    required this.targetJoints,
    required this.sets,
  });

  final String? id;
  final int sortOrder;
  final String exerciseKey;
  final String displayName;
  final WorkoutType? workoutType;
  final String? assetPath;
  final List<String> targetJoints;
  final List<WorkoutPlanSet> sets;

  WorkoutPlanExercise copyWith({
    String? id,
    int? sortOrder,
    String? exerciseKey,
    String? displayName,
    WorkoutType? workoutType,
    String? assetPath,
    List<String>? targetJoints,
    List<WorkoutPlanSet>? sets,
  }) {
    return WorkoutPlanExercise(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      exerciseKey: exerciseKey ?? this.exerciseKey,
      displayName: displayName ?? this.displayName,
      workoutType: workoutType ?? this.workoutType,
      assetPath: assetPath ?? this.assetPath,
      targetJoints: targetJoints ?? this.targetJoints,
      sets: sets ?? this.sets,
    );
  }

  factory WorkoutPlanExercise.fromMap(Map<String, dynamic> map) {
    final rawSets =
        (map['workout_plan_sets'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    rawSets.sort(
      (a, b) => (a['sort_order'] as int? ?? 0).compareTo(
        b['sort_order'] as int? ?? 0,
      ),
    );

    return WorkoutPlanExercise(
      id: map['id'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      exerciseKey: (map['exercise_key'] as String?) ?? '',
      displayName: (map['display_name'] as String?) ?? '',
      workoutType: WorkoutType.fromDbValue(map['workout_type'] as String?),
      assetPath: map['asset_path'] as String?,
      targetJoints:
          (map['target_joints'] as List<dynamic>? ?? const <dynamic>[])
              .map((joint) => joint.toString())
              .toList(),
      sets: rawSets.map(WorkoutPlanSet.fromMap).toList(),
    );
  }

  Map<String, dynamic> toInsertMap({required String workoutPlanId}) {
    return {
      'workout_plan_id': workoutPlanId,
      'sort_order': sortOrder,
      'exercise_key': exerciseKey,
      'display_name': displayName,
      'workout_type': workoutType?.dbValue,
      'asset_path': assetPath,
      'target_joints': targetJoints,
    };
  }
}

class WorkoutPlan {
  const WorkoutPlan({
    this.id,
    required this.userId,
    required this.name,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.exercises,
  });

  final String? id;
  final String userId;
  final String name;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkoutPlanExercise> exercises;

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkoutPlanExercise>? exercises,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    final rawExercises =
        (map['workout_plan_exercises'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    rawExercises.sort(
      (a, b) => (a['sort_order'] as int? ?? 0).compareTo(
        b['sort_order'] as int? ?? 0,
      ),
    );

    return WorkoutPlan(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      name: (map['name'] as String?) ?? 'Workout Plan',
      notes: map['notes'] as String?,
      isActive: map['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      exercises: rawExercises.map(WorkoutPlanExercise.fromMap).toList(),
    );
  }
}
