import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/client.dart';

class ClientService {
  final _supabase = Supabase.instance.client;

  String get _trainerId => _supabase.auth.currentUser!.id;

  Client _clientFromUserInfoRow(
      Map<String, dynamic> row, {
        required String clientType,
        required String status,
        required DateTime? joinedDate,
      }) {
    final clientId = row['user_id'] as String;
    final fullName = (row['full_name'] as String?)?.trim();

    return Client(
      id: clientId,
      name: fullName != null && fullName.isNotEmpty
          ? fullName
          : 'Client ${clientId.substring(0, 6)}',
      subtitle: clientType == 'online' ? 'Online' : 'Gym',
      avatarUrl: row['avatar_url'] as String?,
      status: status,
      joinedDate: joinedDate,
    );
  }

  Future<List<Client>> fetchClients() async {
    // Step 1: get all client relationships for this trainer
    final relations = await _supabase
        .from('trainer_client')
        .select('client_id, client_type, status, created_at')
        .eq('trainer_id', _trainerId);

    if (relations.isEmpty) return [];

    final rows = (relations as List).cast<Map<String, dynamic>>();

    // Step 2: extract client IDs
    final clientIds = rows.map((r) => r['client_id'] as String).toList();

    // Step 3: fetch from users_info (same as TrainerService)
    final userInfoRows = await _supabase
        .from('users_info')
        .select('user_id, full_name, avatar_url')
        .inFilter('user_id', clientIds);

    // Step 4: build lookup map
    final userInfoById = {
      for (final row in (userInfoRows as List).cast<Map<String, dynamic>>())
        row['user_id'] as String: row,
    };

    // Step 5: merge and build Client list
    return rows.map((row) {
      final clientId = row['client_id'] as String;
      final userInfo = userInfoById[clientId]
          ?? <String, dynamic>{'user_id': clientId};

      return _clientFromUserInfoRow(
        userInfo,
        clientType: row['client_type'] as String? ?? 'online',
        status: row['status'] as String? ?? 'active',
        joinedDate: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
      );
    }).toList();
  }

  Future<void> addClient({
    required String clientUserId,
    required String clientType,
  }) async {
    await _supabase.from('trainer_client').insert({
      'trainer_id': _trainerId,
      'client_id': clientUserId,
      'client_type': clientType,
    });
  }

  Future<void> removeClient({required String clientUserId}) async {
    await _supabase
        .from('trainer_client')
        .delete()
        .eq('trainer_id', _trainerId)
        .eq('client_id', clientUserId);
  }
}