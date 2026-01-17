import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

Future<String> getAssetPath(String asset) async {
  final path = await getLocalPath(asset);
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}

Map<String, dynamic> poseToMap(Pose pose) {
  Map<String, dynamic> landmarks = {};

  pose.landmarks.forEach((type, landmark) {
    landmarks[type.name] = {
      'x': landmark.x,
      'y': landmark.y,
      'z': landmark.z,
      'likelihood': landmark.likelihood,
    };
  });

  return {
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'landmarks': landmarks,
  };
}
