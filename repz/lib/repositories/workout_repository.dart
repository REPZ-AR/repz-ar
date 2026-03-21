import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutRepository {
  final SupabaseClient _client;

  WorkoutRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetches the current workout index. Returns 0 if no record exists yet.
  Future<int> fetchWorkoutProgress(String userId) async {
    final row = await _client
        .from('workout_progress')
        .select('current_workout_index')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return 0;
    return row['current_workout_index'] as int;
  }

  /// Upserts the workout progress.
  /// If a row for this user doesn't exist, it creates one. If it does, it updates it.
  Future<void> syncWorkoutProgress(String userId, int index) async {
    await _client.from('workout_progress').upsert({
      'user_id': userId,
      'current_workout_index': index,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }
}