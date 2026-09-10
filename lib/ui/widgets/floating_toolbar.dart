import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool_type.dart';
import '../../state/board_controller.dart';
import 'color_palette.dart';
import 'stroke_slider.dart';

class FloatingToolbar extends StatelessWidget {
  final VoidCallback onExport;
  const FloatingToolbar({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BoardController>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? MediaQuery.of(context).size.width - 16 : 1180,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF232329).withValues(alpha: 0.94), // Excalidraw dark theme surface
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pin & Palm Controls
                  IconButton(
                    tooltip: controller.isToolbarPinned ? 'Pinned' : 'Auto-Hides',
                    icon: Icon(
                      controller.isToolbarPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 18,
                      color: controller.isToolbarPinned ? const Color(0xFF6965DB) : Colors.white38,
                    ),
                    onPressed: controller.toggleToolbarPin,
                  ),
                  IconButton(
                    tooltip: controller.palmRejectionEnabled ? 'Stylus Only Mode (Active)' : 'Touch + Stylus',
                    icon: Icon(
                      Icons.do_not_touch_rounded,
                      size: 18,
                      color: controller.palmRejectionEnabled ? const Color(0xFFFF5252) : Colors.white38,
                    ),
                    onPressed: controller.togglePalmRejection,
                  ),
                  _buildDivider(),

                  // 1. Selection / Transform Tool
                  _ExcaliToolButton(
                    icon: Icons.near_me_outlined,
                    isSelected: controller.currentTool == ToolType.select,
                    onTap: () => controller.setTool(ToolType.select),
                    tooltip: 'Selection (V)',
                  ),
                  const SizedBox(width: 4),

                  // 2. Freehand Inking (Draw)
                  _ExcaliToolButton(
                    icon: Icons.edit_rounded,
                    isSelected: controller.currentTool == ToolType.pen,
                    onTap: () => controller.setTool(ToolType.pen),
                    tooltip: 'Draw (P)',
                  ),
                  const SizedBox(width: 4),
                  _ExcaliToolButton(
                    icon: Icons.brush_rounded,
                    isSelected: controller.currentTool == ToolType.highlighter,
                    onTap: () => controller.setTool(ToolType.highlighter),
                    tooltip: 'Highlighter',
                  ),
                  const SizedBox(width: 4),
                  _ExcaliToolButton(
                    icon: Icons.flare_rounded,
                    isSelected: controller.currentTool == ToolType.laser,
                    onTap: () => controller.setTool(ToolType.laser),
                    tooltip: 'Laser Pointer',
                  ),
                  const SizedBox(width: 4),
                  _ExcaliToolButton(
                    icon: Icons.auto_fix_high_rounded,
                    isSelected: controller.currentTool == ToolType.eraser,
                    onTap: () => controller.setTool(ToolType.eraser),
                    tooltip: 'Eraser (E)',
                  ),
                  _buildDivider(),

                  // 3. Excalidraw Geometric Shapes
                  _ExcaliToolButton(
                    icon: Icons.horizontal_rule_rounded,
                    isSelected: controller.currentTool == ToolType.line,
                    onTap: () => controller.setTool(ToolType.line),
                    tooltip: 'Line (L)',
                  ),
                  const SizedBox(width: 4),
                  _ExcaliToolButton(
                    icon: Icons.arrow_outward_rounded,
                    isSelected: controller.currentTool == ToolType.arrow,
                    onTap: () => controller.setTool(ToolType.arrow),
                    tooltip: 'Arrow (A)',
                  ),
                  const SizedBox(width: 4),
                  _ExcaliToolButton(
                    icon: Icons.crop_square_rounded,
                    isSelected: controller.currentTool == ToolType.rectangle,
                    onTap: () => controller.setTool(ToolType.rectangle),
                    tooltip: 'Rectangle (R)',
                  ),
                  const SizedBox(width: 4),
                  _ExcaliToolButton(
                    icon: Icons.panorama_fish_eye_rounded,
                    isSelected: controller.currentTool == ToolType.circle,
                    onTap: () => controller.setTool(ToolType.circle),
                    tooltip: 'Ellipse (O)',
                  ),
                  _buildDivider(),

                  // Color & Thickness
                  ColorPalette(
                    selectedColor: controller.selectedColor,
                    onColorSelected: controller.setColor,
                  ),
                  _buildDivider(),
                  StrokeSlider(
                    strokeWidth: controller.strokeWidth,
                    onChanged: controller.setStrokeWidth,
                  ),
                  _buildDivider(),

                  // Media Import
                  IconButton(
                    tooltip: 'Insert PDF / Image',
                    icon: const Icon(Icons.image_outlined, size: 20, color: Colors.white70),
                    onPressed: controller.importMedia,
                  ),

                  // Background Grid Mode
                  IconButton(
                    tooltip: 'Change Canvas Background',
                    icon: const Icon(Icons.grid_4x4_rounded, size: 19, color: Colors.white70),
                    onPressed: controller.toggleTheme,
                  ),

                  // Export Slide
                  IconButton(
                    tooltip: 'Export Image (PNG)',
                    icon: const Icon(Icons.download_rounded, size: 19, color: Color(0xFF6965DB)),
                    onPressed: onExport,
                  ),

                  // History
                  IconButton(
                    tooltip: 'Undo (Ctrl+Z)',
                    icon: const Icon(Icons.undo_rounded, size: 19, color: Colors.white70),
                    onPressed: controller.canUndo ? controller.undo : null,
                  ),
                  IconButton(
                    tooltip: 'Redo (Ctrl+Y)',
                    icon: const Icon(Icons.redo_rounded, size: 19, color: Colors.white70),
                    onPressed: controller.canRedo ? controller.redo : null,
                  ),
                  IconButton(
                    tooltip: 'Clear Canvas',
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFFF5252)),
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

class _ExcaliToolButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _ExcaliToolButton({
    required this.icon,
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
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6965DB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 19,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}