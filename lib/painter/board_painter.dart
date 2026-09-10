import 'dart:ui';
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
    // 1. Paint confirmed strokes
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    // 2. Paint current active stroke with prediction
    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      _paintActiveStrokeWithPrediction(canvas, activeStroke!);
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
    } else {
      paint.blendMode = BlendMode.srcOver;
    }

    // Neon Outer Halo for futuristic feel (skip for eraser)
    if (stroke.tool == ToolType.pen && stroke.color != const Color(0xFF1E1E1E)) {
      final glowPaint = Paint()
        ..color = stroke.color.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth * 2.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      _drawSmoothPath(canvas, stroke.points.map((p) => p.offset).toList(), glowPaint);
    }

    _drawSmoothPath(canvas, stroke.points.map((p) => p.offset).toList(), paint);
  }

  void _paintActiveStrokeWithPrediction(Canvas canvas, Stroke stroke) {
    final points = stroke.points.map((p) => p.offset).toList();

    // Latency eliminator: Predict where stylus will land next based on velocity vector
    if (points.length >= 2) {
      final pLast = points.last;
      final pPrev = points[points.length - 2];
      final delta = pLast - pPrev;

      // Predict 1.2x ahead of current trajectory
      final predictedPoint = pLast + (delta * 1.2);
      points.add(predictedPoint);
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

  void _drawSmoothPath(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.length == 1) {
      canvas.drawCircle(offsets[0], paint.strokeWidth / 2.0, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    if (offsets.length == 2) {
      path.lineTo(offsets[1].dx, offsets[1].dy);
    } else {
      path.lineTo(
        (offsets[0].dx + offsets[1].dx) / 2.0,
        (offsets[0].dy + offsets[1].dy) / 2.0,
      );

      for (int i = 1; i < offsets.length - 1; i++) {
        final current = offsets[i];
        final next = offsets[i + 1];
        final mid = CurveMath.computeMidpoint(current, next);
        path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
      }

      path.lineTo(offsets.last.dx, offsets.last.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}