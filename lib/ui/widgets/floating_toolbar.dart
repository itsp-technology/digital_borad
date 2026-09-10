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
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF121620).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin / Stick Toggle Symbol
              Tooltip(
                message: controller.isToolbarPinned
                    ? 'Pinned: Always Visible'
                    : 'Unpinned: Auto-Hides on Tool Select',
                child: IconButton(
                  icon: Icon(
                    controller.isToolbarPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 19,
                    color: controller.isToolbarPinned ? const Color(0xFF00FFA3) : Colors.white38,
                  ),
                  onPressed: controller.toggleToolbarPin,
                ),
              ),
              _buildDivider(),

              // Core Inking Tools
              _ToolIcon(
                icon: Icons.edit_rounded,
                activeColor: const Color(0xFF00FFA3),
                isSelected: controller.currentTool == ToolType.pen,
                onTap: () => controller.setTool(ToolType.pen),
                tooltip: 'Cyber Pen',
              ),
              const SizedBox(width: 4),
              _ToolIcon(
                icon: Icons.brush_rounded,
                activeColor: const Color(0xFFFFE600),
                isSelected: controller.currentTool == ToolType.highlighter,
                onTap: () => controller.setTool(ToolType.highlighter),
                tooltip: 'Highlighter',
              ),
              const SizedBox(width: 4),
              _ToolIcon(
                icon: Icons.flare_rounded,
                activeColor: const Color(0xFFFF0055),
                isSelected: controller.currentTool == ToolType.laser,
                onTap: () => controller.setTool(ToolType.laser),
                tooltip: 'Laser Pointer',
              ),
              const SizedBox(width: 4),
              _ToolIcon(
                icon: Icons.auto_fix_high_rounded,
                activeColor: Colors.blueAccent,
                isSelected: controller.currentTool == ToolType.eraser,
                onTap: () => controller.setTool(ToolType.eraser),
                tooltip: 'Eraser',
              ),
              _buildDivider(),

              // Color Selection
              ColorPalette(
                selectedColor: controller.selectedColor,
                onColorSelected: controller.setColor,
              ),
              _buildDivider(),

              // Stroke Width
              StrokeSlider(
                strokeWidth: controller.strokeWidth,
                onChanged: controller.setStrokeWidth,
              ),
              _buildDivider(),

              // Canvas Background Grid Mode
              IconButton(
                tooltip: 'Change Background Grid',
                icon: const Icon(Icons.grid_4x4_rounded, size: 20, color: Colors.white70),
                onPressed: controller.toggleTheme,
              ),

              // Undo / Redo / Clear
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
                tooltip: 'Wipe Current Slide',
                icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: Color(0xFFFF4545)),
                onPressed: controller.clearCanvas,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 24,
      width: 1.0,
      color: Colors.white12,
    );
  }
}

class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _ToolIcon({
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}