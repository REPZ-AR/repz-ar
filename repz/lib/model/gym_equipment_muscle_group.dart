class GymEquipmentMuscleGroup {
  final String equipmentId;
  final String muscleGroupId;

  const GymEquipmentMuscleGroup({
    required this.equipmentId,
    required this.muscleGroupId,
  });

  factory GymEquipmentMuscleGroup.fromMap(Map<String, dynamic> map) {
    return GymEquipmentMuscleGroup(
      equipmentId: map['equipment_id'] as String,
      muscleGroupId: map['muscle_group_id'] as String,
    );
  }

  GymEquipmentMuscleGroup copyWith({
    String? equipmentId,
    String? muscleGroupId,
  }) {
    return GymEquipmentMuscleGroup(
      equipmentId: equipmentId ?? this.equipmentId,
      muscleGroupId: muscleGroupId ?? this.muscleGroupId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipment_id': equipmentId,
      'muscle_group_id': muscleGroupId,
    };
  }
}

