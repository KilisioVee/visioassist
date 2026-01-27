╔════════════════════════════════════════════════════════════════════════╗
║                    VISIOASSIST - QUICK REFERENCE                       ║
║              Flutter TensorFlow Lite Object Detection App               ║
╚════════════════════════════════════════════════════════════════════════╝

📌 5-MINUTE QUICK START
═══════════════════════

1. flutter pub get
2. Add model: assets/models/ssd_mobilenet.tflite
3. flutter run --release
4. Select camera or gallery
5. See real-time detections! 🎯

═════════════════════════════════════════════════════════════════════════════

📂 FILE LOCATIONS
═════════════════

Main App:
  lib/main.dart                    - Entry point & routing

Models:
  lib/models/detection.dart        - Detection classes

Services:
  lib/services/object_detection_service.dart   - TFLite logic

State:
  lib/providers/detection_view_model.dart      - State management

UI:
  lib/ui/screens/welcome_screen.dart           - Intro
  lib/ui/screens/source_selection_screen.dart  - Camera vs Gallery
  lib/ui/screens/camera_detection_screen.dart  - Real-time detection
  lib/ui/screens/gallery_detection_screen.dart - Image detection
  lib/ui/screens/settings_screen.dart          - Settings

Utilities:
  lib/utils/permission_utils.dart  - Permissions
  lib/utils/detection_painter.dart - Bounding boxes

Assets:
  assets/models/labels.txt         - COCO labels (provided)
  assets/models/ssd_mobilenet.tflite  - YOUR MODEL (add this!)

Configuration:
  pubspec.yaml                     - Dependencies (updated)

Documentation:
  README.md                        - Full setup guide
  DEVELOPER_GUIDE.md              - Developer reference
  MODEL_CONFIGURATION.md          - Model setup
  IMPLEMENTATION_SUMMARY.md       - Project overview
  SETUP_CHECKLIST.md              - This checklist

═════════════════════════════════════════════════════════════════════════════

⚠️ REQUIRED BEFORE RUNNING
==========================

[ ] Download TFLite model
    → https://tfhub.dev/google/lite-model/object_detection/mobile_ssd/1
    → Place at: assets/models/ssd_mobilenet.tflite

[ ] Run: flutter pub get

[ ] iOS only: Add permissions to Info.plist
    → NSCameraUsageDescription
    → NSPhotoLibraryUsageDescription

═════════════════════════════════════════════════════════════════════════════

🎮 NAVIGATION FLOWS
===================

App Flow:
Welcome Screen
    ↓ "Start Detection"
Source Selection Screen
    ├─→ "Live Camera Detection"
    │       ↓
    │   Camera Detection Screen
    │   (Real-time with overlay)
    │
    └─→ "Gallery Detection"
            ↓
        Gallery Detection Screen
        (Pick image, show results)

Both screens have Settings button (top-right)
    ↓
Settings & Info Screen
(Model info, threshold, labels toggle)

═════════════════════════════════════════════════════════════════════════════

🔧 COMMON CUSTOMIZATIONS
========================

Change Primary Color:
  main.dart → _buildTheme() → primaryColor = Color(0xFF...)

Change Model:
  object_detection_service.dart → loadModel() → fromAsset path

Change Input Size:
  object_detection_service.dart → inputSize = 320 (etc)

Change Labels:
  object_detection_service.dart → loadString() path

Add New Screen:
  1. Create: lib/ui/screens/my_screen.dart
  2. Register: main.dart → routes map
  3. Navigate: Navigator.pushNamed('/route')

═════════════════════════════════════════════════════════════════════════════

⚡ KEY CLASSES & METHODS
========================

Detection Service:
  ObjectDetectionService.instance
  .loadModel()                      - Load TFLite model
  .detectOnImage(File)              - Detect in static image
  .detectOnFrame(CameraImage)       - Detect in camera frame

ViewModel:
  DetectionViewModel
  .initialize()                     - Load model on startup
  .detectOnImage(File)              - Run detection on image
  .setConfidenceThreshold(double)   - Set threshold (0-1)
  .toggleLabels()                   - Toggle label display
  .reset()                          - Clear detections

Models:
  Detection
    .label (String)
    .confidence (double)
    .box (BoundingBox)
    .confidenceString (String%)

  BoundingBox
    .left, .top, .right, .bottom (normalized 0-1)

═════════════════════════════════════════════════════════════════════════════

