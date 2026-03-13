import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:repz/views/utils/logger.dart';
import 'package:repz/views/utils/pose_utils.dart';
import 'package:repz/views/utils/workout_analyzer.dart';

import '../model/workout.dart';
import 'detector_view.dart';
import 'painters/pose_painter.dart';

class PoseDetectorView extends StatefulWidget {
  final List<Exercise> exercises;
  final int initialIndex;

  const PoseDetectorView({
    super.key,
    required this.exercises,
    this.initialIndex = 0
  });

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  late int _currentIndex;
  late Exercise _currentExercise;

  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions(model: PoseDetectionModel.accurate));
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  PoseLogger _logger = PoseLogger();
  List<Map<String, Offset>> _normalizedBaseline = [];
  bool _isBaselineLoaded = false;
  DateTime _lastFeedbackTime = DateTime.now();
  Set<PoseLandmarkType> _currentBadJoints = {};

  final List<String> _activeWorkoutJoints = ['leftShoulder', 'leftElbow', 'leftWrist'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadExercise(_currentIndex);
  }

  void _loadExercise(int index) {
    setState(() {
      _isBaselineLoaded = false;
      _currentExercise = widget.exercises[index];
    });
    _loadAndNormalizeBaseline(_currentExercise.assetPath);
  }

  Future<void> _loadAndNormalizeBaseline(String path) async {
    try {
      final String response = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(response);

      List<Map<String, Offset>> tempNormalized = [];

      for (var frameData in data) {
        // Assuming your JSON has a 'landmarks' key that maps to the utils.dart structure
        final landmarksMap = frameData['landmarks'] as Map<String, dynamic>;
        final normalizedFrame = PoseMatcher.normalizeBaselineFrame(landmarksMap);

        if (normalizedFrame != null) {
          tempNormalized.add(normalizedFrame);
        }
      }

      setState(() {
        _normalizedBaseline = tempNormalized;
        _isBaselineLoaded = true;
      });
      print("Baseline loaded and normalized: ${_normalizedBaseline.length} frames.");
    } catch (e) {
      print("Error loading baseline: $e");
    }
  }


  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Pose Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isNotEmpty && _isBaselineLoaded) {
      final currentPose = poses.first;

      // 1. Normalize the live frame
      final normalizedLive = PoseMatcher.normalizeLivePose(currentPose);

      if (normalizedLive != null) {
        // 2. Find closest baseline frame index
        final closestIndex = PoseMatcher.findClosestFrameIndex(
            normalizedLive,
            _normalizedBaseline,
            _activeWorkoutJoints
        );

        if (closestIndex != -1) {
          // 3. We found a match! Provide visual text feedback
          _text = 'Matched Baseline Frame: $closestIndex / ${_normalizedBaseline.length}\n';

          if (poses.isNotEmpty && _isBaselineLoaded) {
            final currentPose = poses.first;

            // 1. Normalize the live frame
            final normalizedLive = PoseMatcher.normalizeLivePose(currentPose);

            if (normalizedLive != null) {
              // 2. Find closest baseline frame index
              final closestIndex = PoseMatcher.findClosestFrameIndex(
                  normalizedLive,
                  _normalizedBaseline,
                  _activeWorkoutJoints
              );

              if (closestIndex != -1) {
                final matchedBaselineFrame = _normalizedBaseline[closestIndex];

                WorkoutFeedback feedback = WorkoutAnalyzer.analyze(
                    _currentExercise.type,
                    normalizedLive,
                    matchedBaselineFrame
                );

                // 4. Update the UI Text
                final now = DateTime.now();
                if (now.difference(_lastFeedbackTime).inMilliseconds > 400) {
                  _text = 'Match: $closestIndex / ${_normalizedBaseline.length}\nFeedback: ${feedback.message}';
                  _currentBadJoints = feedback.badJoints;
                  _lastFeedbackTime = now;
                }
              }
            }
          }
        }
      }
    }
    _logger.logPoses(poses);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = PosePainter(
        poses,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
        _currentBadJoints,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _text = 'Poses found: ${poses.length}\n\n';
      // TODO: set _customPaint to draw landmarks on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _nextExercise() {
    if (_currentIndex < widget.exercises.length - 1) {
      _loadExercise(_currentIndex + 1);
    } else {
      Navigator.pop(context); // Workout complete
    }
  }
}
