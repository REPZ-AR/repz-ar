import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img_lib;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'detector_view.dart';
import 'equipment_overlay.dart';
import 'painters/object_detector_painter.dart';
import 'utils.dart';

const String _classifierLogTag = '[ObjectDetectorClassifier]';
const int _classifierInputSize = 256;
const int _classifierAnchors = 12276;
const int _classifierNumClasses = 14;
const String _workerTypeInit = 'init';
const String _workerTypeReady = 'ready';
const String _workerTypeClassify = 'classify';
const String _workerTypeResult = 'result';
const String _workerTypeError = 'error';
const String _workerTypeShutdown = 'shutdown';

Map<String, Object?>? _classifyWithInterpreter(
  Interpreter interpreter,
  List<String> labels,
  Map<String, Object?> request,
) {
  final width = request['width'] as int;
  final height = request['height'] as int;
  final boxLeft = request['boxLeft'] as double;
  final boxTop = request['boxTop'] as double;
  final boxWidth = request['boxWidth'] as double;
  final boxHeight = request['boxHeight'] as double;
  final nv21Bytes =
      (request['nv21'] as TransferableTypedData).materialize().asUint8List();
  try {
    final rgbImage = img_lib.Image(width: width, height: height);

    // Device-specific format assumption retained from current pipeline.
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = width * height + (y ~/ 2) * width + (x & ~1);

        final yVal = (yIndex < nv21Bytes.length ? nv21Bytes[yIndex] : 0) & 0xFF;
        final vVal =
            (uvIndex < nv21Bytes.length ? nv21Bytes[uvIndex] : 128) & 0xFF;
        final uVal =
            (uvIndex + 1 < nv21Bytes.length ? nv21Bytes[uvIndex + 1] : 128) &
            0xFF;

        final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
        final g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
            .round()
            .clamp(0, 255);
        final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);
        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }

    final left = boxLeft.clamp(0, width.toDouble() - 1).toInt();
    final top = boxTop.clamp(0, height.toDouble() - 1).toInt();
    final cropWidth = boxWidth.clamp(1, width.toDouble() - left).toInt();
    final cropHeight = boxHeight.clamp(1, height.toDouble() - top).toInt();
    final cropped = img_lib.copyCrop(
      rgbImage,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );

    final resized = img_lib.copyResize(
      cropped,
      width: _classifierInputSize,
      height: _classifierInputSize,
    );

    final inputBuffer = List.generate(
      _classifierInputSize,
      (y) => List.generate(_classifierInputSize, (x) {
        final pixel = resized.getPixel(x, y);
        return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
      }),
    );
    final input = [inputBuffer];

    final outputBoxes = List.generate(
      1,
      (_) => List.generate(_classifierAnchors, (_) => List.filled(4, 0.0)),
    );
    final outputScores = List.generate(
      1,
      (_) => List.generate(
        _classifierAnchors,
        (_) => List.filled(_classifierNumClasses, 0.0),
      ),
    );

    interpreter.runForMultipleInputs(
      [input],
      {0: outputBoxes, 1: outputScores},
    );

    var bestScore = 0.0;
    var bestClass = -1;
    for (int anchor = 0; anchor < _classifierAnchors; anchor++) {
      for (int cls = 0; cls < _classifierNumClasses; cls++) {
        final score = outputScores[0][anchor][cls];
        if (score > bestScore) {
          bestScore = score;
          bestClass = cls;
        }
      }
    }

    if (bestClass == -1 || bestScore < 0.5) {
      return null;
    }

    final label =
        bestClass < labels.length ? labels[bestClass] : 'class_$bestClass';
    return {'label': label, 'confidence': bestScore};
  } catch (e) {
    print('$_classifierLogTag isolate classification error: $e');
    return null;
  }
}