📊 STATE VARIABLES (in ViewModel)
=================================

detections              - List of detected objects
isLoading              - Model loading state
isDetecting            - Detection in progress
errorMessage           - Error text (if any)
confidenceThreshold    - Min confidence (0.0-1.0)
showLabels             - Show/hide label overlay
isModelLoaded          - Model ready flag

═════════════════════════════════════════════════════════════════════════════

🚀 COMMAND REFERENCE
====================

Get dependencies:
  flutter pub get

Run app (debug):
  flutter run

Run app (release - faster!):
  flutter run --release

Run on specific device:
  flutter run -d ios
  flutter run -d android

Clean build:
  flutter clean

View devices:
  flutter devices

Build APK (Android):
  flutter build apk --release

Build IPA (iOS):
  flutter build ios --release

═════════════════════════════════════════════════════════════════════════════

📱 SCREEN DESCRIPTIONS
======================

Welcome Screen
  • App icon and branding
  • Feature highlights
  • "Start Detection" button

Source Selection
  • Choose: Camera OR Gallery
  • Card-based UI

Camera Detection
  • Live camera preview
  • Real-time bounding boxes
  • Start/Stop toggle
  • Camera switch button
  • Detection results list
  • Settings button

Gallery Detection
  • Pick image from gallery
  • Full-screen image with overlay
  • Detection results list below
  • Pick another image button
  • Settings button

Settings
  • Model information (name, size, dataset, classes)
  • Confidence threshold slider (0-100%)
  • Label visibility toggle
  • Privacy notice
  • App info

═════════════════════════════════════════════════════════════════════════════

🔍 DEBUGGING TIPS
=================

Print model status:
  if (viewModel.isModelLoaded) print('✓ Ready');

Print detections:
  viewModel.detections.forEach((d) {
    print('${d.label}: ${d.confidence}');
  });

Check permissions:
  await PermissionUtils.hasCameraPermission()
  await PermissionUtils.hasPhotosPermission()

Monitor errors:
  if (viewModel.errorMessage != null) {
    print('Error: ${viewModel.errorMessage}');
  }

Use DevTools:
  • flutter pub global activate devtools
  • devtools

═════════════════════════════════════════════════════════════════════════════

📈 PERFORMANCE TIPS
===================

For Faster Detection:
  □ Use release build: flutter run --release
  □ Lower confidence threshold
  □ Use smaller input size (if possible)
  □ Use quantized model
  □ Test on real device (emulator is slow)

For Better Accuracy:
  □ Raise confidence threshold
  □ Use larger input size (if device can handle)
  □ Use unquantized model (slower)
  □ Ensure good lighting
  □ Better camera resolution

Optimize Memory:
  □ Avoid keeping image copies
  □ Dispose camera controller properly
  □ Use const widgets
  □ Implement proper state cleanup

═════════════════════════════════════════════════════════════════════════════

❓ COMMON QUESTIONS
===================

Q: Where do I add the TFLite model?
A: assets/models/ssd_mobilenet.tflite

Q: Can I use a different model?
A: Yes, update ObjectDetectionService.loadModel() path

Q: How do I change the threshold?
A: In Settings screen or: viewModel.setConfidenceThreshold(0.7)

Q: Why is detection slow?
A: Use release build, real device, or smaller model

Q: Can I run offline?
A: Yes, all processing is on-device!

Q: How do I add more screens?
A: Create in lib/ui/screens/, register in main.dart routes

Q: How do I change colors?
A: Edit _buildTheme() in main.dart

Q: What models are supported?
A: Any TensorFlow Lite object detection model

═════════════════════════════════════════════════════════════════════════════

✅ FINAL CHECKLIST
==================

Before deploying:
  [ ] Model file added
  [ ] flutter pub get completed
  [ ] App runs without crashes
  [ ] Camera detection works
  [ ] Gallery detection works
  [ ] Settings accessible
  [ ] All buttons functional
  [ ] Permissions handled
  [ ] iOS Info.plist updated

═════════════════════════════════════════════════════════════════════════════

📞 QUICK HELP
=============

Setup help       → README.md
Code questions   → DEVELOPER_GUIDE.md
Model questions  → MODEL_CONFIGURATION.md
See detailed     → IMPLEMENTATION_SUMMARY.md
Details          → Inline code comments

═════════════════════════════════════════════════════════════════════════════

🎯 YOU'RE READY TO BUILD AMAZING THINGS!

Happy coding! 🚀
