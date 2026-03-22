import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:repz/model/workout.dart';

class ExerciseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Exercise>> fetchExercises() async {
    final response = await _supabase
        .from('exercises')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => Exercise.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Exercise>> fetchExercisesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await _supabase
        .from('exercises')
        .select()
        .inFilter('id', ids)
        .eq('is_active', true);

    return (response as List)
        .map((row) => Exercise.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}