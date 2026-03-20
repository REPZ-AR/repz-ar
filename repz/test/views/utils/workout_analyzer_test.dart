import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:repz/model/workout.dart';
import 'package:repz/views/utils/workout_analyzer.dart';
import 'package:repz/model/coordinate_point.dart';

void main() {
  group('WorkoutAnalyzer Math Tests', () {
    test('getAngle calculates 90 degrees correctly in 3D space', () {
      final p1 = Point3D(0, 10, 0);
      final p2 = Point3D(0, 0, 0); // Vertex
      final p3 = Point3D(10, 0, 0);

      final angle = WorkoutAnalyzer.getAngle(p1, p2, p3);
      expect(angle, closeTo(90.0, 0.1));
    });

    test('getAngle calculates 180 degrees correctly in 3D space', () {
      final p1 = Point3D(-10, 0, 0);
      final p2 = Point3D(0, 0, 0); // Vertex
      final p3 = Point3D(10, 0, 0);

      final angle = WorkoutAnalyzer.getAngle(p1, p2, p3);
      expect(angle, closeTo(180.0, 0.1));
    });
  });

  group('WorkoutAnalyzer Bicep Curl Feedback', () {
    // Define a perfect baseline pose
    final baselinePose = {
      'leftHip': Point3D(0, 10, 0),
      'leftShoulder': Point3D(0, 5, 0),
      'leftElbow': Point3D(0, 7, 0), // Arm straight down
      'leftWrist': Point3D(0, 10, 0),
    };

    test('Returns Good Form when angles match baseline', () {
      final feedback = WorkoutAnalyzer.analyze(WorkoutType.curls, baselinePose, baselinePose);

      expect(feedback.message, "Good form!");
      expect(feedback.badJoints, isEmpty);
    });

    test('Detects swinging when shoulder angle difference is > 15', () {
      final livePose = Map<String, Point3D>.from(baselinePose);
      // Move the elbow backwards to simulate swinging backwards
      livePose['leftElbow'] = Point3D(-3, 7, 0);

      final feedback = WorkoutAnalyzer.analyze(WorkoutType.curls, livePose, baselinePose);

      expect(feedback.message, contains("Keep your left elbow pinned"));
      expect(feedback.badJoints, containsAll([
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftHip
      ]));
    });

    test('Detects lagging when elbow angle difference is > 20', () {
      final livePose = Map<String, Point3D>.from(baselinePose);
      final testBaseline = Map<String, Point3D>.from(baselinePose);

      // Simulate baseline being deeply curled, but live is straight
      testBaseline['leftWrist'] = Point3D(3, 4, 0); // curled up

      final feedback = WorkoutAnalyzer.analyze(WorkoutType.curls, livePose, testBaseline);

      expect(feedback.message, contains("Curl your left arm more"));
      expect(feedback.badJoints, containsAll([
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist
      ]));
    });

    test('Detects rushing when elbow angle difference is < -20', () {
      final livePose = Map<String, Point3D>.from(baselinePose);
      final testBaseline = Map<String, Point3D>.from(baselinePose);

      // Simulate live being deeply curled, but baseline is straight
      livePose['leftWrist'] = Point3D(3, 4, 0);

      final feedback = WorkoutAnalyzer.analyze(WorkoutType.curls, livePose, testBaseline);

      expect(feedback.message, contains("Slow down"));
      expect(feedback.badJoints, containsAll([
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist
      ]));
    });
  });
}