import 'dart:io';
import 'package:flutter/material.dart';
import 'package:visioassist/utils/single_detection_painter.dart';
import '../../models/detection.dart';

class DetectionPreviewScreen extends StatelessWidget {
  final File imageFile;
  final Detection detection;

  const DetectionPreviewScreen({
    super.key,
    required this.imageFile,
    required this.detection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(detection.label),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
                CustomPaint(
                  painter: SingleDetectionPainter(detection: detection),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}