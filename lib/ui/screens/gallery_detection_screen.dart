import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/detection.dart';
import '../../providers/detection_view_model.dart';
import '../../utils/permission_utils.dart';
import '../../utils/detection_painter.dart';
import '../../utils/selected_detection_painter.dart';

/// Screen for detecting objects in images from the gallery.
///
/// Allows user to pick an image, runs detection, and displays
/// results with bounding boxes overlaid on the image.
class GalleryDetectionScreen extends StatefulWidget {
  const GalleryDetectionScreen({super.key});

  @override
  State<GalleryDetectionScreen> createState() => _GalleryDetectionScreenState();
}

class _GalleryDetectionScreenState extends State<GalleryDetectionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _showPermissionError = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPhotoPermission = await PermissionUtils.hasPhotosPermission();
    if (!hasPhotoPermission) {
      final granted = await PermissionUtils.requestPhotosPermission();
      if (!granted) {
        setState(() {
          _showPermissionError = true;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile;
      });

      // Run detection
      final viewModel = context.read<DetectionViewModel>();
      await viewModel.detectOnImage(imageFile);
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  void _pickAnotherImage() {
    setState(() {
      _selectedImage = null;
    });
    final viewModel = context.read<DetectionViewModel>();
    viewModel.reset();
    _pickImage();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  void _openDetectionPreview(Detection detection) {
    if (_selectedImage == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetectionPreviewScreen(
          imageFile: _selectedImage!,
          detection: detection,
        ),
      ),
    );
  }  @override
  Widget build(BuildContext context) {
    if (_showPermissionError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gallery Detection'),
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
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gallery Permission Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app needs access to your photos. Please enable it in app settings.',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery Detection'),
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
      body: _selectedImage == null
          ? _buildImagePickerView()
          : _buildDetectionResultsView(),
    );
  }

  /// Build the initial image picker view
  Widget _buildImagePickerView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pick an Image',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Select a photo from your gallery to detect objects',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose from Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the detection results view with image and detections
  Widget _buildDetectionResultsView() {
    return Consumer<DetectionViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 320,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                        if (!viewModel.isDetecting)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DetectionPainter(
                                detections: viewModel.detections,
                                showLabels: viewModel.showLabels,
                              ),
                            ),
                          ),
                        if (viewModel.isDetecting)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (viewModel.detections.isNotEmpty && !viewModel.isDetecting)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Objects',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: viewModel.detections.length,
                        itemBuilder: (context, index) {
                          final detection = viewModel.detections[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _openDetectionPreview(detection),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.deepPurple.withOpacity(0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          detection.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Box: (${(detection.box.left * 100).toStringAsFixed(1)}%, '
                                              '${(detection.box.top * 100).toStringAsFixed(1)}%)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      detection.confidenceString,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              if (viewModel.detections.isEmpty &&
                  !viewModel.isDetecting &&
                  viewModel.errorMessage == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.amber),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No objects detected in this image',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _pickAnotherImage,
                    icon: const Icon(Icons.image_search),
                    label: const Text('Pick Another Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }}
