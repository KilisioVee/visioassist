import 'dart:io';
import 'dart:math' as math;
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

  img.Image _convertNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    Uint8List yPlane = image.planes[0].bytes;
    Uint8List uvPlane = image.planes[1].bytes;

    Uint8List out = Uint8List(width * height * 3);

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        int yIndex = i * width + j;

        // UV plane is 1/4 resolution (half width, half height)
        // Each 2x2 block of Y pixels shares one U and one V
        int uvPixelRow = i >> 1;
        int uvPixelCol = j >> 1;
        int uvPlaneWidth = width >> 1;  // UV plane width is half of Y plane
        // Each UV pixel occupies 2 bytes (V, U in NV21 format)
        int uvByteIndex = (uvPixelRow * uvPlaneWidth + uvPixelCol) * 2;

        int y = yPlane[yIndex].toUnsigned(8);
        int v = uvPlane[uvByteIndex].toSigned(8);      // V comes first in NV21
        int u = uvPlane[uvByteIndex + 1].toSigned(8);  // U comes second in NV21

        // YUV to RGB conversion
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
    );
  }

  /// Parse single-tensor output format for models with combined outputs.
  ///
  /// Some TFLite models output everything in a single tensor like [1, numDetections, N]
  /// where N includes both bounding boxes and possibly confidence/class data.
  ///
  /// Common formats:
  /// - [1, numDetections, 4]: Just boxes (coords only)
  /// - [1, numDetections, 5]: Boxes + confidence score
  /// - [1, numDetections, 6+]: Boxes + confidence + class scores
  Future<List<Detection>> _parseSingleOutputTensor(
    dynamic outputTensor,
    dynamic input,
    int inputSize,
  ) async {
    final detections = <Detection>[];

    try {
      final shape = outputTensor.shape as List<int>;
      print('_parseSingleOutputTensor: Parsing tensor shape $shape, type: ${outputTensor.type}');

      // Create appropriate output buffer
      final outputBuffer = _createOutputBuffer(outputTensor);
      print('_parseSingleOutputTensor: Created output buffer');

      // Run inference
      _interpreter.runForMultipleInputs([input], {0: outputBuffer});
      print('_parseSingleOutputTensor: Inference completed');

      if (shape.length != 3) {
        print('ERROR: Expected 3D tensor, got ${shape.length}D');
        return [];
      }

      final batchSize = shape[0];
      final numResults = shape[1];
      final contentSize = shape[2];

      print('_parseSingleOutputTensor: Batch=$batchSize, NumResults=$numResults, ContentSize=$contentSize');

      // Iterate through results and extract detections
      for (int i = 0; i < numResults; i++) {
        try {
          final result = outputBuffer[0][i];

          if (contentSize < 4) {
            print('Skipping result $i: content too small ($contentSize < 4)');
            continue;
          }

          // Extract bounding box coordinates
          // Common format: [top, left, bottom, right] or [y1, x1, y2, x2]
          var y1 = (result[0] as num).toDouble();
          var x1 = (result[1] as num).toDouble();
          var y2 = (result[2] as num).toDouble();
          var x2 = (result[3] as num).toDouble();

          print('Result $i: coords=($x1,$y1,$x2,$y2)');

          // Extract confidence if available
          double confidence = 1.0; // Default to high confidence if not specified
          if (contentSize > 4) {
            confidence = (result[4] as num).toDouble();
            // If it's uint8, normalize to 0-1
            if (outputTensor.type == TensorType.uint8) {
              confidence /= 255.0;
            }
            print('  Confidence: $confidence');
          }

          // Only include detections with meaningful confidence
          if (confidence < 0.05) {
            print('  Skipping: confidence too low');
            continue;
          }

          // Normalize coordinates if needed
          // Some models output in [0,1] range, others in pixel coordinates
          // We assume normalized [0,1] range

          final box = BoundingBox(
            left: x1.clamp(0.0, 1.0),
            top: y1.clamp(0.0, 1.0),
            right: x2.clamp(0.0, 1.0),
            bottom: y2.clamp(0.0, 1.0),
          );

          // Extract class label if available
          String label = 'Object';
          if (contentSize > 5) {
            try {
              int classIndex = (result[5] as num).toInt();
              if (classIndex >= 0 && classIndex < _labels.length) {
                label = _labels[classIndex];
              }
            } catch (_) {
              // Couldn't extract class, use default
            }
          }

          detections.add(Detection(
            label: label,
            confidence: confidence,
            box: box,
          ));

          print('  Added detection: $label (conf=$confidence, box=($x1,$y1,$x2,$y2))');

        } catch (e) {
          print('Error processing result $i: $e');
          continue;
        }
      }

      print('_parseSingleOutputTensor: Extracted ${detections.length} detections');

    } catch (e) {
      print('Error parsing single-output tensor: $e');
    }

    return detections;
  }
  Future<List<Detection>> _parseTwoTensorOutput(
      dynamic input,
      double confidenceThreshold,
      ) async {
    final detections = <Detection>[];

    try {
      final boxesTensor = _interpreter.getOutputTensor(0);
      final classesTensor = _interpreter.getOutputTensor(1);

      print(
        '_parseTwoTensorOutput: '
            'boxes shape=${boxesTensor.shape}, type=${boxesTensor.type}',
      );
      print(
        '_parseTwoTensorOutput: '
            'classes shape=${classesTensor.shape}, type=${classesTensor.type}',
      );

      final boxesBuffer = _createOutputBuffer(boxesTensor);
      final classesBuffer = _createOutputBuffer(classesTensor);

      _interpreter.runForMultipleInputs([input], {
        0: boxesBuffer,
        1: classesBuffer,
      });

      final boxesShape = boxesTensor.shape;
      final classesShape = classesTensor.shape;

      if (boxesShape.length != 3 || classesShape.length != 3) {
        print('ERROR: Expected 3D tensors for two-tensor output parsing');
        return [];
      }

      final numDetections = boxesShape[1];
      final numClasses = classesShape[2];

      print(
        '_parseTwoTensorOutput: '
            'numDetections=$numDetections, numClasses=$numClasses',
      );

      for (int i = 0; i < numDetections; i++) {
        final box = boxesBuffer[0][i];
        final classScores = classesBuffer[0][i];

        if (box.length < 4) {
          continue;
        }

        double y1 = (box[0] as num).toDouble();
        double x1 = (box[1] as num).toDouble();
        double y2 = (box[2] as num).toDouble();
        double x2 = (box[3] as num).toDouble();

        int bestClass = -1;
        double bestScore = double.negativeInfinity;

        for (int c = 0; c < numClasses; c++) {
          final score = (classScores[c] as num).toDouble();
          if (score > bestScore) {
            bestScore = score;
            bestClass = c;
          }
        }

        double confidence = bestScore;

        // If model outputs logits instead of probabilities, apply sigmoid.
        if (confidence < 0.0 || confidence > 1.0) {
          confidence = 1.0 / (1.0 + math.exp(-confidence));
        }

        if (confidence < confidenceThreshold) {
          continue;
        }

        final label = (bestClass >= 0 && bestClass < _labels.length)
            ? _labels[bestClass]
            : 'Class $bestClass';

        detections.add(
          Detection(
            label: label,
            confidence: confidence,
            box: BoundingBox(
              left: x1.clamp(0.0, 1.0),
              top: y1.clamp(0.0, 1.0),
              right: x2.clamp(0.0, 1.0),
              bottom: y2.clamp(0.0, 1.0),
            ),
          ),
        );

        print(
          '_parseTwoTensorOutput: '
              'det=$i label=$label class=$bestClass conf=$confidence '
              'box=($x1,$y1,$x2,$y2)',
        );
      }

      return detections;
    } catch (e) {
      print('Error parsing two-tensor output: $e');
      return [];
    }
  }
  /// Parse alternative output formats for models that don't use the standard 4-output format.
  ///
  /// Some TFLite models combine outputs differently or have different tensor structures.
  Future<List<Detection>> _parseAlternativeOutput(
    Interpreter interpreter,
    dynamic input,
    int inputSize,
  ) async {
    final detections = <Detection>[];

    try {
      // Get the single output tensor
      final outputTensor = interpreter.getOutputTensor(0);
      print('Alternative output parsing - Tensor shape: ${outputTensor.shape}, type: ${outputTensor.type}');

      // Create appropriate buffer based on shape
      final outputBuffer = _createOutputBuffer(outputTensor);

      // Run inference
      interpreter.runForMultipleInputs([input], {0: outputBuffer});

      // The output might be in various formats. Common ones for SSD include:
      // 1. [1, numDetections, (4 + numClasses)] - combined boxes and classes
      // 2. [numDetections, (4 + numClasses)]
      // 3. [1, numDetections, 4] with separate class/score tensors stored elsewhere

      print('Alternative format detected. Output buffer content (first few values):');
      print('  Full output: $outputBuffer');

      // For now, just log and return empty to indicate we need to investigate further
      print('⚠️ Unknown output format. Cannot parse detections.');
      print('Output tensor shape: ${outputTensor.shape}');

    } catch (e) {
      print('Error parsing alternative output format: $e');
    }

    return detections;
  }

  /// Dispose of the interpreter and clean up resources.
  Future<void> dispose() async {
    _interpreter.close();
    _isModelLoaded = false;
  }

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

      // Log model input/output details for debugging
      final inputTensor = _interpreter.getInputTensor(0);
      final outputTensor = _interpreter.getOutputTensor(0);
      print('ObjectDetectionService: Model input shape: ${inputTensor.shape}, type: ${inputTensor.type}');
      print('ObjectDetectionService: Model output[0] shape: ${outputTensor.shape}, type: ${outputTensor.type}');

      // Load the labels file
      final labelsData =
          await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n');
      _labels.removeWhere((label) => label.isEmpty);

      _isModelLoaded = true;
      print('ObjectDetectionService: Model loaded successfully');
      print('ObjectDetectionService: Labels count: ${_labels.length}');
      print('ObjectDetectionService: First few labels: ${_labels.take(5).join(", ")}');
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
    final inputTensor = _interpreter.getInputTensor(0);
    final input = _imageToTensor(resized, inputTensor.type);

    try {
      // First, check how many output tensors the model has
      final outputCount = _interpreter.getOutputTensors().length;
      print('ObjectDetectionService._runInference: Model has $outputCount output tensor(s)');

      if (outputCount == 0) {
        print('ERROR: Model has no output tensors!');
        return [];
      }

      final outputTensor0 = _interpreter.getOutputTensor(0);
      print('ObjectDetectionService._runInference: Output[0] shape: ${outputTensor0.shape}, type: ${outputTensor0.type}');

      // Check if this is a single-tensor model with combined output format
      if (outputCount == 1 &&
          outputTensor0.shape.length == 3 &&
          outputTensor0.shape[2] >= 4) {
        return _parseSingleOutputTensor(outputTensor0, input, inputSize);
      }
      if (outputCount == 2) {
        return _parseTwoTensorOutput(input, confidenceThreshold);
      }
      // Standard 4-output format
      if (outputCount < 4) {
        print('ERROR: Unsupported output tensor count: $outputCount');
        for (int i = 0; i < outputCount; i++) {
          final tensor = _interpreter.getOutputTensor(i);
          print('  - Output[$i] shape: ${tensor.shape}, type: ${tensor.type}');
        }
        return [];
      }

      final outputTensor1 = _interpreter.getOutputTensor(1);
      final outputTensor2 = _interpreter.getOutputTensor(2);
      final outputTensor3 = _interpreter.getOutputTensor(3);

      print('ObjectDetectionService._runInference: Creating output buffers for standard 4-tensor format...');
      print('  - Output[0] shape: ${outputTensor0.shape}, type: ${outputTensor0.type}');
      print('  - Output[1] shape: ${outputTensor1.shape}, type: ${outputTensor1.type}');
      print('  - Output[2] shape: ${outputTensor2.shape}, type: ${outputTensor2.type}');
      print('  - Output[3] shape: ${outputTensor3.shape}, type: ${outputTensor3.type}');

      // Create output buffers matching the actual tensor shapes
      // For shape [1, numResults, 4], create nested list as [[..., ...]]
      final output = _createOutputBuffer(outputTensor0);
      final outputClasses = _createOutputBuffer(outputTensor1);
      final outputScores = _createOutputBuffer(outputTensor2);
      final numDetections = _createOutputBuffer(outputTensor3);

      // Run inference
      _interpreter.runForMultipleInputs([input], {
        0: output,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      });

      print('ObjectDetectionService._runInference: Inference completed successfully');
      print('ObjectDetectionService._runInference: numDetections buffer: $numDetections');
      print('ObjectDetectionService._runInference: output buffer type: ${output.runtimeType}');
      print('ObjectDetectionService._runInference: outputScores buffer type: ${outputScores.runtimeType}');

      // Parse results
      final detections = <Detection>[];
      // numDetections is a 1D tensor [1], so access as [0] not [0][0]
      final numDets = (numDetections[0] as num).toInt();
      print('ObjectDetectionService._runInference: RAW Number of detections: $numDets');

      final bool scoresAreUint8 = outputTensor2.type == TensorType.uint8;
      final bool boxesAreUint8 = outputTensor0.type == TensorType.uint8;

      print('ObjectDetectionService._runInference: Output tensor types:');
      print('  - Boxes (tensor 0): ${outputTensor0.type}');
      print('  - Classes (tensor 1): ${outputTensor1.type}');
      print('  - Scores (tensor 2): ${outputTensor2.type}');
      print('  - NumDets (tensor 3): ${outputTensor3.type}');

      // Show raw values for debugging
      final scoresToShow = <double>[];
      for (int i = 0; i < numResults; i++) {
        var score = (outputScores[0][i] as num).toDouble();
        if (scoresAreUint8) {
          scoresToShow.add(score / 255.0);
        } else {
          scoresToShow.add(score);
        }
      }
      print('ObjectDetectionService._runInference: ALL normalized scores: $scoresToShow');
      print('ObjectDetectionService._runInference: ALL output classes: ${outputClasses[0]}');

      // Also show raw unnormalized scores
      final rawScores = <dynamic>[];
      for (int i = 0; i < numResults; i++) {
        rawScores.add(outputScores[0][i]);
      }
      print('ObjectDetectionService._runInference: ALL RAW scores (before normalization): $rawScores');

      // Show first few boxes
      print('ObjectDetectionService._runInference: First few bounding boxes:');
      for (int i = 0; i < 3 && i < numResults; i++) {
        final top = output[0][i][0];
        final left = output[0][i][1];
        final bottom = output[0][i][2];
        final right = output[0][i][3];
        print('  Box[$i]: top=$top, left=$left, bottom=$bottom, right=$right');
      }

      for (int i = 0; i < numDets && i < numResults; i++) {
        final scoreValue = outputScores[0][i];
        var confidence = (scoreValue as num).toDouble();
        if (scoresAreUint8) {
          confidence = confidence / 255.0;
        }
        print('ObjectDetectionService: Detection $i - confidence: $confidence');

        if (confidence >= confidenceThreshold) {
          final classIndexValue = outputClasses[0][i];
          final classIndex = (classIndexValue as num).toInt();
          final label =
              classIndex >= 0 && classIndex < _labels.length
                  ? _labels[classIndex]
                  : 'Unknown';
          print('ObjectDetectionService: Detection $i - class: $classIndex ($label)');

          // Bounding box coordinates (normalized)
          var top = (output[0][i][0] as num).toDouble();
          var left = (output[0][i][1] as num).toDouble();
          var bottom = (output[0][i][2] as num).toDouble();
          var right = (output[0][i][3] as num).toDouble();

          if (boxesAreUint8) {
            top /= 255.0;
            left /= 255.0;
            bottom /= 255.0;
            right /= 255.0;
          }

          print('ObjectDetectionService: Detection $i - box: [$left, $top, $right, $bottom]');

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

  /// Converts [image] into a tensor suitable for the model input.
  ///
  /// Supports both float32 and uint8 inputs.
  /// For quantized uint8 models: uses raw pixel values (0-255) in RGB order
  /// For float32 models: normalizes values to [-1, 1] range
  dynamic _imageToTensor(img.Image image, TensorType inputType) {
    if (inputType == TensorType.uint8 || inputType == TensorType.int8) {
      return [
        List.generate(inputSize, (y) {
          return List.generate(inputSize, (x) {
            final pixel = image.getPixelSafe(x, y);
            return [
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
            ];
          });
        }),
      ];
    }

    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = image.getPixelSafe(x, y);
          return [
            (pixel.r.toDouble() - 127.5) / 127.5,
            (pixel.g.toDouble() - 127.5) / 127.5,
            (pixel.b.toDouble() - 127.5) / 127.5,
          ];
        });
      }),
    ];
  }

  /// Create a nested buffer for model output based on the tensor shape and type.
  dynamic _createOutputBuffer(dynamic tensor) {
    final shape = tensor.shape as List<int>;
    final type = tensor.type;

    if (shape.length == 1) {
      // 1D tensor like [1] or [100]
      if (type == TensorType.uint8 || type == TensorType.int8) {
        return List.filled(shape[0], 0);
      } else if (type == TensorType.float32) {
        return List.filled(shape[0], 0.0);
      } else {
        return List.filled(shape[0], 0);
      }
    } else if (shape.length == 2) {
      // 2D tensor like [1, 10]
      final outer = shape[0];
      final inner = shape[1];
      if (type == TensorType.uint8 || type == TensorType.int8) {
        return List.generate(outer, (_) => List.filled(inner, 0));
      } else {
        return List.generate(outer, (_) => List.filled(inner, 0.0));
      }
    } else if (shape.length == 3) {
      // 3D tensor like [1, 10, 4]
      final d1 = shape[0];
      final d2 = shape[1];
      final d3 = shape[2];
      if (type == TensorType.uint8 || type == TensorType.int8) {
        return List.generate(
          d1,
          (_) => List.generate(d2, (_) => List.filled(d3, 0)),
        );
      } else {
        return List.generate(
          d1,
          (_) => List.generate(d2, (_) => List.filled(d3, 0.0)),
        );
      }
    } else {
      // Fallback
      return List.filled(10, List.filled(1, 0.0));
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
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        convertedBytes[pixelIndex++] = (r - mean) / std;
        convertedBytes[pixelIndex++] = (g - mean) / std;
        convertedBytes[pixelIndex++] = (b - mean) / std;
      }
    }

    return convertedBytes.toList();
  }

  /// Convert CameraImage to img.Image.
  ///
  /// Handles the conversion from camera format (typically NV21 on Android, BGRA on iOS)
  /// to a standard RGB image. Crops to square and rotates to match preview orientation.
  img.Image? _cameraImageToImage(CameraImage image) {
    print(
      'ObjectDetectionService._cameraImageToImage: '
          'format group=${image.format.group}, raw=${image.format.raw}, '
          'planes=${image.planes.length}, size=${image.width}x${image.height}',
    );

    img.Image? convertedImage;

    if (image.format.group == ImageFormatGroup.bgra8888) {
      final bytes = image.planes[0].bytes;
      convertedImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    } else if (image.format.group == ImageFormatGroup.nv21) {
      convertedImage = _convertNV21(image);
    } else if (image.format.group == ImageFormatGroup.yuv420) {
      convertedImage = _convertYUV420(image);
    } else {
      print('Unsupported format group: ${image.format.group}');
      return null;
    }

    convertedImage = img.copyRotate(convertedImage, angle: 90);

    final size = convertedImage.width < convertedImage.height
        ? convertedImage.width
        : convertedImage.height;

    final x = (convertedImage.width - size) ~/ 2;
    final y = (convertedImage.height - size) ~/ 2;

    return img.copyCrop(
      convertedImage,
      x: x,
      y: y,
      width: size,
      height: size,
    );
  }
  img.Image _convertYUV420(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;

    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    final out = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final uvRow = y >> 1;

      for (int x = 0; x < width; x++) {
        final uvCol = x >> 1;

        final yIndex = y * yRowStride + x;
        final uIndex = uvRow * uRowStride + uvCol * uPixelStride;
        final vIndex = uvRow * vRowStride + uvCol * vPixelStride;

        final yp = yBytes[yIndex];
        final up = uBytes[uIndex];
        final vp = vBytes[vIndex];

        final r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
        final g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
            .round()
            .clamp(0, 255);
        final b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

}