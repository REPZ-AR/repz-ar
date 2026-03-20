import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../model/coordinate_point.dart';

class PoseMatcher {
  // 1. Generalized Normalization Logic
  static Map<String, Point3D> normalize({
    required Point3D leftShoulder,
    required Point3D rightShoulder,
    required Point3D leftHip,
    required Point3D rightHip,
    required Map<String, Point3D> allLandmarks,
  }) {
    // Find Origin (Center of Hips)
    final originX = (leftHip.x + rightHip.x) / 2;
    final originY = (leftHip.y + rightHip.y) / 2;
    final originZ = (leftHip.z + rightHip.z) / 2;

    // Find Center of Shoulders
    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderCenterY = (leftShoulder.y + rightShoulder.y) / 2;
    final shoulderCenterZ = (leftShoulder.z + rightShoulder.z) / 2;

    // Calculate Scale (Torso Length)
    final torsoLength = sqrt(
        pow(shoulderCenterX - originX, 2) +
            pow(shoulderCenterY - originY, 2) +
            pow(shoulderCenterZ - originZ, 2)
    );

    if (torsoLength == 0) return {}; // Prevent division by zero

    // Normalize all provided landmarks
    Map<String, Point3D> normalized = {};
    allLandmarks.forEach((name, point) {
      normalized[name] = Point3D(
        (point.x - originX) / torsoLength,
        (point.y - originY) / torsoLength,
        (point.z - originZ) / torsoLength,
      );
    });

    return normalized;
  }

  // 2. Extract and Normalize Real-time Pose
  static Map<String, Point3D>? normalizeLivePose(Pose pose) {
    final leftS = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightS = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftH = pose.landmarks[PoseLandmarkType.leftHip];
    final rightH = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftS == null || rightS == null || leftH == null || rightH == null) return null;

    Map<String, Point3D> rawLandmarks = {};
    pose.landmarks.forEach((type, lm) {
      rawLandmarks[type.name] = Point3D(lm.x, lm.y, lm.z);
    });

    return normalize(
      leftShoulder: Point3D(leftS.x, leftS.y, leftS.z),
      rightShoulder: Point3D(rightS.x, rightS.y, rightS.z),
      leftHip: Point3D(leftH.x, leftH.y, leftH.z),
      rightHip: Point3D(rightH.x, rightH.y, rightH.z),
      allLandmarks: rawLandmarks,
    );
  }

  // 3. Extract and Normalize Baseline Frame
  static Map<String, Point3D>? normalizeBaselineFrame(Map<String, dynamic> baselineLandmarks) {
    // Assuming your baseline JSON uses the map structure from utils.dart
    final leftS = baselineLandmarks['leftShoulder'];
    final rightS = baselineLandmarks['rightShoulder'];
    final leftH = baselineLandmarks['leftHip'];
    final rightH = baselineLandmarks['rightHip'];

    if (leftS == null || rightS == null || leftH == null || rightH == null) return null;

    Map<String, Point3D> rawLandmarks = {};
    baselineLandmarks.forEach((name, lm) {
      rawLandmarks[name] = Point3D((lm['x'] as num).toDouble(), (lm['y'] as num).toDouble(), (lm['z'] as num).toDouble());
    });

    return normalize(
      leftShoulder: rawLandmarks['leftShoulder']!,
      rightShoulder: rawLandmarks['rightShoulder']!,
      leftHip: rawLandmarks['leftHip']!,
      rightHip: rawLandmarks['rightHip']!,
      allLandmarks: rawLandmarks,
    );
  }

  // 4. Find closest frame using Mean Squared Error
  static int findClosestFrameIndex(Map<String, Point3D> liveNormalized, List<Map<String, Point3D>> baselineNormalized, List<String> targetJoints, int lastMatchedIndex,
      {int windowBackward = 10, int windowForward = 20}) {
    double lowestDistance = double.infinity;
    int closestIndex = -1;
    int totalFrames = baselineNormalized.length;

    if (totalFrames == 0) return -1;

    // GLOBAL SEARCH: If no previous match, search the whole video
    if (lastMatchedIndex == -1) {
      for (int i = 0; i < totalFrames; i++) {
        double mse = _calculate3DMSE(
            liveNormalized, baselineNormalized[i], targetJoints);
        if (mse < lowestDistance) {
          lowestDistance = mse;
          closestIndex = i;
        }
      }
      return closestIndex;
    }

    // CYCLIC ROLLING WINDOW: Search a neighborhood around the last match
    for (int offset = -windowBackward; offset <= windowForward; offset++) {
      // Modulo arithmetic smoothly wraps around the end of the video to the beginning
      int i = (lastMatchedIndex + offset) % totalFrames;
      if (i < 0) i += totalFrames; // Safety for negative modulo in Dart

      double mse = _calculate3DMSE(
          liveNormalized, baselineNormalized[i], targetJoints);
      if (mse < lowestDistance) {
        lowestDistance = mse;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  static double _calculate3DMSE(Map<String, Point3D> live, Map<String, Point3D> base, List<String> joints) {
    double totalDistance = 0;
    int validJoints = 0;

    for (String joint in joints) {
      final liveJoint = live[joint];
      final baseJoint = base[joint];

      if (liveJoint != null && baseJoint != null) {
        // 3D Distance Squared
        totalDistance += pow(liveJoint.x - baseJoint.x, 2) +
            pow(liveJoint.y - baseJoint.y, 2) +
            pow(liveJoint.z - baseJoint.z, 2);
        validJoints++;
      }
    }
    return validJoints > 0 ? (totalDistance / validJoints) : double.infinity;
  }
}