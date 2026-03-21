import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/client.dart';

class ClientService {
  final _supabase = Supabase.instance.client;

  String get _trainerId => _supabase.auth.currentUser!.id;

  Future<List<Client>> fetchClients({required String clientType}) async {
    final result = await _supabase
        .from('trainer_client')
        .select('client_id, client_type, status')
        .eq('trainer_id', _trainerId)
        .eq('client_type', clientType)
        .eq('status', 'active');

    if (result.isEmpty) return [];

    return (result as List).map((row) => Client(
      id: row['client_id'] as String,
      name: 'Client',  // placeholder until we add name column
      subtitle: clientType == 'online' ? 'Online Client' : 'Gym Client',
      avatarUrl: null,
    )).toList();
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