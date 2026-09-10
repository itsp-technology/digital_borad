import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../models/stroke.dart';
import '../../models/tool_type.dart';
import '../../painter/active_stroke_painter.dart';
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
  Offset? _selectionStartPos;

  Future<void> _exportSlide() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF232329),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF6965DB)),
                const SizedBox(width: 8),
                Text(
                  'Slide ${context.read<BoardController>().currentPageIndex + 1} exported to PNG!',
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
    final selectedImage = controller.selectedImage;
    final bool hasSelection = selectedStroke != null || selectedImage != null;

    // Determine current active selection bounding box
    Rect? activeBox;
    if (selectedStroke != null) {
      activeBox = selectedStroke.boundingBox;
    } else if (selectedImage != null) {
      activeBox = Rect.fromLTWH(selectedImage.position.dx, selectedImage.position.dy, selectedImage.width, selectedImage.height);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. Canvas Viewport
          RepaintBoundary(
            key: _canvasKey,
            child: InteractiveViewer(
              transformationController: _transformController,
              panEnabled: isSelectMode && !hasSelection,
              scaleEnabled: isSelectMode && !hasSelection,
              minScale: 0.2,
              maxScale: 5.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GridBackground(mode: controller.themeMode),

                  // Background PDF & Images Layer
                  RepaintBoundary(
                    child: Stack(
                      fit: StackFit.expand,
                      children: controller.currentImages.asMap().entries.map(
                        (entry) => InteractiveImageWidget(
                          image: entry.value,
                          index: entry.key,
                        ),
                      ).toList(),
                    ),
                  ),

                  // Layer A: Committed Strokes (Cached)
                  RepaintBoundary(
                    child: CustomPaint(
                      isComplex: true,
                      willChange: false,
                      painter: BoardPainter(strokes: controller.strokes),
                      size: Size.infinite,
                    ),
                  ),

                  // Layer B: Transient Active Ink
                  RepaintBoundary(
                    child: ValueListenableBuilder<Stroke?>(
                      valueListenable: controller.activeStrokeNotifier,
                      builder: (context, activeStroke, _) {
                        return ValueListenableBuilder<List<Offset>>(
                          valueListenable: controller.laserTrailNotifier,
                          builder: (context, laserTrail, _) {
                            return CustomPaint(
                              isComplex: false,
                              willChange: true,
                              painter: ActiveStrokePainter(
                                activeStroke: activeStroke,
                                laserTrail: laserTrail,
                              ),
                              size: Size.infinite,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Layer C: Selection Marquee Box (Futuristic Rubberband Lasso)
                  ValueListenableBuilder<Rect?>(
                    valueListenable: controller.selectionMarqueeNotifier,
                    builder: (context, marquee, _) {
                      if (marquee == null) return const SizedBox.shrink();
                      return CustomPaint(
                        painter: _MarqueePainter(rect: marquee),
                        size: Size.infinite,
                      );
                    },
                  ),

                  // Gesture Layer (Supports Marquee Drag & Direct Element Translation)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      if (isSelectMode) {
                        if (hasSelection && activeBox != null && activeBox.contains(details.localPosition)) {
                          _selectionStartPos = null; // Dragging the selected element directly
                        } else {
                          _selectionStartPos = details.localPosition;
                          controller.startSelection(details.localPosition);
                        }
                      }
                    },
                    onPanUpdate: (details) {
                      if (isSelectMode) {
                        if (_selectionStartPos != null) {
                          controller.updateSelectionMarquee(_selectionStartPos!, details.localPosition);
                        } else if (hasSelection) {
                          controller.moveSelectedElement(details.delta);
                        }
                      }
                    },
                    onPanEnd: (details) {
                      if (isSelectMode && _selectionStartPos != null) {
                        final rect = controller.selectionMarqueeNotifier.value;
                        if (rect != null) {
                          controller.finalizeSelectionMarquee(rect);
                        }
                        _selectionStartPos = null;
                      }
                    },
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (e) {
                        setState(() => _cursorPos = e.localPosition);
                        controller.startStroke(e.localPosition, e.pressure, e.kind);
                      },
                      onPointerMove: (e) {
                        controller.appendPoint(e.localPosition, e.pressure, e.kind);
                      },
                      onPointerUp: (_) => controller.endStroke(),
                      child: Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),

                  // Universal Selection Box Handles (Works for both Ink & PDF/Images)
                  if (isSelectMode && hasSelection && activeBox != null) ...[
                    // Bottom-Right Corner Resize Handle
                    Positioned(
                      left: activeBox.right - 12,
                      top: activeBox.bottom - 12,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          controller.resizeSelectedElement(details.delta.dx, details.delta.dy);
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF6965DB), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.aspect_ratio_rounded, size: 12, color: Color(0xFF6965DB)),
                        ),
                      ),
                    ),

                    // Top-Right Corner Delete Handle
                    Positioned(
                      left: activeBox.right - 12,
                      top: activeBox.top - 28,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: controller.deleteSelectedElement,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF232329),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFFF5252)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 2. Top-Left Slide Deck Button
          Positioned(
            top: isMobile ? 12 : 18,
            left: 14,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: InkWell(
                    onTap: controller.toggleSlideDrawer,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232329).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.isSlideDrawerOpen
                              ? const Color(0xFF6965DB)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_outlined, color: Color(0xFF6965DB), size: 16),
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

          // 4. Restore Toolbar Button (When hidden)
          if (!controller.isToolbarVisible)
            Positioned(
              top: isMobile ? null : 18,
              bottom: isMobile ? 38 : null,
              right: 14,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: InkWell(
                      onTap: () => controller.setToolbarVisible(true),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF232329).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6965DB).withValues(alpha: 0.6)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF6965DB), size: 20),
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
                color: const Color(0xFF232329).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 12, color: Color(0xFF6965DB)),
                  const SizedBox(width: 4),
                  Text(
                    isMobile
                        ? 'P: ${controller.currentPageIndex + 1}/${controller.totalPages} • ${controller.currentTool.name.toUpperCase()}'
                        : 'NovaSlate • PAGE: ${controller.currentPageIndex + 1}/${controller.totalPages} • MODE: ${controller.currentTool.name.toUpperCase()} • POS: (${_cursorPos.dx.toInt()}, ${_cursorPos.dy.toInt()})',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF6965DB),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Slide Drawer Backdrop & Drawer
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

// Rubberband Selection Marquee Box Painter
class _MarqueePainter extends CustomPainter {
  final Rect rect;
  const _MarqueePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF6965DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = const Color(0xFF6965DB).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MarqueePainter oldDelegate) => oldDelegate.rect != rect;
}