import 'dart:io';

import 'package:image/image.dart' as img_lib;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:ui' as ui;

import '../utils/image_helper.dart';
import 'detector_view.dart';
import 'equipment_overlay.dart';
import 'painters/object_detector_painter.dart';
import 'utils.dart';

class ObjectDetectorView extends StatefulWidget {
  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  static const String _logTag = '[ObjectDetectorView]';

  ObjectDetector? _objectDetector;
  DetectionMode _mode = DetectionMode.stream;
  bool _canProcess = false;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  int _option = 0;
  bool _isOverlayVisible = false;
  String? _lastOverlayEquipment;
  DateTime? _lastOverlayAt;
  static const Duration _overlayCooldown = Duration(seconds: 2);
  static const Duration _classificationInterval = Duration(seconds: 2);
  ImageLabeler? _equipmentClassifier;
  CameraImage? _lastCameraImage;
  DateTime? _lastClassificationAt;
  final int NUM_CLASSES = 14;

  final _options = {
    'default': '',
    // 'object_custom': 'object_labeler.tflite',
    // 'fruits': 'object_labeler_fruits.tflite',
    // 'flowers': 'object_labeler_flowers.tflite',
    // 'birds': 'lite-model_aiy_vision_classifier_birds_V1_3.tflite',
    // // https://tfhub.dev/google/lite-model/aiy/vision/classifier/birds_V1/3
    //
    // 'food': 'lite-model_aiy_vision_classifier_food_V1_1.tflite',
    // // https://tfhub.dev/google/lite-model/aiy/vision/classifier/food_V1/1
    //
    // 'plants': 'lite-model_aiy_vision_classifier_plants_V1_3.tflite',
    // // https://tfhub.dev/google/lite-model/aiy/vision/classifier/plants_V1/3
    //
    // 'mushrooms': 'lite-model_models_mushroom-identification_v1_1.tflite',
    // // https://tfhub.dev/bohemian-visual-recognition-alliance/lite-model/models/mushroom-identification_v1/1
    //
    // 'landmarks':
    //     'lite-model_on_device_vision_classifier_landmarks_classifier_north_america_V1_1.tflite',
    // // https://tfhub.dev/google/lite-model/on_device_vision/classifier/landmarks_classifier_north_america_V1/1
  };

  @override
  void dispose() {
    print('$_logTag dispose called: releasing detector and disabling processing');
    _canProcess = false;
    _objectDetector?.close();
    super.dispose();
  }

  String? _extractEquipmentName(List<DetectedObject> objects) {
    print('$_logTag _extractEquipmentName called with ${objects.length} objects');
    if (objects.isEmpty) return null;
    final labels = objects.first.labels;
    print('$_logTag first object has ${labels.length} labels');
    if (labels.isEmpty) return null;
    final name = labels.first.text.trim();
    print('$_logTag extracted equipment label: "$name"');
    return name.isEmpty ? null : name;
  }

  // Future<void> _initClassifier() async {
  //   final modelPath = await _getModelPath('./assets/ml/gym_equipment_model.tflite');
  //   final options = LocalLabelerOptions(
  //     modelPath: modelPath,
  //     confidenceThreshold: 0.5,
  //   );
  //   _equipmentClassifier = ImageLabeler(options: options);
  // }

  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> _initClassifier() async {
    print('$_logTag _initClassifier started');
    _interpreter = await Interpreter.fromAsset('assets/ml/gym_equipment_model.tflite');
    print('$_logTag interpreter loaded from assets/ml/gym_equipment_model.tflite');
    // Load labels from a text file
    final labelData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelData.split('\n').where((l) => l.isNotEmpty).toList();
    print('$_logTag loaded ${_labels.length} labels');
    _printInterpreterDetails();
  }

