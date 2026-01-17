import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils.dart';

class PoseLogger {
  File? _logFile;

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/workout_log_${DateTime.now().toIso8601String()}.txt';
    _logFile = File(path);
  }

  Future<void> logPoses(List<Pose> poses) async {
    if (_logFile == null || poses.isEmpty) return;

    // Convert list of poses to a single line of JSON
    final List<Map<String, dynamic>> data = poses.map((p) => poseToMap(p)).toList();
    final String entry = jsonEncode(data) + "\n";

    // Use append mode to keep adding data
    await _logFile!.writeAsString(entry, mode: FileMode.append);
  }
}