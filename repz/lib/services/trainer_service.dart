import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/trainer.dart';

class TrainerService {
  final _supabase = Supabase.instance.client;

  String get _clientId => _supabase.auth.currentUser!.id;

  Trainer _trainerFromUserInfoRow(
      Map<String, dynamic> row, {
        required String subtitle,
        DateTime? joinedDate,
      }) {
    final trainerId = row['user_id'] as String;
    final fullName = (row['full_name'] as String?)?.trim();

    return Trainer(
      id: trainerId,
      name: fullName != null && fullName.isNotEmpty
          ? fullName
          : 'Trainer ${trainerId.substring(0, 6)}',
      subtitle: subtitle,
      avatarUrl: row['avatar_url'] as String?,
      joinedDate: joinedDate,
    );
  }

  Future<List<Trainer>> _fetchTrainerDetails(
      List<String> trainerIds, {
        required String subtitle,
        Map<String, DateTime?>? joinedDates,
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
        joinedDate: joinedDates?[trainerId],
      );
    }).toList();
  }

  Future<List<Trainer>> fetchTrainers() async {
    // Step 1: fetch relationships with created_at
    final relations = await _supabase
        .from('trainer_client')
        .select('trainer_id, created_at')
        .eq('client_id', _clientId)
        .eq('status', 'active');

    if (relations.isEmpty) return [];

    final rows =
    (relations as List).cast<Map<String, dynamic>>();

    // Step 2: extract trainer IDs
    final trainerIds =
    rows.map((row) => row['trainer_id'] as String).toList();

    // Step 3: build joined date lookup map
    final joinedDates = {
      for (final row in rows)
        row['trainer_id'] as String: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
    };

    return _fetchTrainerDetails(
      trainerIds,
      subtitle: 'Your Trainer',
      joinedDates: joinedDates,
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
        .where(
            (row) => !existingIds.contains(row['user_id'] as String))
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

  Future<void> removeTrainer(
      {required String trainerUserId}) async {
    await _supabase
        .from('trainer_client')
        .delete()
        .eq('trainer_id', trainerUserId)
        .eq('client_id', _clientId);
  }
}