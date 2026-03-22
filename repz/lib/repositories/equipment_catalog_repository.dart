import 'package:repz/model/equipment_details.dart';
import 'package:repz/model/gym_equipment.dart';
import 'package:repz/model/muscle_group.dart';
import 'package:repz/model/tutorial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EquipmentCatalogRepository {
  EquipmentCatalogRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<EquipmentDetails?> fetchEquipmentDetailsByName(String equipmentName) async {
    final normalizedName = equipmentName.trim();
    if (normalizedName.isEmpty) return null;

    final equipmentRow =
        await _client
            .from('gym_equipment')
            .select('equipment_id, equipment_name, created_date, updated_date')
            .ilike('equipment_name', normalizedName)
            .maybeSingle();

    if (equipmentRow == null) return null;

    final equipment = GymEquipment.fromMap(equipmentRow);

    final muscleRows = await _client
        .from('gym_equipment_muscle_group')
        .select('muscle_group(id, muscle_group_name, muscle_class, description)')
        .eq('equipment_id', equipment.equipmentId);

    final muscles =
        muscleRows
            .cast<Map<String, dynamic>>()
            .map((row) => row['muscle_group'])
            .whereType<Map<String, dynamic>>()
            .map(MuscleGroup.fromMap)
            .toList()
          ..sort(
            (a, b) => a.muscleGroupName.toLowerCase().compareTo(
              b.muscleGroupName.toLowerCase(),
            ),
          );

    final tutorialRows = await _client
        .from('tutorials')
        .select('id, equipment_id, description, tutorial_link, source')
        .eq('equipment_id', equipment.equipmentId)
        .order('source')
        .order('description');

    final tutorials =
        tutorialRows.cast<Map<String, dynamic>>().map(Tutorial.fromMap).toList();

    return EquipmentDetails(
      equipment: equipment,
      muscleGroups: muscles,
      tutorials: tutorials,
    );
  }
}

