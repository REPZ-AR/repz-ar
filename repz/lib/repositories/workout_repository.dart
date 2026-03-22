import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutProgressState {
  const WorkoutProgressState({
    required this.currentWorkoutIndex,
    this.currentWorkoutPlanId,
  });

  final int currentWorkoutIndex;
  final String? currentWorkoutPlanId;
}

class WorkoutRepository {
  final SupabaseClient _client;

  WorkoutRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<WorkoutProgressState> fetchWorkoutProgressState(String userId) async {
    final row = await _client
        .from('workout_progress')
        .select('current_workout_index, current_workout_plan_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) {
      return const WorkoutProgressState(currentWorkoutIndex: 0);
    }

    return WorkoutProgressState(
      currentWorkoutIndex: row['current_workout_index'] as int? ?? 0,
      currentWorkoutPlanId: row['current_workout_plan_id'] as String?,
    );
  }

  /// Fetches the current workout index. Returns 0 if no record exists yet.
  Future<int> fetchWorkoutProgress(
    String userId, {
    String? workoutPlanId,
  }) async {
    final state = await fetchWorkoutProgressState(userId);
    if (workoutPlanId != null && state.currentWorkoutPlanId != workoutPlanId) {
      return 0;
    }
    return state.currentWorkoutIndex;
  }

  /// Upserts the workout progress.
  /// If a row for this user doesn't exist, it creates one. If it does, it updates it.
  Future<void> syncWorkoutProgress(
    String userId,
    int index, {
    String? workoutPlanId,
  }) async {
    await _client.from('workout_progress').upsert({
      'user_id': userId,
      'current_workout_index': index,
      'current_workout_plan_id': workoutPlanId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
