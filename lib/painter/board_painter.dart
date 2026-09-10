import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/tool_type.dart';
import '../core/utils/curve_math.dart';

class BoardPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final List<Offset> laserTrail;
  final double scale;

  BoardPainter({
    required this.strokes,
    this.activeStroke,
    this.laserTrail = const [],
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scale != 1.0) {
      canvas.save();
      canvas.scale(scale, scale);
    }

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      _paintStroke(canvas, activeStroke!);
    }

    if (laserTrail.isNotEmpty) {
      _paintLaserTrail(canvas, laserTrail);
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

    // Geometric Shapes
    if (stroke.points.length >= 2) {
      final start = stroke.points.first.offset;
      final end = stroke.points.last.offset;

      switch (stroke.tool) {
        case ToolType.line:
          canvas.drawLine(start, end, paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        case ToolType.arrow:
          _drawArrow(canvas, start, end, paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        case ToolType.rectangle:
          final rect = Rect.fromPoints(start, end);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        case ToolType.circle:
          final rect = Rect.fromPoints(start, end);
          canvas.drawOval(rect, paint);
          _drawSelectionGlow(canvas, stroke);
          return;
        default:
          break;
      }
    }

    // Pen outer glow
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
    _drawSelectionGlow(canvas, stroke);
  }

  void _drawSelectionGlow(Canvas canvas, Stroke stroke) {
    if (!stroke.isSelected) return;

    final box = stroke.boundingBox;
    final rrect = RRect.fromRectAndRadius(box, const Radius.circular(10));

    final selectPaint = Paint()
      ..color = const Color(0xFF00FFA3).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final fillPaint = Paint()
      ..color = const Color(0xFF00FFA3).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, selectPaint);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    const double arrowSize = 14.0;
    const double arrowAngle = 25 * math.pi / 180;
    final double angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

    final arrowP1 = Offset(
      end.dx - arrowSize * math.cos(angle - arrowAngle),
      end.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    final arrowP2 = Offset(
      end.dx - arrowSize * math.cos(angle + arrowAngle),
      end.dy - arrowSize * math.sin(angle + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowP1.dx, arrowP1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowP2.dx, arrowP2.dy);

    canvas.drawPath(arrowPath, paint);
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