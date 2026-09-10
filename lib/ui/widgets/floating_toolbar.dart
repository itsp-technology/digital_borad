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
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? MediaQuery.of(context).size.width - 16 : 1180,
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
                  IconButton(
                    tooltip: controller.isToolbarPinned ? 'Pinned' : 'Auto-Hides',
                    icon: Icon(
                      controller.isToolbarPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 18,
                      color: controller.isToolbarPinned ? const Color(0xFF00FFA3) : Colors.white38,
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

                  // Select / Move & Scale Images/PDFs
                  _ToolIcon(
                    icon: Icons.pan_tool_alt_rounded,
                    activeColor: const Color(0xFF00E5FF),
                    isSelected: controller.currentTool == ToolType.select,
                    onTap: () => controller.setTool(ToolType.select),
                    tooltip: 'Select / Move & Resize Image',
                  ),
                  const SizedBox(width: 3),

                  // Freehand Tools
                  _ToolIcon(
                    icon: Icons.edit_rounded,
                    activeColor: const Color(0xFF00FFA3),
                    isSelected: controller.currentTool == ToolType.pen,
                    onTap: () => controller.setTool(ToolType.pen),
                    tooltip: 'Pen',
                  ),
                  const SizedBox(width: 3),
                  _ToolIcon(
                    icon: Icons.brush_rounded,
                    activeColor: const Color(0xFFFFE600),
                    isSelected: controller.currentTool == ToolType.highlighter,
                    onTap: () => controller.setTool(ToolType.highlighter),
                    tooltip: 'Highlighter',
                  ),
                  const SizedBox(width: 3),
                  _ToolIcon(
                    icon: Icons.flare_rounded,
                    activeColor: const Color(0xFFFF0055),
                    isSelected: controller.currentTool == ToolType.laser,
                    onTap: () => controller.setTool(ToolType.laser),
                    tooltip: 'Laser',
                  ),
                  const SizedBox(width: 3),
                  _ToolIcon(
                    icon: Icons.auto_fix_high_rounded,
                    activeColor: Colors.blueAccent,
                    isSelected: controller.currentTool == ToolType.eraser,
                    onTap: () => controller.setTool(ToolType.eraser),
                    tooltip: 'Eraser',
                  ),
                  _buildDivider(),

                  // Geometric Shapes
                  _ToolIcon(
                    icon: Icons.horizontal_rule_rounded,
                    activeColor: const Color(0xFF00E5FF),
                    isSelected: controller.currentTool == ToolType.line,
                    onTap: () => controller.setTool(ToolType.line),
                    tooltip: 'Line',
                  ),
                  const SizedBox(width: 3),
                  _ToolIcon(
                    icon: Icons.arrow_outward_rounded,
                    activeColor: const Color(0xFF00E5FF),
                    isSelected: controller.currentTool == ToolType.arrow,
                    onTap: () => controller.setTool(ToolType.arrow),
                    tooltip: 'Arrow',
                  ),
                  const SizedBox(width: 3),
                  _ToolIcon(
                    icon: Icons.crop_square_rounded,
                    activeColor: const Color(0xFF00E5FF),
                    isSelected: controller.currentTool == ToolType.rectangle,
                    onTap: () => controller.setTool(ToolType.rectangle),
                    tooltip: 'Rectangle',
                  ),
                  const SizedBox(width: 3),
                  _ToolIcon(
                    icon: Icons.panorama_fish_eye_rounded,
                    activeColor: const Color(0xFF00E5FF),
                    isSelected: controller.currentTool == ToolType.circle,
                    onTap: () => controller.setTool(ToolType.circle),
                    tooltip: 'Circle',
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

                  // Import PDF / Image
                  IconButton(
                    tooltip: 'Import PDF / Image to Board',
                    icon: const Icon(Icons.note_add_rounded, size: 20, color: Color(0xFF00E5FF)),
                    onPressed: controller.importMedia,
                  ),

                  // Background Pattern
                  IconButton(
                    tooltip: 'Grid Pattern',
                    icon: const Icon(Icons.grid_4x4_rounded, size: 19, color: Colors.white70),
                    onPressed: controller.toggleTheme,
                  ),

                  // Export Notes
                  IconButton(
                    tooltip: 'Export Slide to Notes',
                    icon: const Icon(Icons.download_rounded, size: 19, color: Color(0xFF00FFA3)),
                    onPressed: onExport,
                  ),

                  // History & Wipe
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
                    tooltip: 'Wipe Clean',
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
      margin: const EdgeInsets.symmetric(horizontal: 5),
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
            borderRadius: BorderRadius.circular(10),
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