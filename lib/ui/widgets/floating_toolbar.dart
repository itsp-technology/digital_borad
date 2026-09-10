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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            isSelected: controller.currentTool == ToolType.pen,
            onPressed: () => controller.setTool(ToolType.pen),
          ),
          IconButton(
            icon: const Icon(Icons.border_color, color: Colors.white),
            isSelected: controller.currentTool == ToolType.highlighter,
            onPressed: () => controller.setTool(ToolType.highlighter),
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.white),
            isSelected: controller.currentTool == ToolType.eraser,
            onPressed: () => controller.setTool(ToolType.eraser),
          ),
          const VerticalDivider(color: Colors.white24, width: 20, thickness: 1),
          ColorPalette(
            selectedColor: controller.selectedColor,
            onColorSelected: controller.setColor,
          ),
          const VerticalDivider(color: Colors.white24, width: 20, thickness: 1),
          StrokeSlider(
            strokeWidth: controller.strokeWidth,
            onChanged: controller.setStrokeWidth,
          ),
          const VerticalDivider(color: Colors.white24, width: 20, thickness: 1),
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: controller.canUndo ? controller.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.white),
            onPressed: controller.canRedo ? controller.redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: controller.clearCanvas,
          ),
        ],
      ),
    );
  }
}