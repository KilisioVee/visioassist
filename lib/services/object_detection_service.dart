import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';

/// Service responsible for loading TFLite models and running object detection inference.
///
/// This service encapsulates all TensorFlow Lite interactions and provides
/// a clean API for the rest of the application.
class ObjectDetectionService {
  static final ObjectDetectionService _instance =
      ObjectDetectionService._internal();

  factory ObjectDetectionService() {
    return _instance;
  }

  ObjectDetectionService._internal();

  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isModelLoaded = false;

  /// Expected input image size for the model (e.g., 300x300 for SSD MobileNet)
  static const int inputSize = 300;

  /// Number of results per detection (varies by model)
  static const int numResults = 10;

  /// Number of classes the model can detect
  static const int numClasses = 90; // COCO dataset has ~80 classes

  /// Check if the model is loaded and ready for inference
  bool get isModelLoaded => _isModelLoaded;

  /// Get loaded labels
  List<String> get labels => _labels;

  /// Load the TFLite model and labels from assets.
  ///
  /// Must be called before running any detections.
  /// Throws an exception if model or labels file cannot be found.
  Future<void> loadModel() async {
    try {
      if (_isModelLoaded) {
        return; // Model already loaded
      }

      // Load the TFLite model
      // TODO: Replace 'ssd_mobilenet.tflite' with your actual model filename.
      _interpreter = await Interpreter.fromAsset('assets/models/ssd_mobilenet.tflite');

      // Load the labels file
      // TODO: Replace 'labels.txt' with your actual labels filename.
      final labelsData =
          await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n');
      _labels.removeWhere((label) => label.isEmpty);

      _isModelLoaded = true;
      print('ObjectDetectionService: Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  /// Run object detection on a static image file.
  ///
  /// Returns a list of [Detection] objects found in the image.
  /// Returns empty list if no objects are detected.
  Future<List<Detection>> detectOnImage(
    File imageFile, {
    double confidenceThreshold = 0.5,
  }) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    // Read the image file
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Preprocess and run inference
    final detections = await _runInference(
      image,
      confidenceThreshold: confidenceThreshold,
    );

    return detections;
  }

  /// Run object detection on a camera frame.
  ///
  /// Converts the CameraImage to a format suitable for inference
  /// and returns detected objects.
  Future<List<Detection>> detectOnFrame(
    CameraImage frame, {
    double confidenceThreshold = 0.5,
  }) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    // Convert CameraImage to img.Image
    img.Image? image = _cameraImageToImage(frame);

    if (image == null) {
      return [];
    }

    // Run inference
    final detections = await _runInference(
      image,
      confidenceThreshold: confidenceThreshold,
    );

    return detections;
  }

  /// Internal method to preprocess image and run inference.
  ///
  /// Handles:
  /// - Resizing the image to model input size
  /// - Normalizing pixel values
  /// - Running the interpreter
  /// - Parsing and filtering results
  Future<List<Detection>> _runInference(
    img.Image image, {
    double confidenceThreshold = 0.5,
  }) async {
    // Resize image to model input size
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Convert to input tensor (4D: [1, height, width, 3])
    // Normalize pixel values to [0, 1] range
    final input = _imageToByteListFloat32(resized, inputSize, inputSize, 127.5, 127.5);

    try {
      // Prepare output buffers
      // SSD MobileNet typically outputs:
      // - detectionBoxes: [1, numResults, 4] (normalized coordinates)
      // - detectionClasses: [1, numResults] (class indices)
      // - detectionScores: [1, numResults] (confidence scores)
      // - numDetections: [1] (number of detections)
      final output = <List<List<double>>>[
        List.filled(numResults, List.filled(4, 0.0))
      ];
      final outputClasses = <List<double>>[List.filled(numResults, 0.0)];
      final outputScores = <List<double>>[List.filled(numResults, 0.0)];
      final numDetections = <List<double>>[List.filled(1, 0.0)];

      // Run inference
      _interpreter.runForMultipleInputs([input], {
        0: output,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      });

      // Parse results
      final detections = <Detection>[];
      final numDets = (numDetections[0][0] as num).toInt();

      for (int i = 0; i < numDets && i < numResults; i++) {
        final scoreValue = outputScores[0][i];
        final confidence = (scoreValue as num).toDouble();

        if (confidence >= confidenceThreshold) {
          final classIndexValue = outputClasses[0][i];
          final classIndex = (classIndexValue as num).toInt();
          final label =
              classIndex >= 0 && classIndex < _labels.length
                  ? _labels[classIndex]
                  : 'Unknown';

          // Bounding box coordinates (normalized)
          final top = (output[0][i][0] as num).toDouble();
          final left = (output[0][i][1] as num).toDouble();
          final bottom = (output[0][i][2] as num).toDouble();
          final right = (output[0][i][3] as num).toDouble();

          // Clamp coordinates to [0, 1]
          final box = BoundingBox(
            left: left.clamp(0.0, 1.0),
            top: top.clamp(0.0, 1.0),
            right: right.clamp(0.0, 1.0),
            bottom: bottom.clamp(0.0, 1.0),
          );

          detections.add(
            Detection(
              label: label,
              confidence: confidence,
              box: box,
            ),
          );
        }
      }

      return detections;
    } catch (e) {
      print('Error during inference: $e');
      return [];
    }
  }

  /// Convert img.Image to byte list with normalization (float32).
  ///
  /// Normalizes pixel values using mean and std deviation.
  List<double> _imageToByteListFloat32(
    img.Image image,
    int inputSize,
    int inputSizeHeight,
    double mean,
    double std,
  ) {
    final convertedBytes = Float32List(1 * inputSize * inputSizeHeight * 3);
    var pixelIndex = 0;

    for (var i = 0; i < inputSizeHeight; i++) {
      for (var j = 0; j < inputSize; j++) {
        final pixel = image.getPixelSafe(j, i);
        convertedBytes[pixelIndex++] = (pixel.r - mean) / std;
        convertedBytes[pixelIndex++] = (pixel.g - mean) / std;
        convertedBytes[pixelIndex++] = (pixel.b - mean) / std;
      }
    }

    return convertedBytes.toList();
  }

  /// Convert CameraImage to img.Image.
  ///
  /// Handles the conversion from camera format (typically NV21 on Android, BGRA on iOS)
  /// to a standard RGB image.
  img.Image? _cameraImageToImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.bgra8888) {
      // iOS format
      return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: image.planes[0].bytes.buffer,
        //format: img.Format.BGRA,
      );
    } else if (image.format.group == ImageFormatGroup.nv21) {
      // Android format
      return _convertNV21(image);
    }

    return null;
  }

  /// Convert NV21 format (Android) to RGB image.
  img.Image _convertNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    Uint8List yPlane = image.planes[0].bytes;
    Uint8List uvPlane = image.planes[1].bytes;

    Uint8List out = Uint8List(width * height * 3);

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        int yIndex = i * width + j;
        int uvIndex = (i >> 1) * width + (j & ~1);

        int y = yPlane[yIndex].toUnsigned(8);
        int u = uvPlane[uvIndex].toSigned(8);
        int v = uvPlane[uvIndex + 1].toSigned(8);

        int r = (y + (1.402 * v)).round().clamp(0, 255).toInt();
        int g = (y - (0.344136 * u) - (0.714136 * v)).round().clamp(0, 255).toInt();
        int b = (y + (1.772 * u)).round().clamp(0, 255).toInt();

        out[yIndex * 3] = r;
        out[yIndex * 3 + 1] = g;
        out[yIndex * 3 + 2] = b;
      }
    }

    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: out.buffer,
     // format: img.Format.rgb,
    );
  }

  /// Dispose of the interpreter and clean up resources.
  Future<void> dispose() async {
    _interpreter.close();
    _isModelLoaded = false;
  }
}
