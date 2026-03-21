import 'package:repz/model/workout_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get _currentUser => _client.auth.currentUser;

  Future<List<WorkoutPlan>> fetchPlans() async {
    final userId = _currentUser?.id;
    if (userId == null) return const <WorkoutPlan>[];

    final rows = await _client
        .from('workout_plans')
        .select(_selectQuery)
        .eq('user_id', userId)
        .order('is_active', ascending: false)
        .order('updated_at', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(WorkoutPlan.fromMap)
        .toList();
  }

  Future<WorkoutPlan?> fetchPlanById(String planId) async {
    final row = await _client
        .from('workout_plans')
        .select(_selectQuery)
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
        .select(_selectQuery)
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) return null;
    return WorkoutPlan.fromMap(row);
  }

  Future<WorkoutPlan> savePlan(
    WorkoutPlan plan, {
    bool setActive = false,
  }) async {
    final userId = _currentUser?.id;
    if (userId == null) {
      throw const AuthException('You need to be signed in to save plans.');
    }

    if (setActive) {
      await _client
          .from('workout_plans')
          .update({'is_active': false})
          .eq('user_id', userId);
    }

    final trimmedName = plan.name.trim().isEmpty ? 'Workout Plan' : plan.name.trim();
    final planPayload = <String, dynamic>{
      'user_id': userId,
      'name': trimmedName,
      'notes': plan.notes?.trim().isEmpty == true ? null : plan.notes?.trim(),
      'is_active': setActive,
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

    for (var exerciseIndex = 0; exerciseIndex < plan.exercises.length; exerciseIndex++) {
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

  static const String _selectQuery =
      'id, user_id, name, notes, is_active, created_at, updated_at, '
      'workout_plan_exercises('
      'id, workout_plan_id, sort_order, exercise_key, display_name, workout_type, asset_path, target_joints, '
      'workout_plan_sets(id, workout_plan_exercise_id, sort_order, reps, variation)'
      ')';
}
