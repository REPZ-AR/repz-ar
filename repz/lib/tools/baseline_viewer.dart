import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaselineFrame {
  final int timestamp;
  final Map<String, dynamic> landmarks;

  BaselineFrame({required this.timestamp, required this.landmarks});

  factory BaselineFrame.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedLandmarks = {};

    // Check if the JSON file is using the older List format
    if (json['landmarks'] is List) {
      List<dynamic> listData = json['landmarks'];

      // Google ML Kit's standard index mapping
      const List<String> jointNames = [
        'nose', 'leftEyeInner', 'leftEye', 'leftEyeOuter',
        'rightEyeInner', 'rightEye', 'rightEyeOuter',
        'leftEar', 'rightEar', 'mouthLeft', 'mouthRight',
        'leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow',
        'leftWrist', 'rightWrist', 'leftPinky', 'rightPinky',
        'leftIndex', 'rightIndex', 'leftThumb', 'rightThumb',
        'leftHip', 'rightHip', 'leftKnee', 'rightKnee',
        'leftAnkle', 'rightAnkle', 'leftHeel', 'rightHeel',
        'leftFootIndex', 'rightFootIndex'
      ];

      for (int i = 0; i < listData.length; i++) {
        if (i < jointNames.length) {
          // Map the old index to the new string key
          parsedLandmarks[jointNames[i]] = listData[i];
        }
      }
    } else {
      // If it's already using the new format from utils.dart
      parsedLandmarks = Map<String, dynamic>.from(json['landmarks']);
    }

    return BaselineFrame(
      timestamp: json['timestamp'] ?? json['timestamp_ms'] ?? 0,
      landmarks: parsedLandmarks,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'landmarks': landmarks
  };
}

class BaselineInspector extends StatefulWidget {
  final String assetPath;

  const BaselineInspector({Key? key, required this.assetPath}) : super(key: key);

  @override
  _BaselineInspectorState createState() => _BaselineInspectorState();
}

class _BaselineInspectorState extends State<BaselineInspector> {
  List<BaselineFrame>? _frames;
  double _currentSliderValue = 0;

  @override
  void initState() {
    super.initState();
    _loadBaseline();
  }

  Future<void> _loadBaseline() async {
    try {
      final String response = await rootBundle.loadString(widget.assetPath);
      final List<dynamic> data = json.decode(response);
      setState(() {
        _frames = data.map((e) => BaselineFrame.fromJson(e)).toList();
      });
    } catch (e) {
      print("Error loading baseline: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Baseline Inspector"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _frames == null || _frames!.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _buildInspectorBody(),
    );
  }

  Widget _buildInspectorBody() {
    int frameIndex = (_currentSliderValue * (_frames!.length - 1)).round();
    final currentFrame = _frames![frameIndex];

    return Column(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child:
              SingleChildScrollView(
                child: Text(
                    JsonEncoder.withIndent('  ').convert(currentFrame),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.grey[100],
            child: CustomPaint(
              painter: BaselinePainter(landmarks: currentFrame.landmarks),
              size: Size.infinite,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Time: ${currentFrame.timestamp}ms", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Frame: $frameIndex / ${_frames!.length - 1}"),
                ],
              ),
              Slider(
                value: _currentSliderValue,
                onChanged: (value) {
                  setState(() {
                    _currentSliderValue = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BaselinePainter extends CustomPainter {
  final Map<String, dynamic> landmarks;

  BaselinePainter({required this.landmarks});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // SCALING CONFIGURATION
    final double scale = 300.0;
    final double offsetX = size.width / 2;
    final double offsetY = size.height / 2;

    Offset? getPoint(String key) {
      if (!landmarks.containsKey(key)) return null;
      final lm = landmarks[key];

      double x = (lm['x'] * scale) + offsetX;
      double y = (lm['y'] * scale) + offsetY;

      return Offset(x, y);
    }

    // --- DRAWING LOGIC ---

    final connections = [
      ['leftShoulder', 'leftElbow'], ['leftElbow', 'leftWrist'],    // Left Arm
      ['rightShoulder', 'rightElbow'], ['rightElbow', 'rightWrist'],// Right Arm
      ['leftShoulder', 'rightShoulder'],                            // Shoulders
      ['leftShoulder', 'leftHip'], ['rightShoulder', 'rightHip'],   // Torso
      ['leftHip', 'rightHip'],                                      // Hips
    ];

    for (var pair in connections) {
      final p1 = getPoint(pair[0]);
      final p2 = getPoint(pair[1]);

      // Only draw the line if both joints exist in the map
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }

    // List of active joints we want to render the red dots for
    final jointsToDraw = [
      'leftShoulder', 'rightShoulder',
      'leftElbow', 'rightElbow',
      'leftWrist', 'rightWrist',
      'leftHip', 'rightHip'
    ];

    for (String joint in jointsToDraw) {
      final p = getPoint(joint);
      if (p != null) {
        canvas.drawCircle(p, 6, jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}