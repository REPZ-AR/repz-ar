import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class WorkoutFeedback {
  final String message;
  final Set<PoseLandmarkType> badJoints;

  WorkoutFeedback(this.message, this.badJoints);
}

class WorkoutAnalyzer {
  /// Calculates the interior angle between three points.
  /// [midPoint] is the vertex of the angle (e.g., the elbow).
  static double getAngle(Offset firstPoint, Offset midPoint, Offset lastPoint) {
    // Calculate the angle using atan2
    double result = atan2(
        lastPoint.dy - midPoint.dy, lastPoint.dx - midPoint.dx) -
        atan2(firstPoint.dy - midPoint.dy, firstPoint.dx - midPoint.dx);

    // Convert radians to degrees
    result = result * (180 / pi);

    // Ensure the angle is positive
    result = result.abs();

    // We want the interior angle (always <= 180 degrees)
    if (result > 180.0) {
      result = 360.0 - result;
    }

    return result;
  }

  static WorkoutFeedback compareCurlAngles(Map<String, Offset> livePose,
      Map<String, Offset> baselinePose) {
    final liveHip = livePose['leftHip'];
    final liveShoulder = livePose['leftShoulder'];
    final liveElbow = livePose['leftElbow'];
    final liveWrist = livePose['leftWrist'];

    final baseHip = baselinePose['leftHip'];
    final baseShoulder = baselinePose['leftShoulder'];
    final baseElbow = baselinePose['leftElbow'];
    final baseWrist = baselinePose['leftWrist'];

    // Check Shoulder Stability (Swinging)
    if (liveHip != null && liveShoulder != null && liveElbow != null &&
        baseHip != null && baseShoulder != null && baseElbow != null) {
      double liveShoulderAngle = getAngle(liveHip, liveShoulder, liveElbow);
      double baseShoulderAngle = getAngle(baseHip, baseShoulder, baseElbow);

      if ((liveShoulderAngle - baseShoulderAngle) > 15.0) {
        return WorkoutFeedback(
            "Keep your elbow pinned to your side! Don't swing.",
            // Flag the shoulder, elbow, and hip to turn red
            {
              PoseLandmarkType.leftShoulder,
              PoseLandmarkType.leftElbow,
              PoseLandmarkType.leftHip
            }
        );
      }
    }

    // Check Elbow Flexion (Timing/Pacing)
    if (liveShoulder != null && liveElbow != null && liveWrist != null &&
        baseShoulder != null && baseElbow != null && baseWrist != null) {
      double liveElbowAngle = getAngle(liveShoulder, liveElbow, liveWrist);
      double baseElbowAngle = getAngle(baseShoulder, baseElbow, baseWrist);

      double difference = liveElbowAngle - baseElbowAngle;

      if (difference > 20.0) {
        return WorkoutFeedback(
            "Curl your arm more! You are lagging behind.",
            // Flag the arm joints to turn red
            {
              PoseLandmarkType.leftShoulder,
              PoseLandmarkType.leftElbow,
              PoseLandmarkType.leftWrist
            }
        );
      } else if (difference < -20.0) {
        return WorkoutFeedback(
            "Slow down! You are curling too fast.",
            {
              PoseLandmarkType.leftShoulder,
              PoseLandmarkType.leftElbow,
              PoseLandmarkType.leftWrist
            }
        );
      }
    }

    // Default Good State
    return WorkoutFeedback("Good form!", {});
  }
}