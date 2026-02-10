import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaselineFrame {
  final int timestamp;
  final List<Map<String, dynamic>> landmarks;

  BaselineFrame({required this.timestamp, required this.landmarks});

  factory BaselineFrame.fromJson(Map<String, dynamic> json) {
    return BaselineFrame(
      timestamp: json['timestamp_ms'],
      landmarks: List<Map<String, dynamic>>.from(json['landmarks']),
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
  final List<Map<String, dynamic>> landmarks;

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

    Offset getPoint(int index) {
      if (index >= landmarks.length) return Offset.zero;
      final lm = landmarks[index];

      double x = (lm['x'] * scale) + offsetX;
      double y = (lm['y'] * scale) + offsetY;

      return Offset(x, y);
    }

    // --- DRAWING LOGIC ---

    final connections = [
      [11, 13], [13, 15], // Left Arm (Shoulder->Elbow->Wrist)
      [12, 14], [14, 16], // Right Arm
      [11, 12],           // Shoulders
      [11, 23], [12, 24], // Torso (Shoulder->Hip)
      [23, 24],           // Hips
    ];

    for (var pair in connections) {
      if (landmarks.length > pair[1]) {
        canvas.drawLine(getPoint(pair[0]), getPoint(pair[1]), paint);
      }
    }

    for (int i = 11; i <= 16; i++) {
      if (landmarks.length > i) {
        canvas.drawCircle(getPoint(i), 6, jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}