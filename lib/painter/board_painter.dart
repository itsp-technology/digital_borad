import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/tool_type.dart';
import '../core/utils/curve_math.dart';

class BoardPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? activeStroke;

  BoardPainter({
    required this.strokes,
    this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (activeStroke != null) {
      _paintStroke(canvas, activeStroke!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Single point / tap
    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      paint.style = PaintingStyle.fill;
      final radius = (stroke.strokeWidth * p.pressure) / 2.0;
      canvas.drawCircle(p.offset, radius.clamp(1.0, 50.0), paint);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points[0].offset.dx, stroke.points[0].offset.dy);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      final mid = CurveMath.computeMidpoint(p0.offset, p1.offset);

      final dynamicWidth = stroke.tool == ToolType.highlighter
          ? stroke.strokeWidth * 2.5
          : stroke.strokeWidth * (p0.pressure * 2.0).clamp(0.5, 3.0);

      paint.strokeWidth = dynamicWidth;
      path.quadraticBezierTo(p0.offset.dx, p0.offset.dy, mid.dx, mid.dy);
    }

    final last = stroke.points.last;
    path.lineTo(last.offset.dx, last.offset.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}