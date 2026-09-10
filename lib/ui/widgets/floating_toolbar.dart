import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool_type.dart';
import '../../state/board_controller.dart';
import 'color_palette.dart';
import 'stroke_slider.dart';

class FloatingToolbar extends StatelessWidget {
  const FloatingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BoardController>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF14171F).withOpacity(0.70),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolButton(
                icon: Icons.edit_rounded,
                label: 'Pen',
                activeColor: const Color(0xFF00FFA3),
                isSelected: controller.currentTool == ToolType.pen,
                onTap: () => controller.setTool(ToolType.pen),
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.brush_rounded,
                label: 'Highlight',
                activeColor: const Color(0xFFFFE600),
                isSelected: controller.currentTool == ToolType.highlighter,
                onTap: () => controller.setTool(ToolType.highlighter),
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.auto_fix_high_rounded,
                label: 'Eraser',
                activeColor: const Color(0xFFFF3366),
                isSelected: controller.currentTool == ToolType.eraser,
                onTap: () => controller.setTool(ToolType.eraser),
              ),
              const _GlassDivider(),
              ColorPalette(
                selectedColor: controller.selectedColor,
                onColorSelected: controller.setColor,
              ),
              const _GlassDivider(),
              StrokeSlider(
                strokeWidth: controller.strokeWidth,
                onChanged: controller.setStrokeWidth,
              ),
              const _GlassDivider(),
              IconButton(
                tooltip: 'Undo',
                icon: const Icon(Icons.undo_rounded, size: 20, color: Colors.white70),
                onPressed: controller.canUndo ? controller.undo : null,
              ),
              IconButton(
                tooltip: 'Redo',
                icon: const Icon(Icons.redo_rounded, size: 20, color: Colors.white70),
                onPressed: controller.canRedo ? controller.redo : null,
              ),
              IconButton(
                tooltip: 'Purge Canvas',
                icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: Color(0xFFFF5252)),
                onPressed: controller.clearCanvas,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? activeColor : Colors.white60,
        ),
      ),
    );
  }
}

class _GlassDivider extends StatelessWidget {
  const _GlassDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 24,
      width: 1.2,
      color: Colors.white.withOpacity(0.1),
    );
  }
}