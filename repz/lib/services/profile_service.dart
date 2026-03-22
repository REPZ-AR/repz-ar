import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/profile_data.dart';


class ProfileService {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  Future<ProfileData?> fetchCurrentUserProfile() async {
    try {
      final result = await _supabase
          .from('profile')
          .select('user_id, height_cm, weight_kg, frequency, mode, birthday, gender, experience')
          .eq('user_id', _userId)
          .single();

      return ProfileData.fromMap(result as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}