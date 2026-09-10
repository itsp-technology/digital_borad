import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import '../models/board_image.dart';
import '../models/stroke.dart';
import '../models/stroke_point.dart';
import '../models/tool_type.dart';

@JS('renderPdfToImages')
external JSPromise<JSArray<JSString>> renderPdfToImages(JSArrayBuffer buffer);

enum BoardThemeMode { grid, dots, lines, blank }

class BoardController extends ChangeNotifier {
  static const String _storageStrokesKey = 'novaslate_strokes_v2';
  static const String _storageImagesKey = 'novaslate_images_v2';
  static const String _pageIndexKey = 'novaslate_active_page_v2';

  final List<List<Stroke>> _pages = [[]];
  final List<List<BoardImage>> _pageImages = [[]];
  int _currentPageIndex = 0;
  bool _isSlideDrawerOpen = false;

  bool _isToolbarPinned = true;
  bool _isToolbarVisible = true;
  bool _palmRejectionEnabled = false;

  final List<Stroke> _redoStack = [];
  Stroke? _activeStroke;
  List<Offset> _laserTrail = [];
  Timer? _laserTimer;
  Timer? _debounceSaveTimer;

  ToolType _currentTool = ToolType.pen;
  Color _selectedColor = const Color(0xFF00FFA3);
  double _strokeWidth = 4.0;
  BoardThemeMode _themeMode = BoardThemeMode.dots;

  Size _screenSize = const Size(1920, 1080);
  int? _selectedStrokeIndex;

  BoardController() {
    _loadFromLocalStorage();
  }

  // Getters
  List<Stroke> get strokes => List.unmodifiable(_pages[_currentPageIndex]);
  List<List<Stroke>> get allPages => List.unmodifiable(_pages);
  List<BoardImage> get currentImages => _pageImages[_currentPageIndex];
  List<List<BoardImage>> get allPageImages => List.unmodifiable(_pageImages);
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
  bool get palmRejectionEnabled => _palmRejectionEnabled;
  Size get screenSize => _screenSize;
  int? get selectedStrokeIndex => _selectedStrokeIndex;
  Stroke? get selectedStroke =>
      (_selectedStrokeIndex != null && _selectedStrokeIndex! < _pages[_currentPageIndex].length)
          ? _pages[_currentPageIndex][_selectedStrokeIndex!]
          : null;
  bool get canUndo => _pages[_currentPageIndex].isNotEmpty || _pageImages[_currentPageIndex].isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Local Storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strokesData = prefs.getString(_storageStrokesKey);
      final imagesData = prefs.getString(_storageImagesKey);
      final savedIndex = prefs.getInt(_pageIndexKey) ?? 0;

