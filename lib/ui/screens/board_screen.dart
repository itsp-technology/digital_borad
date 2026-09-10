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
          // 1. Dynamic background grid
          GridBackground(mode: controller.themeMode),

          // 2. Main low-latency inking canvas
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
                laserTrail: controller.laserTrail,
              ),
              size: Size.infinite,
            ),
          ),

          // 3. Cyber Telemetry Status Bar
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF141721).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 14, color: Color(0xFF00FFA3)),
                  const SizedBox(width: 6),
                  Text(
                    'NovaSlate • LATENCY: ~0ms • POS: (${_cursorPos.dx.toInt()}, ${_cursorPos.dy.toInt()}) • MODE: ${controller.themeMode.name.toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF00FFA3),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Centered Floating Acrylic Dock
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