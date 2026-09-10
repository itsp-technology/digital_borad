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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? MediaQuery.of(context).size.width - 24 : 950,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF121620).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pin / Auto-hide Button
                  Tooltip(
                    message: controller.isToolbarPinned
                        ? 'Pinned: Always Visible'
                        : 'Unpinned: Auto-Hides on Tool Select',
                    child: IconButton(
                      icon: Icon(
                        controller.isToolbarPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 18,
                        color: controller.isToolbarPinned ? const Color(0xFF00FFA3) : Colors.white38,
                      ),
                      onPressed: controller.toggleToolbarPin,
                    ),
                  ),
                  _buildDivider(),

                  // Inking Tools
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

                  // Color Picker
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

                  // Theme Selector
                  IconButton(
                    tooltip: 'Change Grid Pattern',
                    icon: const Icon(Icons.grid_4x4_rounded, size: 19, color: Colors.white70),
                    onPressed: controller.toggleTheme,
                  ),

                  // Actions: Undo, Redo, Clear
                  IconButton(
                    tooltip: 'Undo',
                    icon: const Icon(Icons.undo_rounded, size: 19, color: Colors.white70),
                    onPressed: controller.canUndo ? controller.undo : null,
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    icon: const Icon(Icons.redo_rounded, size: 19, color: Colors.white70),
                    onPressed: controller.canRedo ? controller.redo : null,
                  ),
                  IconButton(
                    tooltip: 'Wipe Slide',
                    icon: const Icon(Icons.delete_sweep_rounded, size: 19, color: Color(0xFFFF4545)),
                    onPressed: controller.clearCanvas,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 22,
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
          padding: const EdgeInsets.all(7),
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
            size: 18,
            color: isSelected ? activeColor : Colors.white60,
          ),
        ),
      ),
    );
  }
}