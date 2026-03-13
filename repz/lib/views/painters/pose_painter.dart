import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'coordinates_translator.dart';

class PosePainter extends CustomPainter {
  PosePainter(
    this.poses,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.badJoints,
  );

  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final Set<PoseLandmarkType> badJoints;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.yellow;

    final errorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 // Slightly thicker so it pops out
      ..color = Colors.red;

    final defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;

    final bodyPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = Colors.green;

    for (final pose in poses) {
      pose.landmarks.forEach((type, landmark) {
        // Switch to red if this joint is in our bad list
        final currentPaint = badJoints.contains(type) ? errorPaint : defaultPaint;

        canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, imageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, imageSize, rotation, cameraLensDirection),
            ),
            1,
            currentPaint);
      });

      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final joint1 = pose.landmarks[type1];
        final joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null) {
          // If EITHER joint connected by this line is "bad", paint the line red
          final currentPaint = (badJoints.contains(type1) || badJoints.contains(type2))
              ? errorPaint
              : defaultPaint;

          canvas.drawLine(
              Offset(
                translateX(joint1.x, size, imageSize, rotation, cameraLensDirection),
                translateY(joint1.y, size, imageSize, rotation, cameraLensDirection),
              ),
              Offset(
                translateX(joint2.x, size, imageSize, rotation, cameraLensDirection),
                translateY(joint2.y, size, imageSize, rotation, cameraLensDirection),
              ),
              currentPaint);
        }
      }

      //Draw arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      //Draw Body
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

      //Draw legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

      //Draw hands
      paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex);
      paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky);
      paintLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb);

      paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex);
      paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky);
      paintLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.poses != poses;
  }
}
