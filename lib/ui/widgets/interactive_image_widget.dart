import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_image.dart';
import '../../models/tool_type.dart';
import '../../state/board_controller.dart';

class InteractiveImageWidget extends StatefulWidget {
  final BoardImage image;
  final int index;

  const InteractiveImageWidget({
    super.key,
    required this.image,
    required this.index,
  });

  @override
  State<InteractiveImageWidget> createState() => _InteractiveImageWidgetState();
}

class _InteractiveImageWidgetState extends State<InteractiveImageWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BoardController>();
    final isSelectMode = controller.currentTool == ToolType.select;

    return Positioned(
      left: widget.image.position.dx,
      top: widget.image.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isSelectMode) {
            controller.selectImage(widget.index);
          }
        },
        onPanUpdate: (details) {
          if (isSelectMode && widget.image.isSelected) {
            controller.updateImagePosition(widget.index, details.delta);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.image.width,
              height: widget.image.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: (widget.image.isSelected && isSelectMode)
                      ? const Color(0xFF00FFA3)
                      : Colors.transparent,
                  width: 2.0,
                ),
                boxShadow: (widget.image.isSelected && isSelectMode)
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00FFA3).withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ]
                    : [],
              ),
              child: Image.memory(
                widget.image.bytes,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),

            // Resize & Scale Handle (Bottom-Right)
            if (widget.image.isSelected && isSelectMode)
              Positioned(
                right: -16,
                bottom: -16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    controller.updateImageSize(
                      widget.index,
                      details.delta.dx,
                      details.delta.dy,
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFA3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.aspect_ratio_rounded, size: 16, color: Colors.black),
                  ),
                ),
              ),

            // Delete Image Button (Top-Right)
            if (widget.image.isSelected && isSelectMode)
              Positioned(
                right: -16,
                top: -16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.deleteSelectedImage,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3366),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}