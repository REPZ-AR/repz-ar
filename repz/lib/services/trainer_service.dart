import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/trainer.dart';

class TrainerService {
  final _supabase = Supabase.instance.client;

  String get _clientId => _supabase.auth.currentUser!.id;

  Future<List<Trainer>> fetchTrainers() async {
    final result = await _supabase
        .from('trainer_client')
        .select('trainer_id, status')
        .eq('client_id', _clientId)
        .eq('status', 'active');

    if (result.isEmpty) return [];

    return (result as List).map((row) => Trainer(
      id: row['trainer_id'] as String,
      name: 'Trainer',
      subtitle: 'Your Trainer',
      avatarUrl: null,
    )).toList();
  }
}