import 'package:flutter/material.dart';
import '../../models/detection.dart';

class SingleDetectionPainter extends CustomPainter {
  final Detection detection;

  SingleDetectionPainter({required this.detection});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final box = detection.box;

    final rect = Rect.fromLTRB(
      box.left * size.width,
      box.top * size.height,
      box.right * size.width,
      box.bottom * size.height,
    );

    canvas.drawRect(rect, paint);

    final labelPainter = TextPainter(
      text: TextSpan(
        text: detection.label,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(
        rect.left,
        rect.top > 20 ? rect.top - 20 : rect.top + 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant SingleDetectionPainter oldDelegate) {
    return oldDelegate.detection != detection;
  }
}