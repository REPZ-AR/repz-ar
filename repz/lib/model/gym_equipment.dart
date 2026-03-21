class GymEquipment {
  final String equipmentId;
  final String equipmentName;
  final DateTime createdDate;
  final DateTime updatedDate;

  const GymEquipment({
    required this.equipmentId,
    required this.equipmentName,
    required this.createdDate,
    required this.updatedDate,
  });

  factory GymEquipment.fromMap(Map<String, dynamic> map) {
    return GymEquipment(
      equipmentId: map['equipment_id'] as String,
      equipmentName: map['equipment_name'] as String,
      createdDate: DateTime.parse(map['created_date'] as String),
      updatedDate: DateTime.parse(map['updated_date'] as String),
    );
  }

  GymEquipment copyWith({
    String? equipmentId,
    String? equipmentName,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return GymEquipment(
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }
}

