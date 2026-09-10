import 'dart:ui';
import 'stroke_point.dart';
import 'tool_type.dart';

class Stroke {
  final List<StrokePoint> points;
  final Color color;
  final double strokeWidth;
  final ToolType tool;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });
}