  Future<String?> _classifyWithTFLite(File imageFile) async {
    if (_interpreter == null) return null;

    const int inputSize = 256;

    // Step 1: Decode and resize to exactly 256x256
    final rawBytes = await imageFile.readAsBytes();
    final rawImage = img_lib.decodeImage(rawBytes);
    if (rawImage == null) {
      print('$_logTag failed to decode image');
      return null;
    }

    final resized = img_lib.copyResize(
      rawImage,
      width: inputSize,
      height: inputSize,
    );
    print('$_logTag decoded image ${rawImage.width}x${rawImage.height}, resized to ${resized.width}x${resized.height}');

    // Step 2: Build input tensor [1, 256, 256, 3]
    final inputBuffer = List.generate(
        inputSize, (y) => List.generate(
        inputSize, (x) {
      final pixel = resized.getPixel(x, y);
      return [
        pixel.r / 255.0,
        pixel.g / 255.0,
        pixel.b / 255.0,
      ];
    }
    )
    );
    final input = [inputBuffer]; // wrap in batch dimension

    // Step 3: Prepare outputs
    final outputBoxes  = List.generate(1, (_) =>
        List.generate(12276, (_) => List.filled(4, 0.0)));
    final outputScores = List.generate(1, (_) =>
        List.generate(12276, (_) => List.filled(14, 0.0)));

    final outputs = {0: outputBoxes, 1: outputScores};

    // Step 4: Run inference
    _interpreter!.runForMultipleInputs([input], outputs);

    // Step 5: Find best scoring class across all anchors
    double bestScore = 0.0;
    int bestClass = -1;

    for (int anchor = 0; anchor < 12276; anchor++) {
      for (int cls = 0; cls < 14; cls++) {
        final score = outputScores[0][anchor][cls];
        if (score > bestScore) {
          bestScore = score;
          bestClass = cls;
        }
      }
    }

    if (bestClass == -1 || bestScore < 0.5) {
      print('$_logTag no confident detection (best: $bestScore)');
      return null;
    }

    final label = bestClass < _labels.length ? _labels[bestClass] : 'class_$bestClass';
    print('$_logTag result: $label ($bestScore)');
    return label;
  }

