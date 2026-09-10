import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../painter/board_painter.dart';
import '../../state/board_controller.dart';
import '../widgets/floating_toolbar.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BoardController>();

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: Stack(
        children: [
          Listener(
            onPointerDown: (e) => controller.startStroke(e.localPosition, e.pressure),
            onPointerMove: (e) => controller.appendPoint(e.localPosition, e.pressure),
            onPointerUp: (_) => controller.endStroke(),
            child: CustomPaint(
              painter: BoardPainter(
                strokes: controller.strokes,
                activeStroke: controller.activeStroke,
              ),
              size: Size.infinite,
            ),
          ),
          const Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingToolbar(),
            ),
          ),
        ],
      ),
    );
  }
}