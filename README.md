# VisioAssist - Flutter Object Detection App

A complete, production-ready Flutter application for on-device object detection using TensorFlow Lite and a pre-trained SSD MobileNet model. All detection happens entirely on your device—no images are sent to any server.

## Features

✨ **Real-Time Camera Detection** - Detect objects as they appear in your camera feed
📸 **Gallery Detection** - Pick images from your gallery and detect objects
🔒 **On-Device Processing** - All ML inference runs locally on your device
⚡ **Efficient** - Optimized for smooth performance on mobile devices
🎨 **Beautiful UI** - Modern Material Design 3 interface
🔧 **Configurable** - Adjust confidence threshold and detection settings
📱 **Cross-Platform** - Works on Android and iOS

## Architecture

The app follows a clean, layered architecture:

```
lib/
├── main.dart                      # App entry point, routing, theme
├── models/
│   └── detection.dart             # Detection and BoundingBox classes
├── services/
│   └── object_detection_service.dart  # TFLite model loading & inference
├── providers/
│   └── detection_view_model.dart  # State management with Provider
├── utils/
│   ├── permission_utils.dart      # Permission handling
│   └── detection_painter.dart     # CustomPainter for bounding boxes
└── ui/
    └── screens/
        ├── welcome_screen.dart
        ├── source_selection_screen.dart
        ├── camera_detection_screen.dart
        ├── gallery_detection_screen.dart
        └── settings_screen.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- Dart SDK (comes with Flutter)
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation

1. **Clone or open the project**
   ```bash
   cd visioassist
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Download the TFLite Model**
   
   You need to download a pre-trained SSD MobileNet TFLite model and labels file:

   - **Option A: Use SSD MobileNet v2 (Recommended)**
     - Model: https://www.tensorflow.org/lite/guide/hosted_models#object_detection
     - Download `ssd_mobilenet_v2_coco_quant.tflite`
     - Download labels file or use the COCO labels

   - **Option B: TensorFlow Hub**
     - Visit: https://tfhub.dev/google/lite-model/object_detection/mobile_ssd/1
     - Download the `.tflite` model

4. **Add Model Files**

   Create the assets directory and add your model files:

   ```bash
   mkdir -p assets/models
   ```

   Then copy your model files:
   - Place `ssd_mobilenet.tflite` → `assets/models/ssd_mobilenet.tflite`
   - Place `labels.txt` → `assets/models/labels.txt`

   **Labels file format** (one label per line):
   ```
   background
   person
   bicycle
   car
   ...
   ```

5. **Update Model Path (if needed)**

   If you use a different model filename, update `ObjectDetectionService`:

   ```dart
   // In lib/services/object_detection_service.dart
   _interpreter = await Interpreter.fromAsset('assets/models/YOUR_MODEL_NAME.tflite');
   ```

6. **Configure Platform-Specific Settings**

   **For Android:**
   - Ensure `android/app/build.gradle` has the correct SDK versions
   - No additional configuration needed for camera/gallery permissions

   **For iOS:**
   - Add camera permission to `ios/Runner/Info.plist`:
     ```xml
     <key>NSCameraUsageDescription</key>
     <string>This app needs camera access to detect objects in real-time</string>
     <key>NSPhotoLibraryUsageDescription</key>
     <string>This app needs access to your photos to detect objects</string>
     ```

### Running the App

```bash
# Run on connected device or emulator
flutter run

# Run on iOS
flutter run -d ios

# Run on Android
flutter run -d android

# Run in release mode (better performance)
flutter run --release
```

## Project Structure & Components

### Core Services

**ObjectDetectionService** (`lib/services/object_detection_service.dart`)
- Loads TFLite model once on startup
- Runs inference on static images
- Processes camera frames in real-time
- Handles image preprocessing (resize, normalization)
- Parses model outputs and applies confidence threshold
- Singleton pattern ensures model is loaded only once

### Model Classes

**Detection** & **BoundingBox** (`lib/models/detection.dart`)
- Strongly typed classes for detection results
- Normalized bounding box coordinates (0.0-1.0)
- Convenience methods for confidence formatting

### State Management

**DetectionViewModel** (`lib/providers/detection_view_model.dart`)
- Manages detection state using Provider pattern
- Handles loading, error states, and detection results
- Exposes methods for image and frame detection
- Settings management (confidence threshold, label visibility)

### UI Screens

1. **Welcome Screen** - App introduction and branding
2. **Source Selection** - Choose camera or gallery
3. **Camera Detection** - Real-time detection from camera
4. **Gallery Detection** - Detection on selected images
5. **Settings** - Model info, threshold adjustment, privacy notice

### Utilities

**PermissionUtils** - Handles camera and gallery permissions
**DetectionPainter** - Custom painter for drawing bounding boxes

