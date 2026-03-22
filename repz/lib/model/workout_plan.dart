import 'workout.dart';

enum WorkoutPlanScope {
  personal('personal'),
  trainerTemplate('trainer_template'),
  assignedCopy('assigned_copy');

  const WorkoutPlanScope(this.dbValue);

  final String dbValue;

  static WorkoutPlanScope fromDbValue(String? value) {
    for (final scope in WorkoutPlanScope.values) {
      if (scope.dbValue == value) return scope;
    }
    return WorkoutPlanScope.personal;
  }
}

enum ScheduleProfileSourceType {
  self('self'),
  trainerProposed('trainer_proposed');

  const ScheduleProfileSourceType(this.dbValue);

  final String dbValue;

  static ScheduleProfileSourceType fromDbValue(String? value) {
    for (final type in ScheduleProfileSourceType.values) {
      if (type.dbValue == value) return type;
    }
    return ScheduleProfileSourceType.self;
  }
}

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
    this.planScope = WorkoutPlanScope.personal,
    this.trainerId,
    this.assignedClientId,
    this.sourceWorkoutPlanId,
    this.isReadOnly = false,
    required this.exercises,
  });

  final String? id;
  final String userId;
  final String name;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorkoutPlanScope planScope;
  final String? trainerId;
  final String? assignedClientId;
  final String? sourceWorkoutPlanId;
  final bool isReadOnly;
  final List<WorkoutPlanExercise> exercises;

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    WorkoutPlanScope? planScope,
    String? trainerId,
    String? assignedClientId,
    String? sourceWorkoutPlanId,
    bool? isReadOnly,
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
      planScope: planScope ?? this.planScope,
      trainerId: trainerId ?? this.trainerId,
      assignedClientId: assignedClientId ?? this.assignedClientId,
      sourceWorkoutPlanId: sourceWorkoutPlanId ?? this.sourceWorkoutPlanId,
      isReadOnly: isReadOnly ?? this.isReadOnly,
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
      planScope: WorkoutPlanScope.fromDbValue(map['plan_scope'] as String?),
      trainerId: map['trainer_id'] as String?,
      assignedClientId: map['assigned_client_id'] as String?,
      sourceWorkoutPlanId: map['source_workout_plan_id'] as String?,
      isReadOnly: map['is_read_only'] as bool? ?? false,
      exercises: rawExercises.map(WorkoutPlanExercise.fromMap).toList(),
    );
  }
}

class WorkoutScheduleProfile {
  const WorkoutScheduleProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.sourceType,
    this.trainerId,
    this.assignmentId,
    required this.isActive,
    required this.isReadOnly,
    required this.createdAt,
    required this.updatedAt,
    required this.days,
  });

  final String id;
  final String userId;
  final String name;
  final ScheduleProfileSourceType sourceType;
  final String? trainerId;
  final String? assignmentId;
  final bool isActive;
  final bool isReadOnly;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkoutScheduleProfileDay> days;

  factory WorkoutScheduleProfile.fromMap(Map<String, dynamic> map) {
    final rawDays =
        (map['workout_schedule_profile_days'] as List<dynamic>? ??
                const <dynamic>[])
            .cast<Map<String, dynamic>>();

    rawDays.sort(
      (a, b) => (a['day_of_week'] as int? ?? 0).compareTo(
        b['day_of_week'] as int? ?? 0,
      ),
    );

    return WorkoutScheduleProfile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: (map['name'] as String?) ?? 'Schedule',
      sourceType: ScheduleProfileSourceType.fromDbValue(
        map['source_type'] as String?,
      ),
      trainerId: map['trainer_id'] as String?,
      assignmentId: map['assignment_id'] as String?,
      isActive: map['is_active'] as bool? ?? false,
      isReadOnly: map['is_read_only'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      days: rawDays.map(WorkoutScheduleProfileDay.fromMap).toList(),
    );
  }
}

class WorkoutScheduleProfileDay {
  const WorkoutScheduleProfileDay({
    required this.id,
    required this.scheduleProfileId,
    required this.dayOfWeek,
    required this.workoutPlanId,
    this.plan,
  });

  final String id;
  final String scheduleProfileId;
  final int dayOfWeek;
  final String workoutPlanId;
  final WorkoutPlan? plan;

