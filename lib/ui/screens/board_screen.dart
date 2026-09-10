import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../models/tool_type.dart';
import '../../painter/board_painter.dart';
import '../../state/board_controller.dart';
import '../widgets/floating_toolbar.dart';
import '../widgets/grid_background.dart';
import '../widgets/interactive_image_widget.dart';
import '../widgets/slide_drawer.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  Offset _cursorPos = Offset.zero;

  Future<void> _exportSlide() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF141721),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00FFA3)),
                const SizedBox(width: 8),
                Text(
                  'Slide ${context.read<BoardController>().currentPageIndex + 1} exported successfully!',
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BoardController>();
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isMobile = size.width < 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateScreenSize(size);
    });

    final bool isSelectMode = controller.currentTool == ToolType.select;
    final selectedStroke = controller.selectedStroke;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // 1. Exportable Board Canvas
          RepaintBoundary(
            key: _canvasKey,
            child: InteractiveViewer(
              transformationController: _transformController,
              panEnabled: false,
              scaleEnabled: isSelectMode && selectedStroke == null,
              minScale: 0.5,
              maxScale: 4.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GridBackground(mode: controller.themeMode),

                  // Resizable & Movable Images
                  ...controller.currentImages.asMap().entries.map(
                        (entry) => InteractiveImageWidget(
                          image: entry.value,
                          index: entry.key,
                        ),
                      ),

                  // Drawing Canvas & Stroke Gesture Layer
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      if (isSelectMode) {
                        controller.selectStrokeAt(details.localPosition);
                      }
                    },
                    onPanUpdate: (details) {
                      if (isSelectMode && selectedStroke != null) {
                        controller.moveSelectedStroke(details.delta);
                      }
                    },
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (e) {
                        setState(() => _cursorPos = e.localPosition);
                        controller.startStroke(e.localPosition, e.pressure, e.kind);
                      },
                      onPointerMove: (e) {
                        setState(() => _cursorPos = e.localPosition);
                        controller.appendPoint(e.localPosition, e.pressure, e.kind);
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
                  ),

                  // Selected Drawing: Touchscreen Corner Resize Handle (Bottom-Right)
                  if (isSelectMode && selectedStroke != null)
                    Positioned(
                      left: selectedStroke.boundingBox.right - 14,
                      top: selectedStroke.boundingBox.bottom - 14,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          controller.resizeSelectedStroke(details.delta.dx, details.delta.dy);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FFA3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                            Icons.aspect_ratio_rounded,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                  // Selected Drawing: Delete Button (Top-Right)
                  if (isSelectMode && selectedStroke != null)
                    Positioned(
                      left: selectedStroke.boundingBox.right - 14,
                      top: selectedStroke.boundingBox.top - 18,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: controller.deleteSelectedStroke,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3366),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Top-Left Slide Drawer Button
          Positioned(
            top: isMobile ? 12 : 18,
            left: 14,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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

          // 3. Floating Toolbar (Desktop Top, Mobile Bottom)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            top: isMobile ? null : (controller.isToolbarVisible ? 18 : -100),
            bottom: isMobile ? (controller.isToolbarVisible ? 38 : -120) : null,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingToolbar(onExport: _exportSlide),
            ),
          ),

          // 4. Restore Toolbar Button (Shown when auto-hidden)
          if (!controller.isToolbarVisible)
            Positioned(
              top: isMobile ? null : 18,
              bottom: isMobile ? 38 : null,
              right: 14,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
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

          // 5. Telemetry Status Bar
          Positioned(
            bottom: isMobile ? 6 : 16,
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
                        ? 'P: ${controller.currentPageIndex + 1}/${controller.totalPages} • ${controller.currentTool.name.toUpperCase()}'
                        : 'NovaSlate • PAGE: ${controller.currentPageIndex + 1}/${controller.totalPages} • MODE: ${controller.currentTool.name.toUpperCase()} • POS: (${_cursorPos.dx.toInt()}, ${_cursorPos.dy.toInt()})',
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

          // 6. Slide Drawer Backdrop & Animated Drawer
          if (controller.isSlideDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.closeSlideDrawer,
                child: Container(color: Colors.black45),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            left: controller.isSlideDrawerOpen ? 0.0 : -(isMobile ? size.width : 270.0),
            top: 0.0,
            bottom: 0.0,
            child: const SlideDrawer(),
          ),
        ],
      ),
    );
  }
}