class MuscleGroup {
  final String id;
  final String muscleGroupName;
  final String muscleClass;
  final String? description;

  const MuscleGroup({
    required this.id,
    required this.muscleGroupName,
    required this.muscleClass,
    this.description,
  });

  factory MuscleGroup.fromMap(Map<String, dynamic> map) {
    return MuscleGroup(
      id: map['id'] as String,
      muscleGroupName: map['muscle_group_name'] as String,
      muscleClass: map['muscle_class'] as String,
      description: map['description'] as String?,
    );
  }

  MuscleGroup copyWith({
    String? id,
    String? muscleGroupName,
    String? muscleClass,
    String? description,
  }) {
    return MuscleGroup(
      id: id ?? this.id,
      muscleGroupName: muscleGroupName ?? this.muscleGroupName,
      muscleClass: muscleClass ?? this.muscleClass,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'muscle_group_name': muscleGroupName,
      'muscle_class': muscleClass,
      'description': description,
    };
  }
}

