import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../providers/detection_view_model.dart';
import '../../utils/permission_utils.dart';
import '../../utils/detection_painter.dart';

/// Screen for real-time object detection using the camera.
///
/// Displays a live camera preview with bounding boxes drawn
/// over detected objects. Allows start/stop detection and camera switching.
class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetectionRunning = false;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _showPermissionError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final hasCameraPermission = await PermissionUtils.hasCameraPermission();

    if (!hasCameraPermission) {
      final granted = await PermissionUtils.requestCameraPermission();
      if (!granted) {
        setState(() {
          _showPermissionError = true;
        });
        return;
      }
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showSnackBar('No cameras available on this device');
        return;
      }

      await _setupCameraController(_cameras[_currentCameraIndex]);
    } catch (e) {
      _showSnackBar('Error initializing camera: $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    if (_isCameraInitialized) {
      await _cameraController.dispose();
      _isCameraInitialized = false;
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });

        // Start image stream for detection
        _startDetectionStream();
      }
    } catch (e) {
      _showSnackBar('Error initializing camera controller: $e');
    }
  }

  void _startDetectionStream() {
    _cameraController.startImageStream((CameraImage image) async {
      if (!_isDetectionRunning) return;

      final viewModel = context.read<DetectionViewModel>();
      await viewModel.detectOnFrame(image);
      viewModel.notifyDetectionsUpdated();
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      _showSnackBar('Only one camera available');
      return;
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _setupCameraController(_cameras[_currentCameraIndex]);
  }

  void _toggleDetection() {
    setState(() {
      _isDetectionRunning = !_isDetectionRunning;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized) return;
    if (!_cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      if (_isDetectionRunning) {
        _startDetectionStream();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showPermissionError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Detection'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.switch_camera,
                  size: 64,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Camera Permission Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app needs camera access to detect objects. Please enable it in app settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await PermissionUtils.openSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Detection'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Detection'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview with Detections
          Expanded(
            child: Stack(
              children: [
                // Camera feed
                CameraPreview(_cameraController),

                // Detection overlay
                Consumer<DetectionViewModel>(
                  builder: (context, viewModel, child) {
                    return CustomPaint(
                      painter: DetectionPainter(
                        detections: viewModel.detections,
                        showLabels: viewModel.showLabels,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Detections counter
                Positioned(
                  top: 16,
                  right: 16,
                  child: Consumer<DetectionViewModel>(
                    builder: (context, viewModel, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${viewModel.detections.length} objects',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Detection results (scrollable)
                if (_isDetectionRunning)
                  Consumer<DetectionViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.detections.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No objects detected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: viewModel.detections.length,
                          itemBuilder: (context, index) {
                            final detection = viewModel.detections[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.deepPurple,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    detection.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    detection.confidenceString,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // Control Buttons
                Row(
                  children: [
                    // Start/Stop Detection Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleDetection,
                        icon: Icon(
                          _isDetectionRunning ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(
                          _isDetectionRunning ? 'Stop Detection' : 'Start Detection',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDetectionRunning
                              ? Colors.red
                              : Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Switch Camera Button
                    if (_cameras.length > 1)
                      ElevatedButton.icon(
                        onPressed: _switchCamera,
                        icon: const Icon(Icons.flip_camera_ios),
                        label: const Text('Switch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
