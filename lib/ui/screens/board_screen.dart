import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../painter/board_painter.dart';
import '../../state/board_controller.dart';
import '../widgets/floating_toolbar.dart';
import '../widgets/grid_background.dart';
import '../widgets/slide_drawer.dart';

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
    final size = MediaQuery.of(context).size;

    // Register active viewport dimensions for accurate preview scaling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateScreenSize(size);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // 1. Grid / Dots / Lines Background
          GridBackground(mode: controller.themeMode),

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
                laserTrail: controller.laserTrail,
              ),
              size: Size.infinite,
            ),
          ),

          // 3. Top-Left Slide Drawer Opener Pill
          Positioned(
            top: 24,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: InkWell(
                  onTap: controller.toggleSlideDrawer,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141721).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: controller.isSlideDrawerOpen
                            ? const Color(0xFF00FFA3)
                            : Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, color: Color(0xFF00FFA3), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'SLIDES (${controller.currentPageIndex + 1}/${controller.totalPages})',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Centered Floating Toolbar (Animated Hide / Show for Focus Mode)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            top: controller.isToolbarVisible ? 24 : -100,
            left: 0,
            right: 0,
            child: const Center(
              child: FloatingToolbar(),
            ),
          ),

          // 5. Restore Toolbar Button (Shown when auto-hidden / unpinned)
          if (!controller.isToolbarVisible)
            Positioned(
              top: 24,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: InkWell(
                    onTap: () => controller.setToolbarVisible(true),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141721).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00FFA3).withValues(alpha: 0.6)),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF00FFA3), size: 20),
                    ),
                  ),
                ),
              ),
            ),

          // 6. Telemetry Status Bar
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
                    'NovaSlate • PAGE: ${controller.currentPageIndex + 1}/${controller.totalPages} • PINNED: ${controller.isToolbarPinned ? "YES" : "AUTO-HIDE"} • POS: (${_cursorPos.dx.toInt()}, ${_cursorPos.dy.toInt()})',
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

          // 7. Left Slide Drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            left: controller.isSlideDrawerOpen ? 0 : -260,
            top: 0,
            bottom: 0,
            child: const SlideDrawer(),
          ),
        ],
      ),
    );
  }
}