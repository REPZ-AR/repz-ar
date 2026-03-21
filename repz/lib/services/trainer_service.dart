import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/trainer.dart';

class TrainerService {
  final _supabase = Supabase.instance.client;

  String get _clientId => _supabase.auth.currentUser!.id;

  Future<List<Trainer>> fetchTrainers() async {
    final relations = await _supabase
        .from('trainer_client')
        .select('trainer_id')
        .eq('client_id', _clientId)
        .eq('status', 'active');

    if (relations.isEmpty) return [];

    final trainerIds = (relations as List)
        .map((r) => r['trainer_id'] as String)
        .toList();

    return trainerIds.map((id) => Trainer(
      id: id,
      name: 'Trainer',
      subtitle: 'Your Trainer',
      avatarUrl: null,
    )).toList();
  }

  Future<List<Trainer>> fetchAvailableTrainers() async {
    final existing = await _supabase
        .from('trainer_client')
        .select('trainer_id')
        .eq('client_id', _clientId);

    final existingIds = (existing as List)
        .map((r) => r['trainer_id'] as String)
        .toList();

    final result = await _supabase
        .from('profile')
        .select('user_id')
        .eq('mode', 'TRAINER')
        .neq('user_id', _clientId);

    return (result as List)
        .where((r) => !existingIds.contains(r['user_id'] as String))
        .map((r) => Trainer(
      id: r['user_id'] as String,
      name: 'Trainer',
      subtitle: 'Available',
      avatarUrl: null,
    ))
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
}