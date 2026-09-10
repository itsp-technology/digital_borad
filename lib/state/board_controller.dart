import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/stroke_point.dart';
import '../models/tool_type.dart';

class BoardController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _activeStroke;

  ToolType _currentTool = ToolType.pen;
  Color _selectedColor = Colors.white;
  double _strokeWidth = 4.0;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get activeStroke => _activeStroke;
  ToolType get currentTool => _currentTool;
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setTool(ToolType tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void startStroke(Offset position, double pressure) {
    _redoStack.clear();
    final effectivePressure = pressure > 0 ? pressure : 0.5;
    _activeStroke = Stroke(
      points: [StrokePoint(offset: position, pressure: effectivePressure)],
      color: _currentTool == ToolType.eraser
          ? const Color(0xFF1E1E1E)
          : (_currentTool == ToolType.highlighter
              ? _selectedColor.withOpacity(0.35)
              : _selectedColor),
      strokeWidth: _currentTool == ToolType.eraser ? _strokeWidth * 3 : _strokeWidth,
      tool: _currentTool,
    );
    notifyListeners();
  }

  void appendPoint(Offset position, double pressure) {
    if (_activeStroke == null) return;
    final effectivePressure = pressure > 0 ? pressure : 0.5;
    _activeStroke!.points.add(
      StrokePoint(offset: position, pressure: effectivePressure),
    );
    notifyListeners();
  }

  void endStroke() {
    if (_activeStroke != null) {
      _strokes.add(_activeStroke!);
      _activeStroke = null;
      notifyListeners();
    }
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void clearCanvas() {
    _strokes.clear();
    _redoStack.clear();
    _activeStroke = null;
    notifyListeners();
  }
}