void _classifierWorkerMain(SendPort mainSendPort) {
  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  Interpreter? interpreter;
  List<String> labels = const <String>[];

  commandPort.listen((dynamic rawMessage) {
    if (rawMessage is! Map) return;
    final message = Map<String, Object?>.from(rawMessage);
    final type = message['type'];

    try {
      if (type == _workerTypeInit) {
        final modelPath = message['modelPath'] as String;
        labels = List<String>.from(message['labels'] as List<dynamic>);
        interpreter?.close();
        interpreter = Interpreter.fromFile(File(modelPath));
        mainSendPort.send({'type': _workerTypeReady});
        return;
      }

      if (type == _workerTypeClassify) {
        final requestId = message['requestId'] as int;
        if (interpreter == null) {
          mainSendPort.send({
            'type': _workerTypeError,
            'requestId': requestId,
            'error': 'Interpreter not initialized',
          });
          return;
        }

        final classification = _classifyWithInterpreter(
          interpreter!,
          labels,
          message,
        );
        mainSendPort.send({
          'type': _workerTypeResult,
          'requestId': requestId,
          'label': classification?['label'],
          'confidence': classification?['confidence'],
        });
        return;
      }

      if (type == _workerTypeShutdown) {
        interpreter?.close();
        commandPort.close();
      }
    } catch (e) {
      mainSendPort.send({
        'type': _workerTypeError,
        'requestId': message['requestId'],
        'error': e.toString(),
      });
    }
  });
}

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
  CameraImage? _lastCameraImage;
  DateTime? _lastClassificationAt;
  bool _isClassificationInFlight = false;
  int _classificationGeneration = 0;
  Isolate? _classifierWorkerIsolate;
  ReceivePort? _classifierWorkerReceivePort;
  StreamSubscription<dynamic>? _classifierWorkerSubscription;
  SendPort? _classifierWorkerSendPort;
  Completer<void>? _classifierWorkerReady;
  int _nextClassifierRequestId = 0;
  final Map<int, int> _pendingClassificationGenerations = <int, int>{};
  final int NUM_CLASSES = 14;

  final _options = {'default': ''};

  @override
  void dispose() {
    print(
      '$_logTag dispose called: releasing detector and disabling processing',
    );
    _canProcess = false;
    _classificationGeneration++;
    _objectDetector?.close();
    unawaited(_stopClassifierWorker());
    super.dispose();
  }

  List<String> _labels = [];
  String? _classifierModelPath;

  Future<void> _initClassifier() async {
    print('$_logTag _initClassifier started');
    _classifierModelPath = await getAssetPath(
      'assets/ml/gym_equipment_model.tflite',
    );
    print('$_logTag classifier model copied to $_classifierModelPath');
    // Load labels from a text file
    final labelData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelData.split('\n').where((l) => l.isNotEmpty).toList();
    print('$_logTag loaded ${_labels.length} labels');
    await _startClassifierWorker();
  }

  Future<void> _startClassifierWorker() async {
    if (_classifierModelPath == null || _labels.isEmpty) return;
    if (_classifierWorkerSendPort != null) return;

    final receivePort = ReceivePort();
    _classifierWorkerReceivePort = receivePort;
    _classifierWorkerReady = Completer<void>();
    _classifierWorkerSubscription = receivePort.listen((dynamic message) {
      if (message is SendPort) {
        _classifierWorkerSendPort = message;
        message.send({
          'type': _workerTypeInit,
          'modelPath': _classifierModelPath!,
          'labels': List<String>.from(_labels),
        });
        return;
      }
      if (message is! Map) return;
      final workerMessage = Map<String, Object?>.from(message);
      final type = workerMessage['type'];
      if (type == _workerTypeReady) {
        if (!(_classifierWorkerReady?.isCompleted ?? true)) {
          _classifierWorkerReady?.complete();
        }
        return;
      }
      unawaited(_handleWorkerResponse(workerMessage));
    });

    _classifierWorkerIsolate = await Isolate.spawn(
      _classifierWorkerMain,
      receivePort.sendPort,
    );

    try {
      await _classifierWorkerReady!.future.timeout(const Duration(seconds: 5));
      print('$_logTag classifier worker ready');
    } catch (e) {
      print('$_logTag classifier worker failed to start: $e');
      await _stopClassifierWorker();
    }
  }

  Future<void> _stopClassifierWorker() async {
    _classifierWorkerSendPort?.send({'type': _workerTypeShutdown});
    _classifierWorkerSendPort = null;
    _classifierWorkerReady = null;
    _pendingClassificationGenerations.clear();
    _isClassificationInFlight = false;

    await _classifierWorkerSubscription?.cancel();
    _classifierWorkerSubscription = null;
    _classifierWorkerReceivePort?.close();
    _classifierWorkerReceivePort = null;
    _classifierWorkerIsolate?.kill(priority: Isolate.immediate);
    _classifierWorkerIsolate = null;
  }

  Future<void> _handleWorkerResponse(Map<String, Object?> message) async {
    final type = message['type'];
    if (type == _workerTypeResult) {
      final requestId = message['requestId'] as int;
      final generation = _pendingClassificationGenerations.remove(requestId);
      _isClassificationInFlight = false;
      if (generation == null) return;
      if (!mounted || generation != _classificationGeneration) return;

      final label = message['label'] as String?;
      final confidence = (message['confidence'] as num?)?.toDouble();
      if (label == null || label.trim().isEmpty) return;

      final normalizedLabel = label.trim().toLowerCase();
      if (normalizedLabel == 'background') {
        print('$_logTag ignoring background classification');
        return;
      }

      print('$_logTag showing overlay for $label (confidence=$confidence)');
      await _showEquipmentOverlay(label, confidence: confidence);
      return;
    }

    if (type == _workerTypeError) {
      final requestId = message['requestId'] as int?;
      if (requestId != null) {
        _pendingClassificationGenerations.remove(requestId);
      }
      _isClassificationInFlight = false;
      print('$_logTag classifier worker error: ${message['error']}');
    }
  }

  void _launchClassificationFireAndForget(
    DetectedObject object,
    CameraImage cameraImage,
  ) {
    if (_isClassificationInFlight) {
      print('$_logTag skipped classification: job already in flight');
      return;
    }
    if (!_shouldRunClassification()) {
      print('$_logTag skipped classification: waiting for interval');
      return;
    }

    _isClassificationInFlight = true;
    _lastClassificationAt = DateTime.now();
    final generation = _classificationGeneration;
    final workerPort = _classifierWorkerSendPort;
    if (workerPort == null) {
      print('$_logTag skipped classification: worker not ready');
      _isClassificationInFlight = false;
      return;
    }

    final requestId = ++_nextClassifierRequestId;
    _pendingClassificationGenerations[requestId] = generation;
    final box = object.boundingBox;

    print('$_logTag dispatching background classification');
    workerPort.send({
      'type': _workerTypeClassify,
      'requestId': requestId,
      'width': cameraImage.width,
      'height': cameraImage.height,
      'boxLeft': box.left,
      'boxTop': box.top,
      'boxWidth': box.width,
      'boxHeight': box.height,
      // Copy bytes before isolate hop to avoid reusing camera buffers.
      'nv21': TransferableTypedData.fromList([
        Uint8List.fromList(cameraImage.planes[0].bytes),
      ]),
    });
  }

  Future<void> _showEquipmentOverlay(
    String equipmentName, {
    double? confidence,
  }) async {
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
        builder:
            (_) => EquipmentOverlay(
              equipmentName: equipmentName,
              confidence: confidence,
            ),
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
    final shouldRun =
        DateTime.now().difference(_lastClassificationAt!) >=
        _classificationInterval;
    print('$_logTag _shouldRunClassification result: $shouldRun');
    return shouldRun;
  }

  @override
  Widget build(BuildContext context) {
    print('$_logTag build called');
    return Scaffold(
      body: Stack(
        children: [
          DetectorView(
            title: 'Object Detector',
            customPaint: _customPaint,
            text: _text,
            onImage: _processImage,
            onCameraImage: (cameraImage) {
              _lastCameraImage = cameraImage;
              print(
                '$_logTag received camera frame ${cameraImage.width}x${cameraImage.height}',
              );
            },
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged:
                (value) => _cameraLensDirection = value,
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
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() => DropdownButton<int>(
    value: _option,
    icon: const Icon(Icons.arrow_downward),
    elevation: 16,
    style: const TextStyle(color: Colors.blue),
    underline: Container(height: 2, color: Colors.blue),
    onChanged: (int? option) {
      print('$_logTag dropdown changed to $option');
      if (option != null) {
        setState(() {
          _option = option;
          _initializeDetector();
        });
      }
    },
    items:
        List<int>.generate(
          _options.length,
          (i) => i,
        ).map<DropdownMenuItem<int>>((option) {
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

  void _initializeDetector() async {
    print(
      '$_logTag _initializeDetector started with option=$_option mode=$_mode',
    );
    _objectDetector?.close();
    _objectDetector = null;
    _lastClassificationAt = null;
    _lastCameraImage = null;
    _isClassificationInFlight = false;
    _classificationGeneration++;
    await _stopClassifierWorker();
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
      await _initClassifier();
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
        objects.isNotEmpty
            ? <DetectedObject>[objects.first]
            : <DetectedObject>[];
    print('$_logTag visibleObjects count: ${visibleObjects.length}');
    if (visibleObjects.isNotEmpty && _lastCameraImage != null) {
      _launchClassificationFireAndForget(
        visibleObjects.first,
        _lastCameraImage!,
      );
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