## How It Works

### Model Inference Flow

1. **Initialization**: Model and labels loaded once when app starts
2. **Input**: Image resized to model's expected size (300×300 for SSD MobileNet)
3. **Preprocessing**: 
   - Pixel values normalized (divided by standard deviation)
   - Converted to expected tensor format
4. **Inference**: Model runs on normalized input
5. **Post-processing**:
   - Parse output tensors (bounding boxes, class indices, scores)
   - Apply confidence threshold filter
   - Clamp coordinates to valid range
6. **Output**: List of Detection objects with label, confidence, and box

### Camera Detection

Real-time detection runs in an image stream:
- Each camera frame is processed
- Detections are computed asynchronously
- UI updates periodically (not on every frame)
- Efficient frame throttling prevents UI lag

### Image Detection

Gallery images are processed:
- Full image is analyzed
- Progress indicator shown during inference
- Results displayed with scrollable list
- Bounding boxes drawn via CustomPainter

## Configuration

### Confidence Threshold
- Adjust in Settings screen
- Default: 50%
- Higher threshold = only very confident detections

### Labels Visibility
- Toggle in Settings screen
- Shows object class and confidence on bounding boxes

### Model Input Size
- Currently set to 300×300 for SSD MobileNet
- If using a different model, update in `ObjectDetectionService.inputSize`

## Performance Tips

- **Use Release Build**: Run with `flutter run --release` for better performance
- **Reduce Detection Frequency**: Add frame throttling for slower devices
- **Optimize Model**: Use quantized models for faster inference
- **Camera Resolution**: Medium resolution is optimal (set in CameraDetectionScreen)

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `tflite_flutter` | ^0.10.1 | TensorFlow Lite inference |
| `camera` | ^0.11.0+1 | Camera access |
| `provider` | ^6.2.0 | State management |
| `image` | ^4.1.3 | Image processing |
| `image_picker` | ^1.2.1 | Gallery access |
| `permission_handler` | ^11.4.4 | Permission management |

## Customization

### Swap Models

To use a different TFLite model:

1. Download your `.tflite` model file
2. Place it in `assets/models/`
3. Update model path in `ObjectDetectionService`:
   ```dart
   _interpreter = await Interpreter.fromAsset('assets/models/your_model.tflite');
   ```
4. Update label file path if different:
   ```dart
   final labelsData = await rootBundle.loadString('assets/models/your_labels.txt');
   ```
5. Adjust input size if needed:
   ```dart
   static const int inputSize = 320; // For example, if your model is 320×320
   ```
6. Update output tensor parsing in `_runInference()` if model output format differs

### Change App Colors

Edit `_buildTheme()` in `main.dart`:
```dart
const primaryColor = Color(0xFF7C3AED); // Change this
const secondaryColor = Color(0xFF06B6D4); // And this
```

### Add Custom Screens

1. Create new screen in `lib/ui/screens/`
2. Add route in `main.dart` `routes` map
3. Navigate with `Navigator.of(context).pushNamed('/your-route')`

## Troubleshooting

### "Model not loaded" error
- Check that `assets/models/ssd_mobilenet.tflite` exists
- Verify model path in `ObjectDetectionService`
- Ensure `pubspec.yaml` assets are correctly declared

### Camera not working
- Grant camera permission when prompted
- Check app settings if permission was denied
- Ensure device has a working camera

### Gallery not working
- Grant photo library permission
- Check app settings if permission was denied
- Ensure device has photos available

### Slow detection
- Use release build: `flutter run --release`
- Reduce camera resolution or frame processing frequency
- Use a quantized model for faster inference
- Test on a real device (emulators are slower)

### iOS build issues
- Run `flutter clean` and `flutter pub get`
- Delete `ios/Pods` directory and rebuild
- Ensure Xcode is up to date

## Learning Resources

- [Flutter Official Docs](https://flutter.dev/docs)
- [TensorFlow Lite Flutter Guide](https://www.tensorflow.org/lite/guide/flutter)
- [Provider State Management](https://pub.dev/packages/provider)
- [Camera Plugin Documentation](https://pub.dev/packages/camera)
- [SSD MobileNet Model Details](https://github.com/tensorflow/models/tree/master/research/object_detection)

## Privacy

🔒 **This app processes all images locally on your device.** No images are uploaded to any server or shared with anyone. Your data remains completely private.

## License

This project is created for educational and development purposes.

## Contributing

Feel free to fork, modify, and improve this project. Some ideas:
- Add support for different models (YOLO, EfficientDet)
- Implement video recording with detections
- Add performance metrics and FPS counter
- Support for custom model training

---

**Questions or issues?** Check the troubleshooting section or review the inline code comments for detailed explanations of the logic.

Happy detecting! 🎯

