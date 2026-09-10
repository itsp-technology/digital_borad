import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/utils/rough_math.dart';
import '../models/stroke.dart';
import '../models/tool_type.dart';
import '../core/utils/curve_math.dart';

class BoardPainter extends CustomPainter {
  final List<Stroke> strokes;
  final double scale;

  const BoardPainter({
    required this.strokes,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scale != 1.0) {
      canvas.save();
      canvas.scale(scale, scale);
    }

    for (int i = 0; i < strokes.length; i++) {
      _paintStroke(canvas, strokes[i]);
    }

    if (scale != 1.0) {
      canvas.restore();
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

    // Excalidraw-Style Hand-Drawn Geometric Shapes
    if (stroke.points.length >= 2) {
      final start = stroke.points.first.offset;
      final end = stroke.points.last.offset;

      switch (stroke.tool) {
        case ToolType.line:
          canvas.drawPath(RoughMath.roughLine(start, end), paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        case ToolType.arrow:
          canvas.drawPath(RoughMath.roughArrow(start, end), paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        case ToolType.rectangle:
          final rect = Rect.fromPoints(start, end);
          canvas.drawPath(RoughMath.roughRect(rect), paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        case ToolType.circle:
          final rect = Rect.fromPoints(start, end);
          canvas.drawPath(RoughMath.roughEllipse(rect), paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        default:
          break;
      }
    }

    // Freehand Pen with smoothing
    if (stroke.tool == ToolType.pen && stroke.color != const Color(0xFF0D1117)) {
      final glowPaint = Paint()
        ..color = stroke.color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth * 1.8;
      _drawSmoothPath(canvas, stroke.points.map((p) => p.offset).toList(), glowPaint);
    }

    _drawSmoothPath(canvas, stroke.points.map((p) => p.offset).toList(), paint);
    _drawSelectionGlow(canvas, stroke);
  }

  void _drawSelectionGlow(Canvas canvas, Stroke stroke) {
    if (!stroke.isSelected) return;

    final box = stroke.boundingBox;
    final rrect = RRect.fromRectAndRadius(box, const Radius.circular(8));

    final selectPaint = Paint()
      ..color = const Color(0xFF6965DB) // Excalidraw accent indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = const Color(0xFF6965DB).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, selectPaint);
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
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.scale != scale;
  }
}