📋 TFLite MODEL CONFIGURATION GUIDE
====================================

This guide explains how to add and configure different TensorFlow Lite object detection models.

📥 OBTAINING MODELS
===================

1. TensorFlow Lite - Official Hosted Models
   https://www.tensorflow.org/lite/guide/hosted_models

   Popular models:
   • SSD MobileNet v2 (Recommended for mobile)
   • EfficientDet
   • YOLOv4 (TFLite)

2. TensorFlow Hub
   https://tfhub.dev/

   Search for: "lite object detection mobile"

3. MediaPipe
   https://mediapipe.dev/solutions/objectron/

   Pre-built object detection solutions

🔧 SETTING UP A MODEL
======================

STEP 1: Download Model
-----------------------
• Download .tflite file (usually 30-100MB)
• Extract if it's in a ZIP file
• Verify file integrity

STEP 2: Add to Project
----------------------
```bash
# Create assets/models if needed
mkdir -p assets/models

# Copy your model
cp your_model.tflite assets/models/ssd_mobilenet.tflite
```

STEP 3: Create or Get Labels
-----------------------------
Labels are dataset-specific. Common options:

A) COCO Dataset (80 classes)
   Already provided in: assets/models/labels.txt
   Use if your model is COCO-trained

B) Pascal VOC (20 classes)
   Example: person, car, dog, cat, bird, etc.

C) Custom Dataset
   Create labels.txt with one label per line

STEP 4: Update Model Path
--------------------------
File: lib/services/object_detection_service.dart

Find this line in loadModel():
```dart
_interpreter = await Interpreter.fromAsset('assets/models/ssd_mobilenet.tflite');
```

Update to your model filename:
```dart
_interpreter = await Interpreter.fromAsset('assets/models/YOUR_MODEL.tflite');
```

STEP 5: Update Labels Path (if different)
------------------------------------------
In same file, find:
```dart
final labelsData = await rootBundle.loadString('assets/models/labels.txt');
```

Update if needed:
```dart
final labelsData = await rootBundle.loadString('assets/models/YOUR_LABELS.txt');
```

STEP 6: Update Input Size (if needed)
--------------------------------------
Find in ObjectDetectionService:
```dart
static const int inputSize = 300;  // For 300x300 input
```

Change based on your model:
• SSD MobileNet: 300
• EfficientDet: varies (320, 512, etc.)
• YOLO: varies (416, 608, etc.)

STEP 7: Update Output Tensor Parsing (if needed)
------------------------------------------------
Find in _runInference() method:

Default assumes:
- outputBoxes: [1, numResults, 4] - normalized coords
- outputClasses: [1, numResults] - class indices
- outputScores: [1, numResults] - confidence scores
- numDetections: [1] - count

If your model outputs differently:
```dart
// Adjust output buffer sizes
final output = <List<List<double>>>[
  List.filled(YOUR_NUM_RESULTS, List.filled(4, 0.0))
];
// ... update parsing accordingly
```

⚙️ COMMON MODELS CONFIGURATION
===============================

1. SSD MobileNet v2 (RECOMMENDED)
   ═══════════════════════════════════════════════════════════
   Download: TFLite Hosted Models page
   Input Size: 300×300
   Output Format: Boxes, Classes, Scores, NumDetections
   Dataset: COCO
   Speed: ~200-400ms per frame
   Accuracy: Good balance
   
   Setup:
   - Filename: ssd_mobilenet.tflite
   - Input size: 300
   - Use default output parsing
   - Use provided labels.txt

2. EfficientDet (Faster)
   ═══════════════════════════════════════════════════════════
   Download: TensorFlow Hub
   Input Size: 320×320 or 512×512
   Output Format: Vary - check model documentation
   Dataset: COCO
   Speed: ~100-300ms per frame
   Accuracy: High accuracy
   
   Setup:
   - Update inputSize to 320 or 512
   - May need custom output parsing
   - Use COCO labels.txt

3. YOLO v4 (TFLite)
   ═══════════════════════════════════════════════════════════
   Download: https://github.com/hunglc007/tensorflow-yolov4-tflite
   Input Size: 416×416
   Output Format: Different from SSD (single output tensor)
   Dataset: COCO
   Speed: Varies with variant
   Accuracy: Very high
   
   Setup:
   - Update inputSize to 416
   - MUST update output tensor parsing
   - Use COCO labels.txt
   - May need custom post-processing (NMS)

