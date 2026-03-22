import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get _currentUser => _client.auth.currentUser;

  Future<List<WorkoutPlan>> fetchPlans({
    WorkoutPlanScope scope = WorkoutPlanScope.personal,
    String? forUserId,
  }) async {
    final userId = forUserId ?? _currentUser?.id;
    if (userId == null) return const <WorkoutPlan>[];

    final rows = await _client
        .from('workout_plans')
        .select(_planSelectQuery)
        .eq('user_id', userId)
        .eq('plan_scope', scope.dbValue)
        .order('is_active', ascending: false)
        .order('updated_at', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(WorkoutPlan.fromMap)
        .toList();
  }

  Future<List<WorkoutPlan>> fetchTrainerTemplates() {
    return fetchPlans(scope: WorkoutPlanScope.trainerTemplate);
  }

  Future<void> setScheduleForDay(int dayOfWeek, String? workoutPlanId) async {
    final selfProfile = await ensureSelfScheduleProfile();
    final Map<int, String?> currentDays = {
      for (final day in selfProfile.days) day.dayOfWeek: day.workoutPlanId,
    };
    currentDays[dayOfWeek] = workoutPlanId;
    await saveScheduleProfileDays(
      profileId: selfProfile.id,
      dayToPlanId: currentDays,
    );
  }

  Future<WorkoutPlan?> fetchPlanById(String planId) async {
    final row = await _client
        .from('workout_plans')
        .select(_planSelectQuery)
        .eq('id', planId)
        .maybeSingle();

    if (row == null) return null;
    return WorkoutPlan.fromMap(row);
  }

  Future<WorkoutPlan?> fetchActivePlan() async {
    final userId = _currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('workout_plans')
        .select(_planSelectQuery)
        .eq('user_id', userId)
        .eq('plan_scope', WorkoutPlanScope.personal.dbValue)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) return null;
    return WorkoutPlan.fromMap(row);
  }

  Future<List<PrebuiltWorkoutPlan>> fetchPrebuiltPlans() async {
    final rows = await _client
        .from('prebuilt_workout_plans')
        .select(_prebuiltSelectQuery)
        .order('is_featured', ascending: false)
        .order('created_at');

    return rows
        .cast<Map<String, dynamic>>()
        .map(PrebuiltWorkoutPlan.fromMap)
        .toList();
  }

  Future<PrebuiltWorkoutPlan?> fetchRecommendedPrebuiltPlan() async {
    final rows = await _client
        .from('prebuilt_workout_plans')
        .select(_prebuiltSelectQuery)
        .eq('is_featured', true)
        .limit(1);

    if (rows.isEmpty) {
      final fallback = await _client
          .from('prebuilt_workout_plans')
          .select(_prebuiltSelectQuery)
          .limit(1);
      if (fallback.isEmpty) return null;
      return PrebuiltWorkoutPlan.fromMap(
        fallback.first,
      );
    }

    return PrebuiltWorkoutPlan.fromMap(rows.first);
  }

  Future<List<WorkoutPlanAssignment>> fetchAssignmentsForClient(
    String clientId,
  ) async {
    final trainerId = _currentUser?.id;
    if (trainerId == null) return const <WorkoutPlanAssignment>[];

    final rows = await _client
        .from('workout_plan_assignments')
        .select(_assignmentBaseSelectQuery)
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId)
        .eq('status', 'active')
        .order('updated_at', ascending: false);

    return _hydrateAssignments(rows.cast<Map<String, dynamic>>());
  }

  Future<List<WorkoutPlanAssignment>> fetchAssignmentsCreatedByTrainer() async {
    final trainerId = _currentUser?.id;
    if (trainerId == null) return const <WorkoutPlanAssignment>[];

    final rows = await _client
        .from('workout_plan_assignments')
        .select(_assignmentBaseSelectQuery)
        .eq('trainer_id', trainerId)
        .eq('status', 'active')
        .order('updated_at', ascending: false);

    return _hydrateAssignments(rows.cast<Map<String, dynamic>>());
  }

  Future<WorkoutPlanAssignment> assignTrainerPlanToClient({
    required String clientId,
    required WorkoutPlan trainerPlan,
  }) async {
    final trainerId = _currentUser?.id;
    if (trainerId == null) {
      throw const AuthException('You need to be signed in to assign plans.');
    }

    final now = DateTime.now();
    final existing = await _client
        .from('workout_plan_assignments')
        .select('id, client_workout_plan_id')
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId)
        .eq('trainer_workout_plan_id', trainerPlan.id as Object)
        .eq('status', 'active')
        .maybeSingle();

    final existingClientPlanId =
        existing == null ? null : existing['client_workout_plan_id'] as String?;
    final existingClientPlan =
        existingClientPlanId == null
            ? null
            : await fetchPlanById(existingClientPlanId);

    final clientCopy = WorkoutPlan(
      id: existingClientPlan?.id,
      userId: clientId,
      name: trainerPlan.name,
      notes: trainerPlan.notes,
      isActive: false,
      createdAt: existingClientPlan?.createdAt ?? now,
      updatedAt: now,
      planScope: WorkoutPlanScope.assignedCopy,
      trainerId: trainerId,
      assignedClientId: clientId,
      sourceWorkoutPlanId: trainerPlan.id,
      isReadOnly: true,
      exercises: List<WorkoutPlanExercise>.generate(
        trainerPlan.exercises.length,
        (index) => trainerPlan.exercises[index].copyWith(
          id: null,
          sortOrder: index,
          sets: List<WorkoutPlanSet>.generate(
            trainerPlan.exercises[index].sets.length,
            (setIndex) => trainerPlan.exercises[index].sets[setIndex].copyWith(
              id: null,
              sortOrder: setIndex,
            ),
          ),
        ),
      ),
    );

    final savedClientCopy = await savePlan(clientCopy);

    final row =
        existing == null
            ? await _client
                .from('workout_plan_assignments')
                .insert({
                  'trainer_id': trainerId,
                  'client_id': clientId,
                  'trainer_workout_plan_id': trainerPlan.id,
                  'client_workout_plan_id': savedClientCopy.id,
                  'status': 'active',
                })
                .select(_assignmentBaseSelectQuery)
                .single()
            : await _client
                .from('workout_plan_assignments')
                .update({
                  'client_workout_plan_id': savedClientCopy.id,
                  'status': 'active',
                  'updated_at': now.toUtc().toIso8601String(),
                })
                .eq('id', existing['id'] as Object)
                .select(_assignmentBaseSelectQuery)
                .single();

    return (await _hydrateAssignments([row])).single;
  }

  Future<List<WorkoutPlanAssignment>> _hydrateAssignments(
    List<Map<String, dynamic>> rows,
  ) async {
    final assignments = <WorkoutPlanAssignment>[];
    for (final row in rows) {
      final trainerPlan = await fetchPlanById(
        row['trainer_workout_plan_id'] as String,
      );
      final clientPlan = await fetchPlanById(
        row['client_workout_plan_id'] as String,
      );

      assignments.add(
        WorkoutPlanAssignment.fromMap({
          ...row,
          'trainer_workout_plan': trainerPlan == null ? null : _planToMap(trainerPlan),
          'client_workout_plan': clientPlan == null ? null : _planToMap(clientPlan),
        }),
      );
    }
    return assignments;
  }

  Map<String, dynamic> _planToMap(WorkoutPlan plan) {
    return {
      'id': plan.id,
      'user_id': plan.userId,
      'name': plan.name,
      'notes': plan.notes,
      'is_active': plan.isActive,
      'created_at': plan.createdAt.toIso8601String(),
      'updated_at': plan.updatedAt.toIso8601String(),
      'plan_scope': plan.planScope.dbValue,
      'trainer_id': plan.trainerId,
      'assigned_client_id': plan.assignedClientId,
      'source_workout_plan_id': plan.sourceWorkoutPlanId,
      'is_read_only': plan.isReadOnly,
      'workout_plan_exercises': plan.exercises.map((exercise) {
        return {
          'id': exercise.id,
          'workout_plan_id': plan.id,
          'sort_order': exercise.sortOrder,
          'exercise_key': exercise.exerciseKey,
          'display_name': exercise.displayName,
          'workout_type': exercise.workoutType?.dbValue,
          'asset_path': exercise.assetPath,
          'target_joints': exercise.targetJoints,
          'workout_plan_sets': exercise.sets.map((set) {
            return {
              'id': set.id,
              'sort_order': set.sortOrder,
              'reps': set.reps,
              'variation': set.variation,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  Future<List<WorkoutScheduleProfile>> fetchScheduleProfiles({
    String? forUserId,
  }) async {
    final userId = forUserId ?? _currentUser?.id;
    if (userId == null) return const <WorkoutScheduleProfile>[];

    final rows = await _client
        .from('workout_schedule_profiles')
        .select(_scheduleProfileSelectQuery)
        .eq('user_id', userId)
        .order('is_active', ascending: false)
        .order('created_at');

    return rows
        .cast<Map<String, dynamic>>()
        .map(WorkoutScheduleProfile.fromMap)
        .toList();
  }

  Future<WorkoutScheduleProfile> ensureSelfScheduleProfile({
    String? forUserId,
  }) async {
    final userId = forUserId ?? _currentUser?.id;
    if (userId == null) {
      throw const AuthException('You need to be signed in to manage schedules.');
    }

    final existing = await _client
        .from('workout_schedule_profiles')
        .select(_scheduleProfileSelectQuery)
        .eq('user_id', userId)
        .eq('source_type', ScheduleProfileSourceType.self.dbValue)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return WorkoutScheduleProfile.fromMap(existing);
    }

    final row =
        await _client
            .from('workout_schedule_profiles')
            .insert({
              'user_id': userId,
              'name': 'My Schedule',
              'source_type': ScheduleProfileSourceType.self.dbValue,
              'is_active': true,
              'is_read_only': false,
            })
            .select(_scheduleProfileSelectQuery)
            .single();

    return WorkoutScheduleProfile.fromMap(row);
  }

  Future<WorkoutScheduleProfile> createOrUpdateTrainerScheduleProfile({
    required String clientId,
    required String name,
    String? assignmentId,
    String? profileId,
  }) async {
    final trainerId = _currentUser?.id;
    if (trainerId == null) {
      throw const AuthException('You need to be signed in to propose schedules.');
    }

    final payload = <String, dynamic>{
      'user_id': clientId,
      'trainer_id': trainerId,
      'assignment_id': assignmentId,
      'name': name.trim().isEmpty ? 'Trainer Schedule' : name.trim(),
      'source_type': ScheduleProfileSourceType.trainerProposed.dbValue,
      'is_read_only': true,
    };

    final row =
        profileId == null
            ? await _client
                .from('workout_schedule_profiles')
                .insert(payload)
                .select(_scheduleProfileSelectQuery)
                .single()
            : await _client
                .from('workout_schedule_profiles')
                .update(payload)
                .eq('id', profileId)
                .select(_scheduleProfileSelectQuery)
                .single();

    return WorkoutScheduleProfile.fromMap(row);
  }

  Future<void> saveScheduleProfileDays({
    required String profileId,
    required Map<int, String?> dayToPlanId,
  }) async {
    final existingRows = await _client
        .from('workout_schedule_profile_days')
        .select('id, day_of_week')
        .eq('schedule_profile_id', profileId);

    final existingByDay = <int, String>{
      for (final row in existingRows.cast<Map<String, dynamic>>())
        row['day_of_week'] as int: row['id'] as String,
    };

    for (final entry in dayToPlanId.entries) {
      final existingId = existingByDay[entry.key];
      final workoutPlanId = entry.value;

      if (workoutPlanId == null || workoutPlanId.isEmpty) {
        if (existingId != null) {
          await _client
              .from('workout_schedule_profile_days')
              .delete()
              .eq('id', existingId);
        }
        continue;
      }

      final payload = <String, dynamic>{
        'schedule_profile_id': profileId,
        'day_of_week': entry.key,
        'workout_plan_id': workoutPlanId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (existingId == null) {
        await _client.from('workout_schedule_profile_days').insert(payload);
      } else {
        await _client
            .from('workout_schedule_profile_days')
            .update(payload)
            .eq('id', existingId);
      }
    }
  }

  Future<void> activateScheduleProfile(String profileId) async {
    final row = await _client
        .from('workout_schedule_profiles')
        .select('id, user_id')
        .eq('id', profileId)
        .single();

    final userId = row['user_id'] as String;
    await _client
        .from('workout_schedule_profiles')
        .update({'is_active': false})
        .eq('user_id', userId);
    await _client
        .from('workout_schedule_profiles')
        .update({'is_active': true})
        .eq('id', profileId);
  }

  Future<WorkoutScheduleProfile?> fetchActiveScheduleProfile({
    String? forUserId,
  }) async {
    final userId = forUserId ?? _currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('workout_schedule_profiles')
        .select(_scheduleProfileSelectQuery)
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return WorkoutScheduleProfile.fromMap(row);
  }

  Future<WorkoutPlan?> fetchScheduledPlanForDay(
    int dayOfWeek, {
    String? forUserId,
  }) async {
    final activeProfile = await fetchActiveScheduleProfile(forUserId: forUserId);
    if (activeProfile == null) return null;

    for (final day in activeProfile.days) {
      if (day.dayOfWeek == dayOfWeek) {
        return day.plan;
      }
    }
    return null;
  }

  Future<ClientActivePlanStatus> fetchClientActivePlanStatus(
    String clientId,
  ) async {
    final activeProfile = await fetchActiveScheduleProfile(forUserId: clientId);
    final todaysPlan = await fetchScheduledPlanForDay(
      DateTime.now().weekday,
      forUserId: clientId,
    );
    final progressRepository = WorkoutRepository(client: _client);
    final savedIndex =
        todaysPlan?.id == null
            ? 0
            : await progressRepository.fetchWorkoutProgress(
                clientId,
                workoutPlanId: todaysPlan!.id,
              );

    final activeSourceLabel =
        activeProfile == null
            ? 'No active schedule'
            : activeProfile.sourceType == ScheduleProfileSourceType.self
            ? activeProfile.name
            : '${activeProfile.name} (Trainer Proposed)';

    return ClientActivePlanStatus(
      clientId: clientId,
      activeScheduleProfile: activeProfile,
      todaysPlan: todaysPlan,
      currentWorkoutIndex: savedIndex,
      activeSourceLabel: activeSourceLabel,
    );
  }

  Future<WorkoutPlan> copyPrebuiltPlanToUser(
    String prebuiltPlanId, {
    bool setActive = false,
  }) async {
    final prebuilt = await _client
        .from('prebuilt_workout_plans')
        .select(_prebuiltSelectQuery)
        .eq('id', prebuiltPlanId)
        .single();

    final template = PrebuiltWorkoutPlan.fromMap(prebuilt);
    final userId = _currentUser?.id;
    if (userId == null) {
      throw const AuthException('You need to be signed in to copy plans.');
    }

    final copiedPlan = WorkoutPlan(
      userId: userId,
      name: template.name,
      notes: template.description,
      isActive: setActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      planScope: WorkoutPlanScope.personal,
      exercises: List<WorkoutPlanExercise>.generate(
        template.exercises.length,
        (index) => template.exercises[index].copyWith(sortOrder: index),
      ),
    );

    return savePlan(copiedPlan, setActive: setActive);
  }

  Future<WorkoutPlan> savePlan(
    WorkoutPlan plan, {
    bool setActive = false,
  }) async {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) {
      throw const AuthException('You need to be signed in to save plans.');
    }

    final effectiveUserId = plan.userId;
    if (setActive) {
      await _client
          .from('workout_plans')
          .update({'is_active': false})
          .eq('user_id', effectiveUserId)
          .eq('plan_scope', plan.planScope.dbValue);
    }

    final trimmedName =
        plan.name.trim().isEmpty ? 'Workout Plan' : plan.name.trim();
    final planPayload = <String, dynamic>{
      'user_id': effectiveUserId,
      'name': trimmedName,
      'notes': plan.notes?.trim().isEmpty == true ? null : plan.notes?.trim(),
      'is_active': setActive,
      'plan_scope': plan.planScope.dbValue,
      'trainer_id': plan.trainerId,
      'assigned_client_id': plan.assignedClientId,
      'source_workout_plan_id': plan.sourceWorkoutPlanId,
      'is_read_only': plan.isReadOnly,
    };

    late final Map<String, dynamic> savedPlanRow;

    if (plan.id == null) {
      savedPlanRow =
          await _client
              .from('workout_plans')
              .insert(planPayload)
              .select()
              .single();
    } else {
      savedPlanRow =
          await _client
              .from('workout_plans')
              .update(planPayload)
              .eq('id', plan.id as Object)
              .select()
              .single();

      final existingExercises = await _client
          .from('workout_plan_exercises')
          .select('id')
          .eq('workout_plan_id', plan.id as Object);

      final existingExerciseIds =
          existingExercises
              .cast<Map<String, dynamic>>()
              .map((row) => row['id'] as String)
              .toList();

      if (existingExerciseIds.isNotEmpty) {
        await _client
            .from('workout_plan_sets')
            .delete()
            .inFilter('workout_plan_exercise_id', existingExerciseIds);
      }

      await _client
          .from('workout_plan_exercises')
          .delete()
          .eq('workout_plan_id', plan.id as Object);
    }

    final savedPlanId = savedPlanRow['id'] as String;

    for (
      var exerciseIndex = 0;
      exerciseIndex < plan.exercises.length;
      exerciseIndex++
    ) {
      final exercise = plan.exercises[exerciseIndex];
      final savedExerciseRow =
          await _client
              .from('workout_plan_exercises')
              .insert(
                exercise.copyWith(sortOrder: exerciseIndex).toInsertMap(
                  workoutPlanId: savedPlanId,
                ),
              )
              .select()
              .single();

      final savedExerciseId = savedExerciseRow['id'] as String;

      if (exercise.sets.isNotEmpty) {
        await _client.from('workout_plan_sets').insert(
          List<Map<String, dynamic>>.generate(exercise.sets.length, (setIndex) {
            final set = exercise.sets[setIndex];
            return set.copyWith(sortOrder: setIndex).toInsertMap(
              workoutPlanExerciseId: savedExerciseId,
            );
          }),
        );
      }
    }

    final savedPlan = await fetchPlanById(savedPlanId);
    if (savedPlan == null) {
      throw StateError('Saved plan could not be reloaded.');
    }

    return savedPlan;
  }

  Future<void> deletePlan(String planId) async {
    final exerciseRows = await _client
        .from('workout_plan_exercises')
        .select('id')
        .eq('workout_plan_id', planId);

    final exerciseIds =
        exerciseRows
            .cast<Map<String, dynamic>>()
            .map((row) => row['id'] as String)
            .toList();

    if (exerciseIds.isNotEmpty) {
      await _client
          .from('workout_plan_sets')
          .delete()
          .inFilter('workout_plan_exercise_id', exerciseIds);
    }

    await _client
        .from('workout_plan_exercises')
        .delete()
        .eq('workout_plan_id', planId);
    await _client.from('workout_plans').delete().eq('id', planId);
  }

  static const String _planSelectQuery =
      'id, user_id, name, notes, is_active, created_at, updated_at, '
      'plan_scope, trainer_id, assigned_client_id, source_workout_plan_id, is_read_only, '
      'workout_plan_exercises('
      'id, workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints, '
      'workout_plan_sets(id, workout_plan_exercise_id, sort_order, reps, variation)'
      ')';

  static const String _scheduleProfileSelectQuery =
      'id, user_id, trainer_id, assignment_id, name, source_type, is_active, is_read_only, created_at, updated_at, '
      'workout_schedule_profile_days('
      'id, schedule_profile_id, day_of_week, workout_plan_id, '
      'workout_plans('
      'id, user_id, name, notes, is_active, created_at, updated_at, '
      'plan_scope, trainer_id, assigned_client_id, source_workout_plan_id, is_read_only, '
      'workout_plan_exercises('
      'id, workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints, '
      'workout_plan_sets(id, workout_plan_exercise_id, sort_order, reps, variation)'
      ')'
      ')'
      ')';

  static const String _assignmentBaseSelectQuery =
      'id, trainer_id, client_id, trainer_workout_plan_id, client_workout_plan_id, status, created_at, updated_at';

  static const String _prebuiltSelectQuery =
      'id, name, description, difficulty, goal_tag, is_featured, created_at, updated_at, '
      'prebuilt_workout_plan_exercises('
      'id, prebuilt_workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints, '
      'prebuilt_workout_plan_sets(id, prebuilt_workout_plan_exercise_id, sort_order, reps, variation)'
      ')';
}
