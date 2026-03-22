enum WorkoutType {
  curls('CURLS'),
  squats('SQUATS'),
  benchPress('BENCH_PRESS'),
  lifts('LIFTS'),
  planks('PLANKS');

  const WorkoutType(this.dbValue);

  final String dbValue;

  static WorkoutType? fromDbValue(String? value) {
    if (value == null) return null;

    for (final type in WorkoutType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }

    return null;
  }
}

class Exercise {
  final String id;
  final String name;
  final String duration;
  final String sets;
  final WorkoutType type;
  final List<dynamic> baselineData;
  final List<String> targetJoints;

  Exercise({
    required this.id,
    required this.name,
    required this.duration,
    required this.sets,
    required this.type,
    required this.baselineData,
    required this.targetJoints,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      duration: map['duration'],
      sets: map['sets'],
      type: WorkoutType.fromDbValue(map['type'])!,
      baselineData: List<dynamic>.from(map['baseline_data']),
      targetJoints: List<String>.from(map['target_joints']),
    );
  }
}