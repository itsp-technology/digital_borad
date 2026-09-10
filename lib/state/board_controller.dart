import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../models/stroke_point.dart';
import '../models/tool_type.dart';

enum BoardThemeMode { grid, dots, lines, blank }

class BoardController extends ChangeNotifier {
  final List<List<Stroke>> _pages = [[]];
  int _currentPageIndex = 0;
  bool _isSlideDrawerOpen = false;

  // Toolbar stick / auto-hide feature
  bool _isToolbarPinned = true;
  bool _isToolbarVisible = true;

  final List<Stroke> _redoStack = [];
  Stroke? _activeStroke;
  List<Offset> _laserTrail = [];
  Timer? _laserTimer;

  ToolType _currentTool = ToolType.pen;
  Color _selectedColor = const Color(0xFF00FFA3);
  double _strokeWidth = 4.0;
  BoardThemeMode _themeMode = BoardThemeMode.dots;

  // Canvas dimensions for scaling thumbnail previews
  Size _screenSize = const Size(1920, 1080);

  // Getters
  List<Stroke> get strokes => List.unmodifiable(_pages[_currentPageIndex]);
  List<List<Stroke>> get allPages => List.unmodifiable(_pages);
  Stroke? get activeStroke => _activeStroke;
  List<Offset> get laserTrail => List.unmodifiable(_laserTrail);
  ToolType get currentTool => _currentTool;
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  BoardThemeMode get themeMode => _themeMode;
  int get currentPageIndex => _currentPageIndex;
  int get totalPages => _pages.length;
  bool get isSlideDrawerOpen => _isSlideDrawerOpen;
  bool get isToolbarPinned => _isToolbarPinned;
  bool get isToolbarVisible => _isToolbarVisible;
  Size get screenSize => _screenSize;
  bool get canUndo => _pages[_currentPageIndex].isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void updateScreenSize(Size size) {
    if (_screenSize != size && size.width > 0 && size.height > 0) {
      _screenSize = size;
      notifyListeners();
    }
  }

  void toggleToolbarPin() {
    _isToolbarPinned = !_isToolbarPinned;
    notifyListeners();
  }

  void setToolbarVisible(bool visible) {
    _isToolbarVisible = visible;
    notifyListeners();
  }

  void onToolSelected() {
    if (!_isToolbarPinned) {
      _isToolbarVisible = false;
      notifyListeners();
    }
  }

  void toggleSlideDrawer() {
    _isSlideDrawerOpen = !_isSlideDrawerOpen;
    notifyListeners();
  }

  void closeSlideDrawer() {
    if (_isSlideDrawerOpen) {
      _isSlideDrawerOpen = false;
      notifyListeners();
    }
  }

  void setTool(ToolType tool) {
    _currentTool = tool;
    onToolSelected();
    notifyListeners();
  }

  void setColor(Color color) {
    _selectedColor = color;
    onToolSelected();
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

  void addNewPage() {
    _pages.add([]);
    _currentPageIndex = _pages.length - 1;
    _redoStack.clear();
    _activeStroke = null;
    notifyListeners();
  }

  void goToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _currentPageIndex = index;
      _redoStack.clear();
      _activeStroke = null;
      notifyListeners();
    }
  }

  void deletePage(int index) {
    if (_pages.length <= 1) {
      _pages[0].clear();
    } else {
      _pages.removeAt(index);
      if (_currentPageIndex >= _pages.length) {
        _currentPageIndex = _pages.length - 1;
      }
    }
    _redoStack.clear();
    _activeStroke = null;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _currentPageIndex++;
    } else {
      _pages.add([]);
      _currentPageIndex++;
    }
    _redoStack.clear();
    _activeStroke = null;
    notifyListeners();
  }

  void previousPage() {
    if (_currentPageIndex > 0) {
      _currentPageIndex--;
      _redoStack.clear();
      _activeStroke = null;
      notifyListeners();
    }
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
      _pages[_currentPageIndex].add(_activeStroke!);
      _activeStroke = null;
      notifyListeners();
    }
  }

  void undo() {
    if (_pages[_currentPageIndex].isNotEmpty) {
      _redoStack.add(_pages[_currentPageIndex].removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _pages[_currentPageIndex].add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void clearCanvas() {
    _pages[_currentPageIndex].clear();
    _redoStack.clear();
    _activeStroke = null;
    _laserTrail.clear();
    notifyListeners();
  }
}