import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../painter/board_painter.dart';
import '../../state/board_controller.dart';

class SlideDrawer extends StatelessWidget {
  const SlideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BoardController>();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final drawerWidth = isMobile ? MediaQuery.of(context).size.width * 0.85 : 250.0;
    final screenSize = controller.screenSize;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          width: drawerWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF10131C).withValues(alpha: 0.92),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 30,
                offset: const Offset(10, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.layers_rounded, color: Color(0xFF00FFA3), size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SLIDE DECK',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'ACTIVE: ${controller.currentPageIndex + 1} / ${controller.totalPages}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Color(0xFF00FFA3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white60),
                      onPressed: controller.toggleSlideDrawer,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Individual Slide Thumbnails
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  itemCount: controller.totalPages,
                  itemBuilder: (context, index) {
                    final isSelected = index == controller.currentPageIndex;
                    final slideStrokes = controller.allPages[index];
                    final slideImages = controller.allPageImages[index];

                    final double previewWidth = drawerWidth - 24;
                    const double previewHeight = 125.0;
                    final double scaleX = previewWidth / (screenSize.width > 0 ? screenSize.width : 1920);
                    final double scaleY = previewHeight / (screenSize.height > 0 ? screenSize.height : 1080);
                    final double previewScale = scaleX < scaleY ? scaleX : scaleY;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00FFA3) : Colors.white12,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00FFA3).withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            controller.goToPage(index);
                            if (isMobile) controller.closeSlideDrawer();
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: previewHeight,
                                width: double.infinity,
                                color: const Color(0xFF080B10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Accurate Slide-Specific Images
                                    ...slideImages.map(
                                      (img) => Positioned(
                                        left: img.position.dx * previewScale,
                                        top: img.position.dy * previewScale,
                                        width: img.width * previewScale,
                                        height: img.height * previewScale,
                                        child: Image.memory(
                                          img.bytes,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                    CustomPaint(
                                      size: Size(previewWidth, previewHeight),
                                      painter: BoardPainter(
                                        strokes: slideStrokes,
                                        activeStroke: null,
                                        scale: previewScale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF00FFA3) : Colors.white24,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFF00FFA3) : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (controller.totalPages > 1)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => controller.deletePage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 14,
                                        color: Color(0xFFFF5252),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: controller.importMedia,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded, color: Color(0xFF00E5FF), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Import PDF / Image',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: controller.addNewPage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFA3).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00FFA3).withValues(alpha: 0.6)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: Color(0xFF00FFA3), size: 17),
                            SizedBox(width: 6),
                            Text(
                              'Add Slide',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF00FFA3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}