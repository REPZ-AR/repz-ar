import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMatcher {
  // 1. Generalized Normalization Logic
  static Map<String, Offset> normalize({
    required Offset leftShoulder,
    required Offset rightShoulder,
    required Offset leftHip,
    required Offset rightHip,
    required Map<String, Offset> allLandmarks,
  }) {
    // Find Origin (Center of Hips)
    final originX = (leftHip.dx + rightHip.dx) / 2;
    final originY = (leftHip.dy + rightHip.dy) / 2;

    // Find Center of Shoulders
    final shoulderCenterX = (leftShoulder.dx + rightShoulder.dx) / 2;
    final shoulderCenterY = (leftShoulder.dy + rightShoulder.dy) / 2;

    // Calculate Scale (Torso Length)
    final torsoLength = sqrt(pow(shoulderCenterX - originX, 2) + pow(shoulderCenterY - originY, 2));

    if (torsoLength == 0) return {}; // Prevent division by zero

    // Normalize all provided landmarks
    Map<String, Offset> normalized = {};
    allLandmarks.forEach((name, point) {
      // LaTeX translation: $X_{norm} = \frac{X_{raw} - X_{origin}}{TorsoLength}$
      final normX = (point.dx - originX) / torsoLength;
      final normY = (point.dy - originY) / torsoLength;
      normalized[name] = Offset(normX, normY);
    });

    return normalized;
  }

  // 2. Extract and Normalize Real-time Pose
  static Map<String, Offset>? normalizeLivePose(Pose pose) {
    final leftS = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightS = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftH = pose.landmarks[PoseLandmarkType.leftHip];
    final rightH = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftS == null || rightS == null || leftH == null || rightH == null) return null;

    Map<String, Offset> rawLandmarks = {};
    pose.landmarks.forEach((type, lm) {
      rawLandmarks[type.name] = Offset(lm.x, lm.y);
    });

    return normalize(
      leftShoulder: Offset(leftS.x, leftS.y),
      rightShoulder: Offset(rightS.x, rightS.y),
      leftHip: Offset(leftH.x, leftH.y),
      rightHip: Offset(rightH.x, rightH.y),
      allLandmarks: rawLandmarks,
    );
  }

  // 3. Extract and Normalize Baseline Frame
  static Map<String, Offset>? normalizeBaselineFrame(Map<String, dynamic> baselineLandmarks) {
    // Assuming your baseline JSON uses the map structure from utils.dart
    final leftS = baselineLandmarks['leftShoulder'];
    final rightS = baselineLandmarks['rightShoulder'];
    final leftH = baselineLandmarks['leftHip'];
    final rightH = baselineLandmarks['rightHip'];

    if (leftS == null || rightS == null || leftH == null || rightH == null) return null;

    Map<String, Offset> rawLandmarks = {};
    baselineLandmarks.forEach((name, lm) {
      rawLandmarks[name] = Offset((lm['x'] as num).toDouble(), (lm['y'] as num).toDouble());
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
  static int findClosestFrameIndex(Map<String, Offset> liveNormalized, List<Map<String, Offset>> baselineNormalized, List<String> targetJoints) {
    double lowestDistance = double.infinity;
    int closestIndex = -1;

    for (int i = 0; i < baselineNormalized.length; i++) {
      double totalDistance = 0;
      int validJoints = 0;

      for (String joint in targetJoints) {
        final liveJoint = liveNormalized[joint];
        final baseJoint = baselineNormalized[i][joint];

        if (liveJoint != null && baseJoint != null) {
          totalDistance += pow(liveJoint.dx - baseJoint.dx, 2) + pow(liveJoint.dy - baseJoint.dy, 2);
          validJoints++;
        }
      }

      if (validJoints > 0) {
        double mse = totalDistance / validJoints;
        if (mse < lowestDistance) {
          lowestDistance = mse;
          closestIndex = i;
        }
      }
    }
    return closestIndex;
  }
}