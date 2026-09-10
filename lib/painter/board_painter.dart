import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/tool_type.dart';
import '../core/utils/curve_math.dart';

class BoardPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final List<Offset> laserTrail;

  BoardPainter({
    required this.strokes,
    this.activeStroke,
    this.laserTrail = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw static strokes
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    // 2. Draw live stroke
    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      _paintActiveStroke(canvas, activeStroke!);
    }

    // 3. Draw dynamic laser pointer
    if (laserTrail.isNotEmpty) {
      _paintLaserTrail(canvas, laserTrail);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.strokeWidth;

    if (stroke.tool == ToolType.highlighter) {
      paint.blendMode = BlendMode.screen;
    }

    // Outer neon bloom for pens on dark surface
    if (stroke.tool == ToolType.pen && stroke.color != const Color(0xFF0D1117)) {
      final glowPaint = Paint()
        ..color = stroke.color.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth * 2.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      _drawSmoothPath(canvas, stroke.points.map((p) => p.offset).toList(), glowPaint);
    }

    _drawSmoothPath(canvas, stroke.points.map((p) => p.offset).toList(), paint);
  }

  void _paintActiveStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.points.map((p) => p.offset).toList();
    if (points.length >= 2) {
      final pLast = points.last;
      final pPrev = points[points.length - 2];
      points.add(pLast + ((pLast - pPrev) * 1.2)); // Velocity forward prediction
    }

    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.strokeWidth;

    if (stroke.tool == ToolType.highlighter) {
      paint.blendMode = BlendMode.screen;
    }

    _drawSmoothPath(canvas, points, paint);
  }

  void _paintLaserTrail(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final laserGlow = Paint()
      ..color = const Color(0xFFFF0055).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final laserCore = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, laserGlow);
    canvas.drawPath(path, laserCore);
    canvas.drawCircle(points.last, 6.0, Paint()..color = const Color(0xFFFF0055));
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.length == 1) {
      canvas.drawCircle(offsets[0], paint.strokeWidth / 2.0, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path()..moveTo(offsets[0].dx, offsets[0].dy);
    if (offsets.length == 2) {
      path.lineTo(offsets[1].dx, offsets[1].dy);
    } else {
      path.lineTo((offsets[0].dx + offsets[1].dx) / 2, (offsets[0].dy + offsets[1].dy) / 2);
      for (int i = 1; i < offsets.length - 1; i++) {
        final mid = CurveMath.computeMidpoint(offsets[i], offsets[i + 1]);
        path.quadraticBezierTo(offsets[i].dx, offsets[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(offsets.last.dx, offsets.last.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}