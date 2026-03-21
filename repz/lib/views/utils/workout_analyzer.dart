import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:repz/model/coordinate_point.dart';

import '../../model/workout.dart';

class WorkoutFeedback {
  final String message;
  final Set<PoseLandmarkType> badJoints;

  WorkoutFeedback(this.message, this.badJoints);
}

class WorkoutAnalyzer {
  /// Calculates the interior angle between three points.
  /// [midPoint] is the vertex of the angle (e.g., the elbow).
  static double getAngle(Point3D firstPoint, Point3D midPoint, Point3D lastPoint) {
    // Create vectors from the midPoint (e.g., from Elbow to Shoulder, and Elbow to Wrist)
    double v1x = firstPoint.x - midPoint.x;
    double v1y = firstPoint.y - midPoint.y;
    double v1z = firstPoint.z - midPoint.z;

    double v2x = lastPoint.x - midPoint.x;
    double v2y = lastPoint.y - midPoint.y;
    double v2z = lastPoint.z - midPoint.z;

    // Calculate Dot Product
    double dotProduct = (v1x * v2x) + (v1y * v2y) + (v1z * v2z);

    // Calculate Magnitudes (Lengths of the vectors)
    double mag1 = sqrt((v1x * v1x) + (v1y * v1y) + (v1z * v1z));
    double mag2 = sqrt((v2x * v2x) + (v2y * v2y) + (v2z * v2z));

    // Prevent division by zero
    if (mag1 == 0 || mag2 == 0) return 0.0;

    // Calculate angle in radians
    double cosTheta = dotProduct / (mag1 * mag2);

    // Clamp cosTheta to [-1.0, 1.0] to prevent NaN errors due to floating-point rounding
    cosTheta = cosTheta.clamp(-1.0, 1.0);

    double angleRad = acos(cosTheta);

    // Convert to degrees
    return angleRad * (180 / pi);
  }

  static WorkoutFeedback analyze( //Factory for analyzing workouts
      WorkoutType type,
      Map<String, Point3D> livePose,
      Map<String, Point3D> baselinePose
      ) {
    switch (type) {
      case WorkoutType.curls:
        return _analyzeCurls(livePose, baselinePose);
      case WorkoutType.squats:
      // Future implementation for squats
        return WorkoutFeedback("Good form!", {});
      default:
        return WorkoutFeedback("Workout type not supported", {});
    }
  }

  // Write a method to return active workout joins

  static WorkoutFeedback _analyzeCurls(Map<String, Point3D> livePose, Map<String, Point3D> baselinePose) {
    final Set<PoseLandmarkType> badJoints = {};
    final List<String> messages = [];

    // Helper function to check form for a specific side
    void checkArm(
        String sideName,
        PoseLandmarkType hipType,
        PoseLandmarkType shoulderType,
        PoseLandmarkType elbowType,
        PoseLandmarkType wristType
        ) {
      final liveHip = livePose['${sideName}Hip'];
      final liveShoulder = livePose['${sideName}Shoulder'];
      final liveElbow = livePose['${sideName}Elbow'];
      final liveWrist = livePose['${sideName}Wrist'];

      final baseHip = baselinePose['${sideName}Hip'];
      final baseShoulder = baselinePose['${sideName}Shoulder'];
      final baseElbow = baselinePose['${sideName}Elbow'];
      final baseWrist = baselinePose['${sideName}Wrist'];

      // Check Shoulder Stability (Swinging)
      if (liveHip != null && liveShoulder != null && liveElbow != null &&
          baseHip != null && baseShoulder != null && baseElbow != null) {
        double liveShoulderAngle = getAngle(liveHip, liveShoulder, liveElbow);
        double baseShoulderAngle = getAngle(baseHip, baseShoulder, baseElbow);

        if ((liveShoulderAngle - baseShoulderAngle) > 15.0) {
          messages.add("Keep your $sideName elbow pinned! Don't swing.");
          badJoints.addAll({shoulderType, elbowType, hipType});
        }
      }

      // Check Elbow Flexion (Timing/Pacing)
      if (liveShoulder != null && liveElbow != null && liveWrist != null &&
          baseShoulder != null && baseElbow != null && baseWrist != null) {
        double liveElbowAngle = getAngle(liveShoulder, liveElbow, liveWrist);
        double baseElbowAngle = getAngle(baseShoulder, baseElbow, baseWrist);

        double difference = liveElbowAngle - baseElbowAngle;

        if (difference > 20.0) {
          messages.add("Curl your $sideName arm more! Lagging behind.");
          badJoints.addAll({shoulderType, elbowType, wristType});
        } else if (difference < -20.0) {
          messages.add("Slow down! Curling $sideName arm too fast.");
          badJoints.addAll({shoulderType, elbowType, wristType});
        }
      }
    }

    // Analyze Left Arm
    checkArm('left', PoseLandmarkType.leftHip, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);

    // Analyze Right Arm
    checkArm('right', PoseLandmarkType.rightHip, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // If there are any form issues, combine the messages and return the bad joints
    if (messages.isNotEmpty) {
      // Joins multiple issues with a space (e.g., "Keep your left elbow pinned! Slow down! Curling right arm too fast.")
      return WorkoutFeedback(messages.join(" "), badJoints);
    }

    // Default Good State
    return WorkoutFeedback("Good form!", {});
  }
}