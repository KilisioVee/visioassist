import 'package:flutter/material.dart';
import '../models/detection.dart';

/// CustomPainter for drawing detection bounding boxes and labels on images.
///
/// Takes a list of normalized detections (0.0-1.0) and draws them
/// on a canvas, scaling to the actual image dimensions.
class DetectionPainter extends CustomPainter {
  /// List of detections to draw
  final List<Detection> detections;

  /// Whether to show labels and confidence scores
  final bool showLabels;

  /// Color for the bounding boxes
  final Color boxColor;

  /// Color for the labels
  final Color labelColor;

  /// Text color for labels
  final Color textColor;

  /// Stroke width for bounding boxes
  final double strokeWidth;

  DetectionPainter({
    required this.detections,
    required this.showLabels,
    this.boxColor = Colors.cyan,
    this.labelColor = Colors.cyan,
    this.textColor = Colors.black,
    this.strokeWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw each detection
    for (final detection in detections) {
      // Get normalized coordinates
      final left = detection.box.left;
      final top = detection.box.top;
      final right = detection.box.right;
      final bottom = detection.box.bottom;

      // Convert normalized coordinates to pixel coordinates
      final paintLeft = left * size.width;
      final paintTop = top * size.height;
      final paintRight = right * size.width;
      final paintBottom = bottom * size.height;

      // Draw bounding box
      final boxPaint = Paint()
        ..color = boxColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawRect(
        Rect.fromLTRB(paintLeft, paintTop, paintRight, paintBottom),
        boxPaint,
      );

      // Draw label if enabled
      if (showLabels) {
        _drawLabel(
          canvas,
          detection.label,
          detection.confidence,
          paintLeft,
          paintTop,
          size,
        );
      }
    }
  }

  /// Draw a label and confidence score above the bounding box.
  void _drawLabel(
    Canvas canvas,
    String label,
    double confidence,
    double left,
    double top,
    Size size,
  ) {
    final labelText = '$label ${(confidence * 100).toStringAsFixed(1)}%';

    // Create text painter for the label
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);

    // Draw label background
    const labelPadding = 6.0;
    final labelRect = Rect.fromLTWH(
      left,
      top - textPainter.height - (labelPadding * 2),
      textPainter.width + (labelPadding * 2),
      textPainter.height + labelPadding,
    );

    final labelPaint = Paint()
      ..color = labelColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(labelRect, labelPaint);

    // Draw the text
    textPainter.paint(
      canvas,
      Offset(left + labelPadding, top - textPainter.height - labelPadding),
    );
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.showLabels != showLabels;
  }
}