  factory WorkoutScheduleProfileDay.fromMap(Map<String, dynamic> map) {
    final nestedPlan = map['workout_plans'] as Map<String, dynamic>?;

    return WorkoutScheduleProfileDay(
      id: map['id'] as String,
      scheduleProfileId: map['schedule_profile_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      workoutPlanId: map['workout_plan_id'] as String,
      plan: nestedPlan == null ? null : WorkoutPlan.fromMap(nestedPlan),
    );
  }
}

class WorkoutPlanAssignment {
  const WorkoutPlanAssignment({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.trainerWorkoutPlanId,
    required this.clientWorkoutPlanId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.trainerPlan,
    this.clientPlan,
  });

  final String id;
  final String trainerId;
  final String clientId;
  final String trainerWorkoutPlanId;
  final String clientWorkoutPlanId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorkoutPlan? trainerPlan;
  final WorkoutPlan? clientPlan;

  factory WorkoutPlanAssignment.fromMap(Map<String, dynamic> map) {
    final trainerPlanMap =
        map['trainer_workout_plan'] as Map<String, dynamic>?;
    final clientPlanMap = map['client_workout_plan'] as Map<String, dynamic>?;

    return WorkoutPlanAssignment(
      id: map['id'] as String,
      trainerId: map['trainer_id'] as String,
      clientId: map['client_id'] as String,
      trainerWorkoutPlanId: map['trainer_workout_plan_id'] as String,
      clientWorkoutPlanId: map['client_workout_plan_id'] as String,
      status: (map['status'] as String?) ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      trainerPlan:
          trainerPlanMap == null ? null : WorkoutPlan.fromMap(trainerPlanMap),
      clientPlan:
          clientPlanMap == null ? null : WorkoutPlan.fromMap(clientPlanMap),
    );
  }
}

class ClientActivePlanStatus {
  const ClientActivePlanStatus({
    required this.clientId,
    this.activeScheduleProfile,
    this.todaysPlan,
    this.currentWorkoutIndex = 0,
    this.activeSourceLabel,
  });

  final String clientId;
  final WorkoutScheduleProfile? activeScheduleProfile;
  final WorkoutPlan? todaysPlan;
  final int currentWorkoutIndex;
  final String? activeSourceLabel;
}

class WorkoutPlanScheduleEntry {
  const WorkoutPlanScheduleEntry({
    this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.workoutPlanId,
    this.plan,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final String userId;
  final int dayOfWeek;
  final String workoutPlanId;
  final WorkoutPlan? plan;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WorkoutPlanScheduleEntry.fromMap(Map<String, dynamic> map) {
    final nestedPlan = map['workout_plans'] as Map<String, dynamic>?;

    return WorkoutPlanScheduleEntry(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      workoutPlanId: map['workout_plan_id'] as String,
      plan: nestedPlan == null ? null : WorkoutPlan.fromMap(nestedPlan),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class PrebuiltWorkoutPlan {
  const PrebuiltWorkoutPlan({
    required this.id,
    required this.name,
    this.description,
    this.difficulty,
    this.goalTag,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    required this.exercises,
  });

  final String id;
  final String name;
  final String? description;
  final String? difficulty;
  final String? goalTag;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkoutPlanExercise> exercises;

  factory PrebuiltWorkoutPlan.fromMap(Map<String, dynamic> map) {
    final rawExercises =
        (map['prebuilt_workout_plan_exercises'] as List<dynamic>? ??
                const <dynamic>[])
            .cast<Map<String, dynamic>>();

    rawExercises.sort(
      (a, b) => (a['sort_order'] as int? ?? 0).compareTo(
        b['sort_order'] as int? ?? 0,
      ),
    );

    return PrebuiltWorkoutPlan(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? 'Pre-built Plan',
      description: map['description'] as String?,
      difficulty: map['difficulty'] as String?,
      goalTag: map['goal_tag'] as String?,
      isFeatured: map['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      exercises: rawExercises.map(_prebuiltExerciseFromMap).toList(),
    );
  }
}

WorkoutPlanExercise _prebuiltExerciseFromMap(Map<String, dynamic> map) {
  final rawSets =
      (map['prebuilt_workout_plan_sets'] as List<dynamic>? ?? const <dynamic>[])
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
