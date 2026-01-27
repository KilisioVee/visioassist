/// Represents a bounding box for an object detection result.
///
/// Coordinates are normalized (0.0 to 1.0) relative to the image dimensions.
class BoundingBox {
  /// Left edge normalized coordinate (0.0 to 1.0)
  final double left;

  /// Top edge normalized coordinate (0.0 to 1.0)
  final double top;

  /// Right edge normalized coordinate (0.0 to 1.0)
  final double right;

  /// Bottom edge normalized coordinate (0.0 to 1.0)
  final double bottom;

  BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Calculate the width of the bounding box (normalized).
  double get width => right - left;

  /// Calculate the height of the bounding box (normalized).
  double get height => bottom - top;

  /// Get center X coordinate (normalized).
  double get centerX => (left + right) / 2;

  /// Get center Y coordinate (normalized).
  double get centerY => (top + bottom) / 2;

  @override
  String toString() =>
      'BoundingBox(left: $left, top: $top, right: $right, bottom: $bottom)';
}

/// Represents a single object detection result.
///
/// Contains the detected object's label, confidence score, and bounding box.
class Detection {
  /// The detected object class label (e.g., "person", "car", "dog").
  final String label;

  /// Confidence score for this detection (0.0 to 1.0).
  /// Higher values indicate more confident predictions.
  final double confidence;

  /// Bounding box coordinates (normalized to 0.0-1.0).
  final BoundingBox box;

  Detection({
    required this.label,
    required this.confidence,
    required this.box,
  });

  /// Format confidence as a percentage string.
  String get confidenceString => '${(confidence * 100).toStringAsFixed(1)}%';

  @override
  String toString() =>
      'Detection(label: $label, confidence: $confidence, box: $box)';
}
