import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/trainer.dart';

class TrainerService {
  final _supabase = Supabase.instance.client;

  String get _clientId => _supabase.auth.currentUser!.id;

  Trainer _trainerFromUserInfoRow(
    Map<String, dynamic> row, {
    required String subtitle,
  }) {
    final trainerId = row['user_id'] as String;
    final fullName = (row['full_name'] as String?)?.trim();

    return Trainer(
      id: trainerId,
      name:
          fullName != null && fullName.isNotEmpty
              ? fullName
              : 'Trainer ${trainerId.substring(0, 6)}',
      subtitle: subtitle,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  Future<List<Trainer>> _fetchTrainerDetails(
    List<String> trainerIds, {
    required String subtitle,
  }) async {
    if (trainerIds.isEmpty) return const <Trainer>[];

    final rows = await _supabase
        .from('users_info')
        .select('user_id, full_name, avatar_url')
        .inFilter('user_id', trainerIds);

    final userInfoById = {
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        row['user_id'] as String: row,
    };

    return trainerIds.map((trainerId) {
      final userInfo = userInfoById[trainerId];
      return _trainerFromUserInfoRow(
        userInfo ?? <String, dynamic>{'user_id': trainerId},
        subtitle: subtitle,
      );
    }).toList();
  }

  Future<List<Trainer>> fetchTrainers() async {
    final relations = await _supabase
        .from('trainer_client')
        .select('trainer_id')
        .eq('client_id', _clientId)
        .eq('status', 'active');

    if (relations.isEmpty) return [];

    final trainerIds = (relations as List)
        .cast<Map<String, dynamic>>()
        .map((row) => row['trainer_id'] as String)
        .toList();

    return _fetchTrainerDetails(
      trainerIds,
      subtitle: 'Your Trainer',
    );
  }

  Future<List<Trainer>> fetchAvailableTrainers() async {
    final existing = await _supabase
        .from('trainer_client')
        .select('trainer_id')
        .eq('client_id', _clientId);

    final existingIds = (existing as List)
        .cast<Map<String, dynamic>>()
        .map((row) => row['trainer_id'] as String)
        .toList();

    final result = await _supabase
        .from('users_info')
        .select('user_id, full_name, avatar_url')
        .eq('role', 'trainer')
        .neq('user_id', _clientId);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .where((row) => !existingIds.contains(row['user_id'] as String))
        .map(
          (row) => _trainerFromUserInfoRow(
            row,
            subtitle: 'Available',
          ),
        )
        .toList();
  }

  Future<void> addTrainer({required String trainerUserId}) async {
    await _supabase.from('trainer_client').insert({
      'trainer_id': trainerUserId,
      'client_id': _clientId,
      'status': 'active',
      'client_type': 'online',
    });
  }

  Future<void> removeTrainer({required String trainerUserId}) async {
    await _supabase
        .from('trainer_client')
        .delete()
        .eq('trainer_id', trainerUserId)
        .eq('client_id', _clientId);
  }
}
