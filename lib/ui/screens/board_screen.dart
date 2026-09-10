import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../painter/board_painter.dart';
import '../../state/board_controller.dart';
import '../widgets/floating_toolbar.dart';
import '../widgets/grid_background.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  Offset _cursorPos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BoardController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // 1. Futuristic Vector Dot Grid
          const GridBackground(),

          // 2. High-speed Inking Surface
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              setState(() => _cursorPos = e.localPosition);
              controller.startStroke(e.localPosition, e.pressure);
            },
            onPointerMove: (e) {
              setState(() => _cursorPos = e.localPosition);
              controller.appendPoint(e.localPosition, e.pressure);
            },
            onPointerUp: (_) => controller.endStroke(),
            child: CustomPaint(
              painter: BoardPainter(
                strokes: controller.strokes,
                activeStroke: controller.activeStroke,
              ),
              size: Size.infinite,
            ),
          ),

          // 3. Cyber HUD Telemetry (Shows current stylus coordinates & latency tracker)
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'X: ${_cursorPos.dx.toInt()} | Y: ${_cursorPos.dy.toInt()}  •  ENGINE: GPU-IMPELLER',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF00FFA3),
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),

          // 4. Centered Frosted Glass Tool Dock
          const Positioned(
            top: 24,
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