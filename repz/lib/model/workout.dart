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
  final String name;
  final String duration;
  final String sets;
  final WorkoutType type;
  final String assetPath; // workout baseline json
  final List<String> targetJoints;

  Exercise({
    required this.name,
    required this.duration,
    required this.sets,
    required this.type,
    required this.assetPath,
    required this.targetJoints,
  });
}
