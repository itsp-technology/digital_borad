import 'package:flutter/material.dart';
import '../../state/board_controller.dart';

class GridBackground extends StatelessWidget {
  final BoardThemeMode mode;
  const GridBackground({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(mode),
    );
  }
}

class _GridPainter extends CustomPainter {
  final BoardThemeMode mode;
  _GridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == BoardThemeMode.blank) return;

    final linePaint = Paint()
      ..color = const Color(0xFF1F2633)
      ..strokeWidth = 1.0;

    const double spacing = 36.0;

    if (mode == BoardThemeMode.dots) {
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.0, linePaint..color = const Color(0xFF2D3748));
        }
      }
    } else if (mode == BoardThemeMode.grid) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    } else if (mode == BoardThemeMode.lines) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.mode != mode;
}