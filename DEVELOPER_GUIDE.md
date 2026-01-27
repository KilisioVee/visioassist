// QUICK START GUIDE FOR DEVELOPERS

/**
 * FILE STRUCTURE OVERVIEW
 * =======================
 * 
 * lib/
 * ├── main.dart
 * │   └── App entry point, routing, theme setup
 * │
 * ├── models/
 * │   └── detection.dart
 * │       └── Detection, BoundingBox classes
 * │
 * ├── services/
 * │   └── object_detection_service.dart
 * │       └── Singleton service for TFLite model loading & inference
 * │
 * ├── providers/
 * │   └── detection_view_model.dart
 * │       └── ChangeNotifier for state management
 * │
 * ├── utils/
 * │   ├── permission_utils.dart (camera, gallery permissions)
 * │   └── detection_painter.dart (CustomPainter for bounding boxes)
 * │
 * └── ui/
 *     └── screens/
 *         ├── welcome_screen.dart (intro & branding)
 *         ├── source_selection_screen.dart (camera vs gallery)
 *         ├── camera_detection_screen.dart (real-time detection)
 *         ├── gallery_detection_screen.dart (image detection)
 *         └── settings_screen.dart (config & info)
 * 
 * assets/
 * └── models/
 *     ├── ssd_mobilenet.tflite (⚠️ ADD YOUR MODEL HERE)
 *     └── labels.txt (✓ Already provided - COCO labels)
 */

/**
 * KEY CLASSES
 * ===========
 */

// lib/models/detection.dart
class BoundingBox {
  final double left, top, right, bottom;  // Normalized: 0.0 to 1.0
}

class Detection {
  final String label;
  final double confidence;  // 0.0 to 1.0
  final BoundingBox box;
}

// lib/services/object_detection_service.dart
class ObjectDetectionService {
  // Singleton
  static final instance = ObjectDetectionService._instance;
  
  // Load model on startup
  Future<void> loadModel() async { ... }
  
  // Detect in static image
  Future<List<Detection>> detectOnImage(File imageFile) async { ... }
  
  // Detect in camera frame (real-time)
  Future<List<Detection>> detectOnFrame(CameraImage frame) async { ... }
}

// lib/providers/detection_view_model.dart
class DetectionViewModel extends ChangeNotifier {
  List<Detection> detections;
  bool isLoading, isDetecting;
  String? errorMessage;
  double confidenceThreshold;  // 0.0-1.0
  bool showLabels;
  
  Future<void> initialize() { ... }
  Future<void> detectOnImage(File image) { ... }
  Future<void> detectOnFrame(CameraImage frame) { ... }
}

/**
 * HOW TO USE IN SCREENS
 * =====================
 */

// Access detection results
Consumer<DetectionViewModel>(
  builder: (context, viewModel, child) {
    return Text('Detections: ${viewModel.detections.length}');
  },
)

// Draw bounding boxes
CustomPaint(
  painter: DetectionPainter(
    detections: viewModel.detections,
    showLabels: viewModel.showLabels,
  ),
  size: Size.infinite,
)

/**
 * INFERENCE PIPELINE
 * ==================
 */

// 1. INITIALIZATION (happens once on app startup)
//    - Model loaded via ObjectDetectionService.loadModel()
//    - Labels loaded from assets/models/labels.txt
//
// 2. IMAGE INPUT
//    - Image resized to 300×300 (SSD MobileNet size)
//    - Pixel values normalized (subtract mean, divide by std)
//
// 3. MODEL INFERENCE
//    - Normalized image passed to TFLite interpreter
//    - Returns tensors: boxes, classes, scores, num_detections
//
// 4. POST-PROCESSING
//    - Parse output tensors
//    - Filter by confidence threshold
//    - Clamp box coordinates to [0,1]
//    - Return List<Detection>
//
// 5. UI RENDERING
//    - CustomPainter draws boxes on image
//    - Scale from normalized coords to pixel coords
//    - Display label + confidence

/**
 * CUSTOMIZATION GUIDE
 * ===================
 */

// Change model
// File: lib/services/object_detection_service.dart
_interpreter = await Interpreter.fromAsset('assets/models/YOUR_MODEL.tflite');

// Change input size (if using different model)
static const int inputSize = 320;  // Change from 300

// Change labels
// File: lib/services/object_detection_service.dart
final labelsData = await rootBundle.loadString('assets/models/YOUR_LABELS.txt');

// Change theme colors
// File: lib/main.dart, in _buildTheme()
const primaryColor = Color(0xFF7C3AED);     // Deep Purple
const secondaryColor = Color(0xFF06B6D4);   // Cyan

// Add new screen
// 1. Create: lib/ui/screens/my_screen.dart
// 2. Route: Add to routes map in main.dart
// 3. Navigate: Navigator.of(context).pushNamed('/my-route')

/**
 * COMMON TASKS
 * ============
 */

// Update confidence threshold
viewModel.setConfidenceThreshold(0.7);  // 70%

// Toggle labels
viewModel.toggleLabels();

// Get detection results
List<Detection> results = viewModel.detections;
for (var detection in results) {
  print('${detection.label}: ${detection.confidence * 100}%');
}

// Reset state
viewModel.reset();

/**
 * PERFORMANCE TIPS
 * ================
 */

// 1. Use release build
//    flutter run --release
//
// 2. Add frame throttling in camera detection
//    if (frameCount % 3 == 0) { runDetection(); }
//
// 3. Use quantized models (smaller, faster)
//    _mobilenet_v2_1.0_224_quant.tflite
//
// 4. Process frames asynchronously
//    Future.microtask(() => detectOnFrame(frame));
//
// 5. Update UI periodically, not on every frame
//    Use a Timer or periodic throttle

/**
 * DEBUGGING
 * =========
 */

// Check if model is loaded
bool loaded = context.read<DetectionViewModel>().isModelLoaded;

// Print detection results
viewModel.detections.forEach((d) {
  print('${d.label} (${d.confidence})');
  print('  Box: ${d.box}');
});

// Check permissions
bool hasCameraPermission = await PermissionUtils.hasCameraPermission();
bool hasPhotosPermission = await PermissionUtils.hasPhotosPermission();

// Monitor state changes
DevTools > Logging > Look for TFLite messages

/**
 * IMPORTANT NOTES
 * ===============
 */

// ⚠️  YOU MUST ADD YOUR OWN TFLITE MODEL
//     - Download from TensorFlow Hub or TensorFlow Lite
//     - Place in assets/models/ssd_mobilenet.tflite
//     - Or update the path in ObjectDetectionService
//
// ✓ Labels file is already provided (COCO dataset)
//   - 80 common object classes
//   - If using different model/dataset, provide your own
//
// 📱 Platform-specific requirements:
//   - Android: No extra setup needed
//   - iOS: Add permissions to Info.plist
//           NSCameraUsageDescription
//           NSPhotoLibraryUsageDescription
//
// 🔒 Privacy: All processing happens on-device
//    No images sent to server, fully private

/**
 * USEFUL RESOURCES
 * ================
 */

// TensorFlow Lite
// https://www.tensorflow.org/lite

// Model Zoo
// https://github.com/tensorflow/models/tree/master/research/object_detection

// Provider Documentation
// https://pub.dev/packages/provider

// Flutter Camera Plugin
// https://pub.dev/packages/camera

// Image Processing
// https://pub.dev/packages/image
