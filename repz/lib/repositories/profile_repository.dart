import 'package:repz/model/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Fetches the full profile row for [userId].
  /// Returns `null` when no row exists yet.
  Future<Profile?> fetchProfile(String userId) async {
    final row =
        await _client
            .from('profile')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    if (row == null) return null;
    return Profile.fromMap(row);
  }

  /// Persists [mode] for [userId] and returns the updated profile.
  Future<Profile> saveMode(String userId, ProfileMode mode) async {
    final row =
        await _client
            .from('profile')
            .update({'mode': mode.dbValue})
            .eq('user_id', userId)
            .select()
            .single();

    return Profile.fromMap(row);
  }

  /// Saves onboarding fields for [userId] and marks `first_time` as `false`.
  Future<Profile> saveOnboarding({
    required String userId,
    required DateTime birthday,
    required String gender,
    required double heightCm,
    required double weightKg,
    required ExperienceLevel experience,
    required int frequency,
  }) async {
    final birthdayDate =
        '${birthday.year.toString().padLeft(4, '0')}-'
        '${birthday.month.toString().padLeft(2, '0')}-'
        '${birthday.day.toString().padLeft(2, '0')}';

    final row =
        await _client
            .from('profile')
            .update({
              'birthday': birthdayDate,
              'gender': gender,
              'height_cm': heightCm,
              'weight_kg': weightKg,
              'experience': experience.dbValue,
              'frequency': frequency,
              'first_time': false,
            })
            .eq('user_id', userId)
            .select()
            .single();

    return Profile.fromMap(row);
  }

  /// Sets `first_time` to `false` for [userId] and returns the updated profile.
  Future<Profile> markFirstTimeComplete(String userId) async {
    final row =
        await _client
            .from('profile')
            .update({'first_time': false})
            .eq('user_id', userId)
            .select()
            .single();

    return Profile.fromMap(row);
  }
}