      if (strokesData != null && strokesData.isNotEmpty) {
        final List<dynamic> decodedPages = jsonDecode(strokesData);
        final loadedStrokes = decodedPages.map((page) {
          final List<dynamic> sList = page as List<dynamic>;
          return sList.map((s) => Stroke.fromMap(s as Map<String, dynamic>)).toList();
        }).toList();

        List<List<BoardImage>> loadedImages = [];
        if (imagesData != null && imagesData.isNotEmpty) {
          final List<dynamic> decodedImgPages = jsonDecode(imagesData);
          loadedImages = decodedImgPages.map((page) {
            final List<dynamic> imgList = page as List<dynamic>;
            return imgList.map((i) => BoardImage.fromMap(i as Map<String, dynamic>)).toList();
          }).toList();
        }

        if (loadedStrokes.isNotEmpty) {
          _pages.clear();
          _pageImages.clear();

          for (int i = 0; i < loadedStrokes.length; i++) {
            _pages.add(loadedStrokes[i]);
            if (i < loadedImages.length) {
              _pageImages.add(loadedImages[i]);
            } else {
              _pageImages.add([]);
            }
          }

          _currentPageIndex = (savedIndex < _pages.length) ? savedIndex : 0;
          notifyListeners();
        }
      }
    } catch (_) {
      _pages.clear();
      _pages.add([]);
      _pageImages.clear();
      _pageImages.add([]);
      _currentPageIndex = 0;
    }
  }

  void _scheduleAutoSave() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final serializedStrokes = _pages.map((p) => p.map((s) => s.toMap()).toList()).toList();
        await prefs.setString(_storageStrokesKey, jsonEncode(serializedStrokes));

        final serializedImages = _pageImages.map((p) => p.map((i) => i.toMap()).toList()).toList();
        await prefs.setString(_storageImagesKey, jsonEncode(serializedImages));

        await prefs.setInt(_pageIndexKey, _currentPageIndex);
      } catch (_) {}
    });
  }

  // Stroke Selection, Movement & Resizing (Touch & Mouse)
  void selectStrokeAt(Offset position) {
    final currentStrokes = _pages[_currentPageIndex];
    int? foundIndex;

    for (int i = currentStrokes.length - 1; i >= 0; i--) {
      if (currentStrokes[i].containsOffset(position)) {
        foundIndex = i;
        break;
      }
    }

    _deselectAllStrokes();
    if (foundIndex != null) {
      currentStrokes[foundIndex].isSelected = true;
      _selectedStrokeIndex = foundIndex;
      deselectAllImages();
    }
    notifyListeners();
  }

  void moveSelectedStroke(Offset delta) {
    if (_selectedStrokeIndex != null &&
        _selectedStrokeIndex! < _pages[_currentPageIndex].length) {
      _pages[_currentPageIndex][_selectedStrokeIndex!].translate(delta);
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void resizeSelectedStroke(double deltaWidth, double deltaHeight) {
    if (_selectedStrokeIndex != null &&
        _selectedStrokeIndex! < _pages[_currentPageIndex].length) {
      _pages[_currentPageIndex][_selectedStrokeIndex!].scale(deltaWidth, deltaHeight);
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void deleteSelectedStroke() {
    if (_selectedStrokeIndex != null &&
        _selectedStrokeIndex! < _pages[_currentPageIndex].length) {
      _redoStack.add(_pages[_currentPageIndex].removeAt(_selectedStrokeIndex!));
      _selectedStrokeIndex = null;
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void _deselectAllStrokes() {
    for (final s in _pages[_currentPageIndex]) {
      s.isSelected = false;
    }
    _selectedStrokeIndex = null;
  }

  // Image Transformations
  void selectImage(int index) {
    _deselectAllStrokes();
    for (int i = 0; i < _pageImages[_currentPageIndex].length; i++) {
      _pageImages[_currentPageIndex][i].isSelected = (i == index);
    }
    notifyListeners();
  }

  void deselectAllImages() {
    for (final img in _pageImages[_currentPageIndex]) {
      img.isSelected = false;
    }
    notifyListeners();
  }

  void updateImagePosition(int index, Offset delta) {
    if (index >= 0 && index < _pageImages[_currentPageIndex].length) {
      _pageImages[_currentPageIndex][index].position += delta;
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void updateImageSize(int index, double deltaWidth, double deltaHeight) {
    if (index >= 0 && index < _pageImages[_currentPageIndex].length) {
      final img = _pageImages[_currentPageIndex][index];
      img.width = (img.width + deltaWidth).clamp(80.0, _screenSize.width * 3.0);
      img.height = (img.height + deltaHeight).clamp(80.0, _screenSize.height * 3.0);
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void deleteSelectedImage() {
    _pageImages[_currentPageIndex].removeWhere((img) => img.isSelected);
    _scheduleAutoSave();
    notifyListeners();
  }

  // File Import Logic
  Future<void> importMedia() async {
    final uploadInput = web.document.createElement('input') as web.HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.accept = '.pdf,image/*';
    uploadInput.click();

    uploadInput.onChange.listen((_) {
      final files = uploadInput.files;
      if (files == null || files.length == 0) return;
      final file = files.item(0)!;
      final reader = web.FileReader();

      reader.onLoadEnd.listen((_) async {
        final result = reader.result;
        if (result == null) return;

        final arrayBuffer = result as JSArrayBuffer;
        final bytes = (result as ByteBuffer).asUint8List();
        final fileName = file.name.toLowerCase();

        if (fileName.endsWith('.pdf')) {
          await _importPdf(arrayBuffer);
        } else {
          _addImageToCurrentSlide(bytes);
        }
      });

      reader.readAsArrayBuffer(file);
    });
  }

  Future<void> _importPdf(JSArrayBuffer buffer) async {
    try {
      final jsImages = await renderPdfToImages(buffer).toDart;
      final dartImages = jsImages.toDart;

      for (int i = 0; i < dartImages.length; i++) {
        final dataUrl = dartImages[i].toDart;
        final base64String = dataUrl.split(',').last;
        final imageBytes = base64Decode(base64String);

        if (i == 0 && _pages[_currentPageIndex].isEmpty && _pageImages[_currentPageIndex].isEmpty) {
          _addImageToCurrentSlide(imageBytes, autoFit: true);
        } else {
          _pages.add([]);
          _pageImages.add([]);
          _currentPageIndex = _pages.length - 1;
          _addImageToCurrentSlide(imageBytes, autoFit: true);
        }
      }
      _scheduleAutoSave();
      notifyListeners();
    } catch (_) {}
  }

  void _addImageToCurrentSlide(Uint8List bytes, {bool autoFit = false}) {
    final double initialWidth = autoFit ? (_screenSize.width * 0.85).clamp(320.0, 1400.0) : 380.0;
    final double initialHeight = autoFit ? (_screenSize.height * 0.88).clamp(240.0, 900.0) : 260.0;

    final newImage = BoardImage(
      bytes: bytes,
      position: Offset(
        (_screenSize.width - initialWidth) / 2,
        (_screenSize.height - initialHeight) / 2,
      ),
      width: initialWidth,
      height: initialHeight,
      isSelected: true,
    );

    _currentTool = ToolType.select;
    _pageImages[_currentPageIndex].add(newImage);
    _scheduleAutoSave();
    notifyListeners();
  }

  void updateScreenSize(Size size) {
    if (_screenSize != size && size.width > 0 && size.height > 0) {
      _screenSize = size;
      notifyListeners();
    }
  }

  void togglePalmRejection() {
    _palmRejectionEnabled = !_palmRejectionEnabled;
    notifyListeners();
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
    if (tool != ToolType.select) {
      deselectAllImages();
      _deselectAllStrokes();
    }
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
    _pageImages.add([]);
    _currentPageIndex = _pages.length - 1;
    _redoStack.clear();
    _activeStroke = null;
    _deselectAllStrokes();
    _scheduleAutoSave();
    notifyListeners();
  }

  void goToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _currentPageIndex = index;
      _redoStack.clear();
      _activeStroke = null;
      _deselectAllStrokes();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void deletePage(int index) {
    if (_pages.length <= 1) {
      _pages[0].clear();
      _pageImages[0].clear();
    } else {
      _pages.removeAt(index);
      _pageImages.removeAt(index);
      if (_currentPageIndex > index) {
        _currentPageIndex--;
      } else if (_currentPageIndex >= _pages.length) {
        _currentPageIndex = _pages.length - 1;
      }
    }
    _redoStack.clear();
    _activeStroke = null;
    _deselectAllStrokes();
    _scheduleAutoSave();
    notifyListeners();
  }

  void nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _currentPageIndex++;
    } else {
      _pages.add([]);
      _pageImages.add([]);
      _currentPageIndex++;
    }
    _redoStack.clear();
    _activeStroke = null;
    _deselectAllStrokes();
    _scheduleAutoSave();
    notifyListeners();
  }

  void previousPage() {
    if (_currentPageIndex > 0) {
      _currentPageIndex--;
      _redoStack.clear();
      _activeStroke = null;
      _deselectAllStrokes();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void startStroke(Offset position, double pressure, [ui.PointerDeviceKind? kind]) {
    // In Select Mode: taps select strokes/images with touch or stylus
    if (_currentTool == ToolType.select) {
      selectStrokeAt(position);
      return;
    }

    // In Drawing Mode: Palm rejection only isolates finger touches while actively inking
    if (_palmRejectionEnabled && kind == ui.PointerDeviceKind.touch) return;

    if (_currentTool == ToolType.laser) {
      _laserTrail = [position];
      notifyListeners();
      return;
    }

    _redoStack.clear();
    final effectivePressure = pressure > 0 ? pressure : 0.5;

    Color strokeColor = _selectedColor;
    double effectiveWidth = _strokeWidth;

    if (_currentTool == ToolType.highlighter) {
      strokeColor = _selectedColor.withValues(alpha: 0.35);
      effectiveWidth = _strokeWidth * 3.5;
    } else if (_currentTool == ToolType.eraser) {
      strokeColor = const Color(0xFF0D1117);
      effectiveWidth = _strokeWidth * 4.0;
    }

    _activeStroke = Stroke(
      points: [StrokePoint(offset: position, pressure: effectivePressure)],
      color: strokeColor,
      strokeWidth: effectiveWidth,
      tool: _currentTool,
    );
    notifyListeners();
  }

  void appendPoint(Offset position, double pressure, [ui.PointerDeviceKind? kind]) {
    if (_currentTool == ToolType.select) return;
    if (_palmRejectionEnabled && kind == ui.PointerDeviceKind.touch) return;

    if (_currentTool == ToolType.laser) {
      _laserTrail.add(position);
      if (_laserTrail.length > 25) _laserTrail.removeAt(0);
      notifyListeners();
      return;
    }

    if (_activeStroke == null) return;
    final effectivePressure = pressure > 0 ? pressure : 0.5;

    if (_isGeometricTool(_currentTool)) {
      if (_activeStroke!.points.length == 1) {
        _activeStroke!.points.add(StrokePoint(offset: position, pressure: effectivePressure));
      } else {
        _activeStroke!.points[1] = StrokePoint(offset: position, pressure: effectivePressure);
      }
    } else {
      _activeStroke!.points.add(StrokePoint(offset: position, pressure: effectivePressure));
    }
    notifyListeners();
  }

  bool _isGeometricTool(ToolType tool) {
    return tool == ToolType.line ||
        tool == ToolType.arrow ||
        tool == ToolType.rectangle ||
        tool == ToolType.circle;
  }

  void endStroke() {
    if (_currentTool == ToolType.select) return;

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
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void undo() {
    if (_pages[_currentPageIndex].isNotEmpty) {
      _redoStack.add(_pages[_currentPageIndex].removeLast());
      _deselectAllStrokes();
      _scheduleAutoSave();
      notifyListeners();
    } else if (_pageImages[_currentPageIndex].isNotEmpty) {
      _pageImages[_currentPageIndex].removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _pages[_currentPageIndex].add(_redoStack.removeLast());
      _deselectAllStrokes();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void clearCanvas() {
    _pages[_currentPageIndex].clear();
    _pageImages[_currentPageIndex].clear();
    _redoStack.clear();
    _activeStroke = null;
    _laserTrail.clear();
    _deselectAllStrokes();
    _scheduleAutoSave();
    notifyListeners();
  }
}