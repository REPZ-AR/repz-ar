import 'package:flutter_test/flutter_test.dart';
import 'package:repz/views/utils/pose_utils.dart';
import 'package:repz/model/coordinate_point.dart';

void main() {
  group('PoseMatcher Normalization Tests', () {
    test('Normalizes 3D points relative to hip center and torso length', () {
      // Hips at (0,0,0) and (2,0,0) -> Origin center is (1,0,0)
      final leftHip = Point3D(0, 0, 0);
      final rightHip = Point3D(2, 0, 0);

      // Shoulders at (0,4,0) and (2,4,0) -> Center is (1,4,0)
      final leftShoulder = Point3D(0, 4, 0);
      final rightShoulder = Point3D(2, 4, 0);

      // Torso Length from (1,0,0) to (1,4,0) is 4.0

      final rawLandmarks = {
        'nose': Point3D(1, 6, 0), // 2 units above shoulder center
        'leftWrist': Point3D(-1, 2, 2),
      };

      final normalized = PoseMatcher.normalize(
        leftShoulder: leftShoulder,
        rightShoulder: rightShoulder,
        leftHip: leftHip,
        rightHip: rightHip,
        allLandmarks: rawLandmarks,
      );

      // Wrist raw X=-1. Origin X=1. (-1 - 1) / 4 = -0.5
      // Wrist raw Y=2. Origin Y=0. (2 - 0) / 4 = 0.5
      // Wrist raw Z=2. Origin Z=0. (2 - 0) / 4 = 0.5
      expect(normalized['leftWrist']!.x, closeTo(-0.5, 0.001));
      expect(normalized['leftWrist']!.y, closeTo(0.5, 0.001));
      expect(normalized['leftWrist']!.z, closeTo(0.5, 0.001));
    });
  });

  group('PoseMatcher Frame Matching Tests', () {
    test('findClosestFrameIndex identifies the frame with lowest 3D MSE', () {
      final live = {
        'leftShoulder': Point3D(0, 0, 0),
        'leftElbow': Point3D(0, 1, 0),
      };

      final baseline1 = { // Very different
        'leftShoulder': Point3D(2, 2, 2),
        'leftElbow': Point3D(2, 3, 2),
      };

      final baseline2 = { // Exact match
        'leftShoulder': Point3D(0, 0, 0),
        'leftElbow': Point3D(0, 1, 0),
      };

      final baseline3 = { // Slight difference
        'leftShoulder': Point3D(0.1, 0.1, 0.1),
        'leftElbow': Point3D(0.1, 1.1, 0.1),
      };

      final baselines = [baseline1, baseline2, baseline3];
      final targetJoints = ['leftShoulder', 'leftElbow'];

      // Start global search (lastMatchedIndex = -1)
      final closestIndex = PoseMatcher.findClosestFrameIndex(live, baselines, targetJoints, -1);

      // Baseline 2 is the exact match, which is at index 1
      expect(closestIndex, 1);
    });
  });
}