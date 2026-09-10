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
        child: Container(
          width: widget.image.width,
          height: widget.image.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: (widget.image.isSelected && isSelectMode)
                  ? const Color(0xFF6965DB)
                  : Colors.transparent,
              width: 2.0,
            ),
            boxShadow: (widget.image.isSelected && isSelectMode)
                ? [
                    BoxShadow(
                      color: const Color(0xFF6965DB).withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ]
                : [],
          ),
          child: Image.memory(
            widget.image.bytes,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1B1F2A),
              child: const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}