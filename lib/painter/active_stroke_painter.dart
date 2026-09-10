import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/tool_type.dart';
import '../core/utils/curve_math.dart';

class ActiveStrokePainter extends CustomPainter {
  final Stroke? activeStroke;
  final List<Offset> laserTrail;

  ActiveStrokePainter({
    required this.activeStroke,
    this.laserTrail = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      final stroke = activeStroke!;
      final points = stroke.points.map((p) => p.offset).toList();

      final paint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth;

      if (stroke.tool == ToolType.highlighter) {
        paint.blendMode = BlendMode.screen;
      }

      // Fast preview for geometric shapes
      if (stroke.points.length >= 2 && _isShape(stroke.tool)) {
        final start = stroke.points.first.offset;
        final end = stroke.points.last.offset;

        switch (stroke.tool) {
          case ToolType.line:
            canvas.drawLine(start, end, paint);
            return;
          case ToolType.arrow:
            canvas.drawLine(start, end, paint);
            return;
          case ToolType.rectangle:
            canvas.drawRect(Rect.fromPoints(start, end), paint);
            return;
          case ToolType.circle:
            canvas.drawOval(Rect.fromPoints(start, end), paint);
            return;
          default:
            break;
        }
      }

      // Zero-latency smooth incremental curve
      if (points.length == 1) {
        canvas.drawCircle(points[0], stroke.strokeWidth / 2.0, paint..style = PaintingStyle.fill);
      } else if (points.length == 2) {
        canvas.drawLine(points[0], points[1], paint);
      } else {
        final path = Path()..moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length - 1; i++) {
          final mid = CurveMath.computeMidpoint(points[i], points[i + 1]);
          path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
        }
        path.lineTo(points.last.dx, points.last.dy);
        canvas.drawPath(path, paint);
      }
    }

    if (laserTrail.isNotEmpty) {
      _paintLaserTrail(canvas, laserTrail);
    }
  }

  bool _isShape(ToolType tool) =>
      tool == ToolType.line ||
      tool == ToolType.arrow ||
      tool == ToolType.rectangle ||
      tool == ToolType.circle;

  void _paintLaserTrail(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;
    final laserGlow = Paint()
      ..color = const Color(0xFFFF0055).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0;

    final laserCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, laserGlow);
    canvas.drawPath(path, laserCore);
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) => true;
}