4. MediaPipe Object Detection
   ═══════════════════════════════════════════════════════════
   Download: https://mediapipe.dev/
   Input Size: Varies
   Output Format: Custom
   Speed: Very fast
   
   Setup:
   - May need MediaPipe plugin
   - Or wrap MediaPipe model in custom service
   - Check MediaPipe documentation for output format

📊 MODEL COMPARISON
===================

╔═════════════════════╦═════════════╦══════════════╦═══════════════╗
║ Model               ║ Input Size  ║ Speed (fps)  ║ Accuracy      ║
╠═════════════════════╬═════════════╬══════════════╬═══════════════╣
║ SSD MobileNet v2    ║ 300×300     ║ 5-10         ║ Good          ║
║ EfficientDet        ║ 320/512×... ║ 10-25        ║ Very Good     ║
║ YOLO v4 TFLite      ║ 416×416     ║ 8-15         ║ Excellent     ║
║ MediaPipe Object Det║ Varies      ║ 25-40        ║ Good          ║
╚═════════════════════╩═════════════╩══════════════╩═══════════════╝

🎯 CHOOSING A MODEL
===================

Use SSD MobileNet if:
✓ You want simple setup
✓ You need good accuracy
✓ Medium speed is acceptable
✓ You're just getting started

Use EfficientDet if:
✓ You want better accuracy
✓ You want faster speed
✓ You don't mind custom output parsing
✓ You have good device performance

Use YOLO if:
✓ You want maximum accuracy
✓ You want fastest speed
✓ You're willing to implement custom parsing
✓ You need state-of-the-art performance

Use MediaPipe if:
✓ You want easiest setup
✓ You want highest speed
✓ You can use their API
✓ You need pre-optimized solution

🏃 PERFORMANCE TUNING
====================

To speed up detection:

1. Use quantized models (smaller, faster)
   - ssd_mobilenet_v2_coco_quant.tflite (faster)
   - vs regular model

2. Reduce input resolution
   ```dart
   static const int inputSize = 224;  // Smaller = faster
   ```

3. Use GPU acceleration (advanced)
   - Requires additional setup
   - Check tflite_flutter docs

4. Increase confidence threshold
   - Fewer boxes to process
   - Less post-processing

5. Throttle frame processing
   - Skip some frames in real-time detection
   - Example: Process every 3rd frame

🔍 VERIFYING YOUR SETUP
=======================

After adding a model, test with:

1. Check model loads
   ```dart
   if (viewModel.isModelLoaded) {
     print('✓ Model loaded');
   } else {
     print('✗ Model failed to load');
   }
   ```

2. Check labels loaded
   ```dart
   print('Labels: ${viewModel.detectionService.labels.length}');
   ```

3. Run detection on test image
   ```dart
   final results = await viewModel.detectOnImage(testImageFile);
   print('Detections: ${results.length}');
   ```

4. Verify output format
   ```dart
   for (var det in results) {
     print('${det.label}: ${det.confidence}');
   }
   ```

❌ TROUBLESHOOTING
==================

Issue: "Model file not found"
Solution: 
  - Check file path is correct
  - Verify file exists in assets/models/
  - Check pubspec.yaml assets declaration

Issue: "Unexpected output tensor format"
Solution:
  - Print actual tensor shapes in _runInference()
  - Update output buffer creation
  - Check model's official documentation

Issue: "All detections are wrong class"
Solution:
  - Verify labels.txt is correct
  - Check label file has correct order
  - Ensure training dataset matches labels

Issue: "Detection is too slow"
Solution:
  - Use quantized model
  - Reduce input size
  - Increase confidence threshold
  - Use release build: flutter run --release

Issue: "No detections found"
Solution:
  - Lower confidence threshold
  - Check image quality
  - Verify model is working (test with official tool)
  - Check input preprocessing is correct

🔗 RESOURCES
============

TensorFlow Lite Models:
  https://www.tensorflow.org/lite/guide/hosted_models

TensorFlow Hub:
  https://tfhub.dev/

SSD MobileNet Details:
  https://arxiv.org/abs/1704.04861

EfficientDet Paper:
  https://arxiv.org/abs/1911.02579

YOLOv4 Details:
  https://arxiv.org/abs/2004.10934

Model Optimization:
  https://www.tensorflow.org/lite/optimize

════════════════════════════════════════════════════════════

Remember: Different models may require adjustments to 
input/output processing. Always check your model's 
documentation!

Happy detecting! 🎯
