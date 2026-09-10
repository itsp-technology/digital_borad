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
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isMobile = size.width < 600;

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

          // 3. Top-Left Slide Drawer Button
          Positioned(
            top: 18,
            left: 14,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: InkWell(
                    onTap: controller.toggleSlideDrawer,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141721).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: controller.isSlideDrawerOpen
                              ? const Color(0xFF00FFA3)
                              : Colors.white.withValues(alpha: 0.15),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_rounded, color: Color(0xFF00FFA3), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'SLIDES (${controller.currentPageIndex + 1}/${controller.totalPages})',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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
          ),

          // 4. Responsive Floating Toolbar (Top on Desktop, Bottom on Mobile)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            top: isMobile
                ? null
                : (controller.isToolbarVisible ? 18 : -100),
            bottom: isMobile
                ? (controller.isToolbarVisible ? 44 : -120)
                : null,
            left: 0,
            right: 0,
            child: const Center(
              child: FloatingToolbar(),
            ),
          ),

          // 5. Restore Toolbar Button (Shown when auto-hidden / unpinned)
          if (!controller.isToolbarVisible)
            Positioned(
              top: isMobile ? null : 18,
              bottom: isMobile ? 44 : null,
              right: 14,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: InkWell(
                      onTap: () => controller.setToolbarVisible(true),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141721).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF00FFA3).withValues(alpha: 0.6)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF00FFA3), size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 6. Cyber Telemetry HUD (Compact on Mobile)
          Positioned(
            bottom: isMobile ? 8 : 16,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF141721).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 12, color: Color(0xFF00FFA3)),
                  const SizedBox(width: 4),
                  Text(
                    isMobile
                        ? 'P: ${controller.currentPageIndex + 1}/${controller.totalPages}'
                        : 'NovaSlate • PAGE: ${controller.currentPageIndex + 1}/${controller.totalPages} • PINNED: ${controller.isToolbarPinned ? "YES" : "AUTO-HIDE"} • POS: (${_cursorPos.dx.toInt()}, ${_cursorPos.dy.toInt()})',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF00FFA3),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Left Slide Drawer Backdrop (Tap outside to close)
          if (controller.isSlideDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.closeSlideDrawer,
                child: Container(color: Colors.black45),
              ),
            ),

          // 8. Slide Drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            left: controller.isSlideDrawerOpen ? 0 : -270,
            top: 0,
            bottom: 0,
            child: const SlideDrawer(),
          ),
        ],
      ),
    );
  }
}