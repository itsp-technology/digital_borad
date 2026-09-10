import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/stroke_point.dart';
import '../models/tool_type.dart';

enum BoardThemeMode { grid, dots, lines, blank }

class BoardController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _activeStroke;
  List<Offset> _laserTrail = [];
  Timer? _laserTimer;

  ToolType _currentTool = ToolType.pen;
  Color _selectedColor = const Color(0xFF00FFA3); // Cyber Mint
  double _strokeWidth = 4.0;
  BoardThemeMode _themeMode = BoardThemeMode.dots;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get activeStroke => _activeStroke;
  List<Offset> get laserTrail => List.unmodifiable(_laserTrail);
  ToolType get currentTool => _currentTool;
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  BoardThemeMode get themeMode => _themeMode;
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

  void toggleTheme() {
    final nextIndex = (_themeMode.index + 1) % BoardThemeMode.values.length;
    _themeMode = BoardThemeMode.values[nextIndex];
    notifyListeners();
  }

  void startStroke(Offset position, double pressure) {
    if (_currentTool == ToolType.laser) {
      _laserTrail = [position];
      notifyListeners();
      return;
    }

    _redoStack.clear();
    final effectivePressure = pressure > 0 ? pressure : 0.5;

    Color strokeColor;
    double effectiveWidth = _strokeWidth;

    switch (_currentTool) {
      case ToolType.highlighter:
        strokeColor = _selectedColor.withValues(alpha: 0.35);
        effectiveWidth = _strokeWidth * 3.5;
        break;
      case ToolType.eraser:
        strokeColor = const Color(0xFF0D1117);
        effectiveWidth = _strokeWidth * 4.0;
        break;
      case ToolType.pen:
      default:
        strokeColor = _selectedColor;
        break;
    }

    _activeStroke = Stroke(
      points: [StrokePoint(offset: position, pressure: effectivePressure)],
      color: strokeColor,
      strokeWidth: effectiveWidth,
      tool: _currentTool,
    );
    notifyListeners();
  }

  void appendPoint(Offset position, double pressure) {
    if (_currentTool == ToolType.laser) {
      _laserTrail.add(position);
      if (_laserTrail.length > 25) _laserTrail.removeAt(0);
      notifyListeners();
      return;
    }

    if (_activeStroke == null) return;
    final effectivePressure = pressure > 0 ? pressure : 0.5;
    _activeStroke!.points.add(
      StrokePoint(offset: position, pressure: effectivePressure),
    );
    notifyListeners();
  }

  void endStroke() {
    if (_currentTool == ToolType.laser) {
      _laserTimer?.cancel();
      _laserTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        if (_laserTrail.isNotEmpty) {
          _laserTrail.removeAt(0);
          notifyListeners();
        } else {
          timer.cancel();
        }
      });
      return;
    }

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
    _laserTrail.clear();
    notifyListeners();
  }
}