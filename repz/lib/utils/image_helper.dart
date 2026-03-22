import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';


Future<ui.Image> convertYUVToImage(CameraImage cameraImage) async {
  final int width = cameraImage.width;
  final int height = cameraImage.height;

  // Safety check - log what we actually have
  print('Planes: ${cameraImage.planes.length}');
  print('Format: ${cameraImage.format.raw}');

  if (cameraImage.planes.length == 1) {
    // Device is giving us a single plane — likely NV21 packed format
    // Just use the Y plane only (grayscale) or handle as NV21
    final yBytes = cameraImage.planes[0].bytes;
    final rgba = Uint8List(width * height * 4);
    for (int i = 0; i < width * height; i++) {
      final y = yBytes[i];
      rgba[i * 4] = y;
      rgba[i * 4 + 1] = y;
      rgba[i * 4 + 2] = y;
      rgba[i * 4 + 3] = 255;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888,
            (image) => completer.complete(image));
    return completer.future;
  }

  // Original 3-plane path
  final yPlane = cameraImage.planes[0];
  final uPlane = cameraImage.planes[1];
  final vPlane = cameraImage.planes[2];

  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;

  final int uvRowStride = uPlane.bytesPerRow;
  final int uvPixelStride = uPlane.bytesPerPixel!;

  final rgba = Uint8List(width * height * 4);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * yPlane.bytesPerRow + x;
      final int uvIndex =
          (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

      final int yVal = yBytes[yIndex];
      final int uVal = uBytes[uvIndex];
      final int vVal = vBytes[uvIndex];

      // YUV to RGB conversion
      int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
      int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
          .round()
          .clamp(0, 255);
      int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

      final int index = (y * width + x) * 4;
      rgba[index] = r;
      rgba[index + 1] = g;
      rgba[index + 2] = b;
      rgba[index + 3] = 255;
    }
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888,
          (image) => completer.complete(image));
  return completer.future;
}

Future<Uint8List?> cropToBox(
    ui.Image fullImage,
    Rect boundingBox,
    ) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final srcRect = Rect.fromLTRB(
    boundingBox.left.clamp(0, fullImage.width.toDouble()),
    boundingBox.top.clamp(0, fullImage.height.toDouble()),
    boundingBox.right.clamp(0, fullImage.width.toDouble()),
    boundingBox.bottom.clamp(0, fullImage.height.toDouble()),
  );

  final cropW = srcRect.width;
  final cropH = srcRect.height;

  final dstRect = Rect.fromLTWH(0, 0, cropW, cropH);

  canvas.drawImageRect(fullImage, srcRect, dstRect, Paint());

  final picture = recorder.endRecording();
  final cropped = await picture.toImage(cropW.toInt(), cropH.toInt());

  final byteData =
  await cropped.toByteData(format: ui.ImageByteFormat.rawRgba);
  return byteData?.buffer.asUint8List();
}