  Future<String> _getModelPath(String assetPath) async {
    print('$_logTag _getModelPath called for $assetPath');
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(p.dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      print('$_logTag model not cached; copying asset to $path');
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ));
    } else {
      print('$_logTag using cached model at $path');
    }
    print('$_logTag _getModelPath returning ${file.path}');
    return file.path;
  }

  Future<String?> _classifyDetectedObject(
      DetectedObject object,
      CameraImage cameraImage,
      ) async {
    print('$_logTag _classifyDetectedObject called with bounding box ${object.boundingBox}');
    if (_interpreter == null) return null;

    try {
      final width = cameraImage.width;
      final height = cameraImage.height;
      final bytes = cameraImage.planes[0].bytes;
      print('$_logTag camera image size: ${width}x$height, bytes: ${bytes.length}');

      // Format 17 = YUV_420_888 packed as NV21 on this device
      // Manually convert NV21 to RGB using image package
      final rgbImage = img_lib.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * width + x;
          // NV21: UV data starts after Y plane
          final int uvIndex = width * height + (y ~/ 2) * width + (x & ~1);

          final int yVal = bytes[yIndex] & 0xFF;
          final int vVal = (uvIndex < bytes.length ? bytes[uvIndex] : 128) & 0xFF;
          final int uVal = (uvIndex + 1 < bytes.length ? bytes[uvIndex + 1] : 128) & 0xFF;

          int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
          int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128)).round().clamp(0, 255);
          int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

          rgbImage.setPixelRgb(x, y, r, g, b);
        }
      }
      print('$_logTag converted camera frame from NV21 to RGB');

      // Crop to bounding box
      final box = object.boundingBox;
      final left  = box.left.clamp(0, width.toDouble() - 1).toInt();
      final top   = box.top.clamp(0, height.toDouble() - 1).toInt();
      final cropW = box.width.clamp(1, width.toDouble() - left).toInt();
      final cropH = box.height.clamp(1, height.toDouble() - top).toInt();
      print('$_logTag crop bounds left=$left top=$top width=$cropW height=$cropH');

      final cropped = img_lib.copyCrop(
        rgbImage,
        x: left,
        y: top,
        width: cropW,
        height: cropH,
      );

      // Save as JPEG to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img_lib.encodeJpg(cropped));
      print('$_logTag wrote cropped image to ${tempFile.path}');

      // Pass to ML Kit
      final inputImage = InputImage.fromFilePath(tempFile.path);
      print('$_logTag created InputImage from ${tempFile.path}: $inputImage');
      print('$_logTag classifying cropped image with TF Lite');
      final labels = await _classifyWithTFLite(tempFile);
      print('$_logTag TF Lite classification result: $labels');

      await tempFile.delete();
      print('$_logTag deleted temp file ${tempFile.path}');

      // if (labels?.isEmpty) return null;
      // labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      // print('Classified as: ${labels.first.label} (${labels.first.confidence})');
      // return labels.first.label;

      return labels;

    } catch (e) {
      print('$_logTag classification error: $e');
      return null;
    }
  }

  Future<void> _showEquipmentOverlay(String equipmentName) async {
    print('$_logTag _showEquipmentOverlay called for "$equipmentName"');
    if (!mounted || _isOverlayVisible) return;

    final normalizedName = equipmentName.trim().toLowerCase();
    final now = DateTime.now();
    if (_lastOverlayEquipment == normalizedName &&
        _lastOverlayAt != null &&
        now.difference(_lastOverlayAt!) < _overlayCooldown) {
      print('$_logTag overlay skipped due to cooldown for "$normalizedName"');
      return;
    }

    _isOverlayVisible = true;
    _canProcess = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => EquipmentOverlay(equipmentName: equipmentName),
      );
      print('$_logTag overlay dismissed for "$equipmentName"');
      _lastOverlayEquipment = normalizedName;
      _lastOverlayAt = DateTime.now();
    } finally {
      _isOverlayVisible = false;
      if (mounted) {
        _canProcess = true;
        print('$_logTag processing re-enabled after overlay');
      }
    }
  }

  bool _shouldRunClassification() {
    print('$_logTag _shouldRunClassification called');
    if (_lastClassificationAt == null) return true;
    final shouldRun = DateTime.now().difference(_lastClassificationAt!) >=
        _classificationInterval;
    print('$_logTag _shouldRunClassification result: $shouldRun');
    return shouldRun;
  }

  @override
  Widget build(BuildContext context) {
    print('$_logTag build called');
    return Scaffold(
      body: Stack(children: [
        DetectorView(
          title: 'Object Detector',
          customPaint: _customPaint,
          text: _text,
          onImage: _processImage,
          onCameraImage: (cameraImage) {
            _lastCameraImage = cameraImage;
            print('$_logTag received camera frame ${cameraImage.width}x${cameraImage.height}');
          },
          initialCameraLensDirection: _cameraLensDirection,
          onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
          onCameraFeedReady: _initializeDetector,
          initialDetectionMode: DetectorViewMode.values[_mode.index],
          onDetectorViewModeChanged: _onScreenModeChanged,
        ),
        Positioned(
            top: 30,
            left: 100,
            right: 100,
            child: Row(
              children: [
                Spacer(),
                Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildDropdown(),
                    )),
                Spacer(),
              ],
            )),
      ]),
    );
  }

  Widget _buildDropdown() => DropdownButton<int>(
        value: _option,
        icon: const Icon(Icons.arrow_downward),
        elevation: 16,
        style: const TextStyle(color: Colors.blue),
        underline: Container(
          height: 2,
          color: Colors.blue,
        ),
        onChanged: (int? option) {
          print('$_logTag dropdown changed to $option');
          if (option != null) {
            setState(() {
              _option = option;
              _initializeDetector();
            });
          }
        },
        items: List<int>.generate(_options.length, (i) => i)
            .map<DropdownMenuItem<int>>((option) {
          return DropdownMenuItem<int>(
            value: option,
            child: Text(_options.keys.toList()[option]),
          );
        }).toList(),
      );

  void _onScreenModeChanged(DetectorViewMode mode) {
    print('$_logTag _onScreenModeChanged called with $mode');
    switch (mode) {
      case DetectorViewMode.gallery:
        _mode = DetectionMode.single;
        print('$_logTag switched to gallery/single mode');
        _initializeDetector();
        return;

      case DetectorViewMode.liveFeed:
        _mode = DetectionMode.stream;
        print('$_logTag switched to liveFeed/stream mode');
        _initializeDetector();
        return;
    }
  }

  void _printInterpreterDetails() {
    if (_interpreter == null) return;

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensors = [
      _interpreter!.getOutputTensor(0),
      _interpreter!.getOutputTensor(1),
    ];

    print('Input shape: ${inputTensor.shape}');
    print('Input type: ${inputTensor.type}');
    print('Output 0 shape: ${outputTensors[0].shape}');
    print('Output 1 shape: ${outputTensors[1].shape}');
  }

  void _initializeDetector() async {
    print('$_logTag _initializeDetector started with option=$_option mode=$_mode');
    _objectDetector?.close();
    _objectDetector = null;
    _lastClassificationAt = null;
    _lastCameraImage = null;
    print('Set detector in mode: $_mode');

    if (_option == 0) {
      // use the default model
      print('$_logTag using the default object detector model');
      final options = ObjectDetectorOptions(
        mode: _mode,
        classifyObjects: true,
        multipleObjects: false,
      );
      _objectDetector = ObjectDetector(options: options);
      print('$_logTag default object detector initialized');
      _initClassifier();
    } else if (_option > 0 && _option <= _options.length) {
      // use a custom model
      // make sure to add tflite model to assets/ml
      final option = _options[_options.keys.toList()[_option]] ?? '';
      final modelPath = await getAssetPath('assets/ml/$option');
      print('$_logTag using custom model path: $modelPath');
      final options = LocalObjectDetectorOptions(
        mode: _mode,
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: false,
      );
      _objectDetector = ObjectDetector(options: options);
      print('$_logTag custom object detector initialized');
    }

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseObjectDetectorModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options = FirebaseObjectDetectorOptions(
    //   mode: _mode,
    //   modelName: modelName,
    //   classifyObjects: true,
    //   multipleObjects: true,
    // );
    // _objectDetector = ObjectDetector(options: options);

    _canProcess = true;
    print('$_logTag detector ready; _canProcess=$_canProcess');
  }

  Future<void> _processImage(InputImage inputImage) async {
    print('$_logTag _processImage called');
    if (_objectDetector == null) return;
    if (!_canProcess) return;
    if (_isBusy) return;
    print('$_logTag processing frame with mode=$_mode option=$_option');
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final objects = await _objectDetector!.processImage(inputImage);
    print('$_logTag detector found ${objects.length} objects');
    final visibleObjects =
        objects.isNotEmpty ? <DetectedObject>[objects.first] : <DetectedObject>[];
    print('$_logTag visibleObjects count: ${visibleObjects.length}');
    String? equipmentName;
    if (visibleObjects.isNotEmpty &&
        _lastCameraImage != null &&
        true) {
      _lastClassificationAt = DateTime.now();
      print('$_logTag classifying first visible object');
      equipmentName = await _classifyDetectedObject(
        visibleObjects.first,
        _lastCameraImage!,
      );
      print('$_logTag equipmentName from classifier: $equipmentName');
    }

    if (equipmentName != null) {
      print('$_logTag showing overlay for $equipmentName');
      await _showEquipmentOverlay(equipmentName);
    }
    // print('Objects found: ${objects.length}\n\n');
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = ObjectDetectorPainter(
        visibleObjects,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
      print('$_logTag custom painter updated for live metadata');
    } else {
      String text = 'Objects found: ${visibleObjects.length}\n\n';
      for (final object in visibleObjects) {
        text +=
            'Object:  trackingId: ${object.trackingId} - ${object.labels.map((e) => e.text)}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
      print('$_logTag metadata missing; switched to text output');
    }
    _isBusy = false;
    print('$_logTag frame processing complete; _isBusy=$_isBusy');
    if (mounted) {
      setState(() {});
      print('$_logTag state updated after frame processing');
    }
  }
}
