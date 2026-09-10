import 'dart:ui';
import 'stroke_point.dart';
import 'tool_type.dart';

class Stroke {
  final List<StrokePoint> points;
  final Color color;
  double strokeWidth;
  final ToolType tool;
  bool isSelected;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    this.isSelected = false,
  });

  // Calculate dynamic bounding box of all points
  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.offset.dx;
    double maxX = points.first.offset.dx;
    double minY = points.first.offset.dy;
    double maxY = points.first.offset.dy;

    for (final p in points) {
      if (p.offset.dx < minX) minX = p.offset.dx;
      if (p.offset.dx > maxX) maxX = p.offset.dx;
      if (p.offset.dy < minY) minY = p.offset.dy;
      if (p.offset.dy > maxY) maxY = p.offset.dy;
    }
    final pad = (strokeWidth + 12.0).clamp(14.0, 36.0);
    return Rect.fromLTRB(minX - pad, minY - pad, maxX + pad, maxY + pad);
  }

  // Generous hit test radius (32px) so touches and stylus never miss
  bool containsOffset(Offset pos) {
    if (!boundingBox.inflate(20).contains(pos)) return false;
    const threshold = 32.0;
    for (final p in points) {
      if ((p.offset - pos).distance <= threshold) {
        return true;
      }
    }
    return false;
  }

  bool intersectsRect(Rect selectionBox) {
    for (final p in points) {
      if (selectionBox.contains(p.offset)) return true;
    }
    return false;
  }

  // Move stroke by offset delta
  void translate(Offset delta) {
    for (int i = 0; i < points.length; i++) {
      points[i] = StrokePoint(
        offset: points[i].offset + delta,
        pressure: points[i].pressure,
      );
    }
  }

  // Scale (increase or decrease size) around anchor pivot (top-left of bounding box)
  void scale(double deltaWidth, double deltaHeight) {
    if (points.isEmpty) return;
    final box = boundingBox;
    final double currentWidth = box.width;
    final double currentHeight = box.height;
    if (currentWidth <= 0 || currentHeight <= 0) return;

    final double newWidth = (currentWidth + deltaWidth).clamp(24.0, 3000.0);
    final double newHeight = (currentHeight + deltaHeight).clamp(24.0, 3000.0);

    final double scaleX = newWidth / currentWidth;
    final double scaleY = newHeight / currentHeight;
    final Offset pivot = box.topLeft;

    for (int i = 0; i < points.length; i++) {
      final oldOffset = points[i].offset;
      final newDx = pivot.dx + (oldOffset.dx - pivot.dx) * scaleX;
      final newDy = pivot.dy + (oldOffset.dy - pivot.dy) * scaleY;

      points[i] = StrokePoint(
        offset: Offset(newDx, newDy),
        pressure: points[i].pressure,
      );
    }

    // Scale line thickness proportionally
    final double avgScale = (scaleX + scaleY) / 2.0;
    strokeWidth = (strokeWidth * avgScale).clamp(1.0, 48.0);
  }

  Map<String, dynamic> toMap() => {
        'pts': points.map((p) => p.toMap()).toList(),
        'c': color.toARGB32(),
        'w': strokeWidth,
        't': tool.index,
      };

  factory Stroke.fromMap(Map<String, dynamic> map) => Stroke(
        points: (map['pts'] as List)
            .map((p) => StrokePoint.fromMap(p as Map<String, dynamic>))
            .toList(),
        color: Color(map['c'] as int),
        strokeWidth: (map['w'] as num).toDouble(),
        tool: ToolType.values[map['t'] as int],
      );
}