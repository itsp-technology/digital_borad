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