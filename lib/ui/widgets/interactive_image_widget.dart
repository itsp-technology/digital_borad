import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_image.dart';
import '../../state/board_controller.dart';

class InteractiveImageWidget extends StatelessWidget {
  final BoardImage image;
  final int index;

  const InteractiveImageWidget({
    super.key,
    required this.image,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<BoardController>();

    return Positioned(
      left: image.position.dx,
      top: image.position.dy,
      child: GestureDetector(
        onTap: () => controller.selectImage(index),
        onPanUpdate: (details) {
          if (image.isSelected) {
            controller.updateImagePosition(index, details.delta);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: image.width,
              height: image.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: image.isSelected ? const Color(0xFF00FFA3) : Colors.transparent,
                  width: 2.0,
                ),
                boxShadow: image.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00FFA3).withValues(alpha: 0.3),
                          blurRadius: 15,
                        ),
                      ]
                    : [],
              ),
              child: Image.memory(
                image.bytes,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),

            // Resize & Zoom Handle (Bottom-Right)
            if (image.isSelected)
              Positioned(
                right: -12,
                bottom: -12,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    controller.updateImageSize(index, details.delta.dx, details.delta.dy);
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFA3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.aspect_ratio_rounded, size: 14, color: Colors.black),
                  ),
                ),
              ),

            // Delete Image Button (Top-Right)
            if (image.isSelected)
              Positioned(
                right: -12,
                top: -12,
                child: GestureDetector(
                  onTap: controller.deleteSelectedImage,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4545),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}