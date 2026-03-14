enum WorkoutType { curls, squats, benchPress, lifts }

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