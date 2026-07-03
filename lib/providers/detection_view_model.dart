import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/detection.dart';
import '../services/object_detection_service.dart';

/// ViewModel for managing object detection state and logic.
///
/// Handles:
/// - Model loading
/// - Running detection on frames and images
/// - Managing detection results
/// - Error handling
/// - Configuration (confidence threshold, etc.)
class DetectionViewModel extends ChangeNotifier {
  final ObjectDetectionService _detectionService = ObjectDetectionService();

  // State variables
  List<Detection> _detections = [];
  bool _isLoading = false;
  bool _isDetecting = false;
  String? _errorMessage;
  double _confidenceThreshold = 0.3;
  bool _showLabels = true;

  // Getters
  List<Detection> get detections => _detections;
  bool get isLoading => _isLoading;
  bool get isDetecting => _isDetecting;
  String? get errorMessage => _errorMessage;
  double get confidenceThreshold => _confidenceThreshold;
  bool get showLabels => _showLabels;
  bool get isModelLoaded => _detectionService.isModelLoaded;

  /// Initialize the ViewModel by loading the TFLite model.
  ///
  /// Should be called once when the app starts.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _detectionService.loadModel();
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load model: $e';
      print('Initialization error: $e');
    }

    notifyListeners();
  }

  /// Run object detection on a static image file.
  ///
  /// Updates the detections list and rebuilds the UI.
  Future<void> detectOnImage(File imageFile) async {
    _errorMessage = null;
    _isDetecting = true;
    notifyListeners();

    try {
      _detections = await _detectionService.detectOnImage(
        imageFile,
        confidenceThreshold: _confidenceThreshold,
      );
      _isDetecting = false;
    } catch (e) {
      _isDetecting = false;
      _errorMessage = 'Detection failed: $e';
      _detections = [];
      print('Detection error: $e');
    }

    notifyListeners();
  }

  /// Run object detection on a camera frame.
  ///
  /// Used for real-time detection from the camera stream.
  /// Does not notify listeners (called frequently).
  /// Call [notifyDetectionsUpdated] to trigger UI update.
  Future<void> detectOnFrame(CameraImage frame) async {
    if (!isModelLoaded) return;

    try {
      _detections = await _detectionService.detectOnFrame(
        frame,
        confidenceThreshold: 0.1, // Lowered threshold to debug
      );
      print('DetectionViewModel: Frame detection completed');
      print('DetectionViewModel: Detected ${_detections.length} objects');
      if (_detections.isNotEmpty) {
        for (int i = 0; i < _detections.length && i < 3; i++) {
          print('  - Detection $i: ${_detections[i].label} (confidence: ${_detections[i].confidence.toStringAsFixed(3)})');
        }
      }
    } catch (e) {
      _errorMessage = 'Frame detection failed: $e';
      print('DetectionViewModel: Error in detectOnFrame: $e');
    }
  }

  /// Notify listeners of detection updates (after running [detectOnFrame]).
  ///
  /// Used to avoid notifying listeners on every frame.
  /// Instead, batch updates and notify periodically.
  void notifyDetectionsUpdated() {
    notifyListeners();
  }

  /// Update the confidence threshold for detections.
  void setConfidenceThreshold(double threshold) {
    if (threshold >= 0.0 && threshold <= 1.0) {
      _confidenceThreshold = threshold;
      notifyListeners();
    }
  }

  /// Toggle label visibility on detection overlays.
  void toggleLabels() {
    _showLabels = !_showLabels;
    notifyListeners();
  }

  /// Clear current detections and reset state.
  void reset() {
    _detections = [];
    _errorMessage = null;
    _isDetecting = false;
    notifyListeners();
  }

  /// Clear the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _detectionService.dispose();
    super.dispose();
  }
}
