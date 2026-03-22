import 'package:repz/model/gym_equipment.dart';
import 'package:repz/model/muscle_group.dart';
import 'package:repz/model/tutorial.dart';

class EquipmentDetails {
  const EquipmentDetails({
    required this.equipment,
    required this.muscleGroups,
    required this.tutorials,
  });

  final GymEquipment equipment;
  final List<MuscleGroup> muscleGroups;
  final List<Tutorial> tutorials;
}

