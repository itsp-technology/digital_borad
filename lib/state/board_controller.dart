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
external JSPromise<JSString> renderPdfToImages(JSString base64Data);

@JS('saveToIDB')
external JSPromise<JSBoolean> saveToIDB(JSString key, JSString dataString);

@JS('loadFromIDB')
external JSPromise<JSString> loadFromIDB(JSString key);

enum BoardThemeMode { grid, dots, lines, blank }

class BoardController extends ChangeNotifier {
  static const String _storageStrokesKey = 'novaslate_strokes_idb';
  static const String _storageImagesKey = 'novaslate_images_idb';
  static const String _pageIndexKey = 'novaslate_active_page_idb';

  final List<List<Stroke>> _pages = [[]];
  final List<List<BoardImage>> _pageImages = [[]];
  int _currentPageIndex = 0;
  bool _isSlideDrawerOpen = false;

  bool _isToolbarPinned = true;
  bool _isToolbarVisible = true;
  bool _palmRejectionEnabled = false;

  final List<Stroke> _redoStack = [];

  // O(1) Zero-latency isolated drawing tip notifiers
  final ValueNotifier<Stroke?> activeStrokeNotifier = ValueNotifier<Stroke?>(null);
  final ValueNotifier<List<Offset>> laserTrailNotifier = ValueNotifier<List<Offset>>([]);
  final ValueNotifier<Rect?> selectionMarqueeNotifier = ValueNotifier<Rect?>(null);

  Timer? _laserTimer;
  Timer? _debounceSaveTimer;

  ToolType _currentTool = ToolType.pen;
  Color _selectedColor = const Color(0xFF00FFA3);
  double _strokeWidth = 4.0;
  BoardThemeMode _themeMode = BoardThemeMode.dots;

  Size _screenSize = const Size(1920, 1080);
  int? _selectedStrokeIndex;
  int? _selectedImageIndex;

  BoardController() {
    _loadFromStorage();
  }

  // Getters
  List<Stroke> get strokes => List.unmodifiable(_pages[_currentPageIndex]);
  List<List<Stroke>> get allPages => List.unmodifiable(_pages);
  List<BoardImage> get currentImages => _pageImages[_currentPageIndex];
  List<List<BoardImage>> get allPageImages => List.unmodifiable(_pageImages);
  Stroke? get activeStroke => activeStrokeNotifier.value;
  List<Offset> get laserTrail => laserTrailNotifier.value;
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
  int? get selectedImageIndex => _selectedImageIndex;

  Stroke? get selectedStroke =>
      (_selectedStrokeIndex != null && _selectedStrokeIndex! < _pages[_currentPageIndex].length)
          ? _pages[_currentPageIndex][_selectedStrokeIndex!]
          : null;

  BoardImage? get selectedImage =>
      (_selectedImageIndex != null && _selectedImageIndex! < _pageImages[_currentPageIndex].length)
          ? _pageImages[_currentPageIndex][_selectedImageIndex!]
          : null;

  bool get canUndo => _pages[_currentPageIndex].isNotEmpty || _pageImages[_currentPageIndex].isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  static bool _isPdfHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
  }

  // Load from IndexedDB
  Future<void> _loadFromStorage() async {
    try {
      final jsStrokes = await loadFromIDB(_storageStrokesKey.toJS).toDart;
      final strokesData = jsStrokes.toDart;

      final jsImages = await loadFromIDB(_storageImagesKey.toJS).toDart;
      final imagesData = jsImages.toDart;

      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_pageIndexKey) ?? 0;

      if (strokesData.isNotEmpty || imagesData.isNotEmpty) {
        List<List<Stroke>> loadedStrokes = [[]];
        if (strokesData.isNotEmpty) {
          final List<dynamic> decodedPages = jsonDecode(strokesData);
          loadedStrokes = decodedPages.map((page) {
            final List<dynamic> sList = page as List<dynamic>;
            return sList.map((s) => Stroke.fromMap(s as Map<String, dynamic>)).toList();
          }).toList();
        }

        List<List<BoardImage>> loadedImages = [[]];
        if (imagesData.isNotEmpty) {
          final List<dynamic> decodedImgPages = jsonDecode(imagesData);
          loadedImages = decodedImgPages.map((page) {
            final List<dynamic> imgList = page as List<dynamic>;
            return imgList
                .map((i) => BoardImage.fromMap(i as Map<String, dynamic>))
                .where((img) => !_isPdfHeader(img.bytes))
                .toList();
          }).toList();
        }

        final int maxLen = loadedStrokes.length > loadedImages.length ? loadedStrokes.length : loadedImages.length;
        _pages.clear();
        _pageImages.clear();

        for (int i = 0; i < maxLen; i++) {
          _pages.add(i < loadedStrokes.length ? loadedStrokes[i] : []);
          _pageImages.add(i < loadedImages.length ? loadedImages[i] : []);
        }

        _currentPageIndex = (savedIndex < _pages.length) ? savedIndex : 0;
        notifyListeners();
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
    _debounceSaveTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final serializedStrokes = _pages.map((p) => p.map((s) => s.toMap()).toList()).toList();
        await saveToIDB(_storageStrokesKey.toJS, jsonEncode(serializedStrokes).toJS).toDart;

        final serializedImages = _pageImages.map((p) => p.map((i) => i.toMap()).toList()).toList();
        await saveToIDB(_storageImagesKey.toJS, jsonEncode(serializedImages).toJS).toDart;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_pageIndexKey, _currentPageIndex);
      } catch (_) {}
    });
  }

  // Media Import Logic
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

        final dataUrl = result.toString();
        final base64Content = dataUrl.split(',').last;
        final fileName = file.name.toLowerCase();

        if (fileName.endsWith('.pdf')) {
          await _convertAndImportPdf(base64Content);
        } else {
          final imageBytes = base64Decode(base64Content);
          _addImageToCurrentSlide(imageBytes);
        }
      });

      reader.readAsDataURL(file);
    });
  }

  Future<void> _convertAndImportPdf(String base64Data) async {
    try {
      final jsResult = await renderPdfToImages(base64Data.toJS).toDart;
      final jsonString = jsResult.toDart;
      final List<dynamic> pngBase64List = jsonDecode(jsonString);

      if (pngBase64List.isEmpty) return;

      for (int i = 0; i < pngBase64List.length; i++) {
        final bytes = base64Decode(pngBase64List[i] as String);
        if (i == 0 && _pages[_currentPageIndex].isEmpty && _pageImages[_currentPageIndex].isEmpty) {
          _addImageToCurrentSlide(bytes, autoFit: true);
        } else {
          _pages.add([]);
          _pageImages.add([]);
          _currentPageIndex = _pages.length - 1;
          _addImageToCurrentSlide(bytes, autoFit: true);
        }
      }
      _scheduleAutoSave();
      notifyListeners();
    } catch (_) {}
  }

  void _addImageToCurrentSlide(Uint8List bytes, {bool autoFit = false}) {
    if (_isPdfHeader(bytes)) return;

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
      isSelected: false,
    );

    _pageImages[_currentPageIndex].add(newImage);
    _scheduleAutoSave();
    notifyListeners();
  }

  // Marquee Selection & Point Selection
  void startSelection(Offset pos) {
    _deselectAll();
    selectionMarqueeNotifier.value = Rect.fromPoints(pos, pos);
  }

  void updateSelectionMarquee(Offset start, Offset current) {
    selectionMarqueeNotifier.value = Rect.fromPoints(start, current);
  }

  void finalizeSelectionMarquee(Rect rect) {
    selectionMarqueeNotifier.value = null;
    if (rect.width.abs() < 5 && rect.height.abs() < 5) {
      _selectAtPoint(rect.topLeft);
      return;
    }

    final normalized = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.right > rect.left ? rect.right : rect.left,
      rect.bottom > rect.top ? rect.bottom : rect.top,
    );

    // Test images / PDF slides first
    final images = _pageImages[_currentPageIndex];
    for (int i = images.length - 1; i >= 0; i--) {
      final imgRect = Rect.fromLTWH(images[i].position.dx, images[i].position.dy, images[i].width, images[i].height);
      if (normalized.overlaps(imgRect)) {
        selectImage(i);
        return;
      }
    }

    // Test ink strokes
    final strokesList = _pages[_currentPageIndex];
    for (int i = strokesList.length - 1; i >= 0; i--) {
      if (strokesList[i].intersectsRect(normalized)) {
        strokesList[i].isSelected = true;
        _selectedStrokeIndex = i;
        notifyListeners();
        return;
      }
    }
  }

  void _selectAtPoint(Offset pos) {
    // Check images/PDF plates first
    final images = _pageImages[_currentPageIndex];
    for (int i = images.length - 1; i >= 0; i--) {
      final imgRect = Rect.fromLTWH(images[i].position.dx, images[i].position.dy, images[i].width, images[i].height);
      if (imgRect.contains(pos)) {
        selectImage(i);
        return;
      }
    }

    // Check drawings
    final strokesList = _pages[_currentPageIndex];
    for (int i = strokesList.length - 1; i >= 0; i--) {
      if (strokesList[i].containsOffset(pos)) {
        strokesList[i].isSelected = true;
        _selectedStrokeIndex = i;
        notifyListeners();
        return;
      }
    }
    _deselectAll();
    notifyListeners();
  }

  void _deselectAll() {
    for (final s in _pages[_currentPageIndex]) {
      s.isSelected = false;
    }
    for (final img in _pageImages[_currentPageIndex]) {
      img.isSelected = false;
    }
    _selectedStrokeIndex = null;
    _selectedImageIndex = null;
  }

  void selectImage(int index) {
    _deselectAll();
    if (index >= 0 && index < _pageImages[_currentPageIndex].length) {
      _pageImages[_currentPageIndex][index].isSelected = true;
      _selectedImageIndex = index;
    }
    notifyListeners();
  }

  void moveSelectedElement(Offset delta) {
    if (_selectedStrokeIndex != null && _selectedStrokeIndex! < _pages[_currentPageIndex].length) {
      _pages[_currentPageIndex][_selectedStrokeIndex!].translate(delta);
      _scheduleAutoSave();
      notifyListeners();
    } else if (_selectedImageIndex != null && _selectedImageIndex! < _pageImages[_currentPageIndex].length) {
      _pageImages[_currentPageIndex][_selectedImageIndex!].position += delta;
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void resizeSelectedElement(double deltaWidth, double deltaHeight) {
    if (_selectedStrokeIndex != null && _selectedStrokeIndex! < _pages[_currentPageIndex].length) {
      _pages[_currentPageIndex][_selectedStrokeIndex!].scale(deltaWidth, deltaHeight);
      _scheduleAutoSave();
      notifyListeners();
    } else if (_selectedImageIndex != null && _selectedImageIndex! < _pageImages[_currentPageIndex].length) {
      final img = _pageImages[_currentPageIndex][_selectedImageIndex!];
      img.width = (img.width + deltaWidth).clamp(60.0, _screenSize.width * 3.0);
      img.height = (img.height + deltaHeight).clamp(60.0, _screenSize.height * 3.0);
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void deleteSelectedElement() {
    if (_selectedStrokeIndex != null && _selectedStrokeIndex! < _pages[_currentPageIndex].length) {
      _redoStack.add(_pages[_currentPageIndex].removeAt(_selectedStrokeIndex!));
      _selectedStrokeIndex = null;
      _scheduleAutoSave();
      notifyListeners();
    } else if (_selectedImageIndex != null && _selectedImageIndex! < _pageImages[_currentPageIndex].length) {
      _pageImages[_currentPageIndex].removeAt(_selectedImageIndex!);
      _selectedImageIndex = null;
      _scheduleAutoSave();
      notifyListeners();
    }
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
      _deselectAll();
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
    activeStrokeNotifier.value = null;
    _deselectAll();
    _scheduleAutoSave();
    notifyListeners();
  }

  void goToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _currentPageIndex = index;
      _redoStack.clear();
      activeStrokeNotifier.value = null;
      _deselectAll();
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
    activeStrokeNotifier.value = null;
    _deselectAll();
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
    activeStrokeNotifier.value = null;
    _deselectAll();
    _scheduleAutoSave();
    notifyListeners();
  }

  void previousPage() {
    if (_currentPageIndex > 0) {
      _currentPageIndex--;
      _redoStack.clear();
      activeStrokeNotifier.value = null;
      _deselectAll();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // ZERO-LATENCY INKING PIPELINE (O(1) Direct Path)
  // ----------------------------------------------------
  void startStroke(Offset position, double pressure, [ui.PointerDeviceKind? kind]) {
    if (_currentTool == ToolType.select) return;
    if (_palmRejectionEnabled && kind == ui.PointerDeviceKind.touch) return;

    if (_currentTool == ToolType.laser) {
      laserTrailNotifier.value = [position];
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

    activeStrokeNotifier.value = Stroke(
      points: [StrokePoint(offset: position, pressure: effectivePressure)],
      color: strokeColor,
      strokeWidth: effectiveWidth,
      tool: _currentTool,
    );
  }

  void appendPoint(Offset position, double pressure, [ui.PointerDeviceKind? kind]) {
    if (_currentTool == ToolType.select) return;
    if (_palmRejectionEnabled && kind == ui.PointerDeviceKind.touch) return;

    if (_currentTool == ToolType.laser) {
      final list = List<Offset>.from(laserTrailNotifier.value)..add(position);
      if (list.length > 25) list.removeAt(0);
      laserTrailNotifier.value = list;
      return;
    }

    final active = activeStrokeNotifier.value;
    if (active == null) return;
    final effectivePressure = pressure > 0 ? pressure : 0.5;

    if (_isGeometricTool(_currentTool)) {
      if (active.points.length == 1) {
        active.points.add(StrokePoint(offset: position, pressure: effectivePressure));
      } else {
        active.points[1] = StrokePoint(offset: position, pressure: effectivePressure);
      }
    } else {
      active.points.add(StrokePoint(offset: position, pressure: effectivePressure));
    }

    activeStrokeNotifier.value = active;
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
        if (laserTrailNotifier.value.isNotEmpty) {
          final list = List<Offset>.from(laserTrailNotifier.value)..removeAt(0);
          laserTrailNotifier.value = list;
        } else {
          timer.cancel();
        }
      });
      return;
    }

    final finishedStroke = activeStrokeNotifier.value;
    if (finishedStroke != null && finishedStroke.points.isNotEmpty) {
      _pages[_currentPageIndex].add(finishedStroke);
      activeStrokeNotifier.value = null;
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void undo() {
    if (_pages[_currentPageIndex].isNotEmpty) {
      _redoStack.add(_pages[_currentPageIndex].removeLast());
      _deselectAll();
      _scheduleAutoSave();
      notifyListeners();
    } else if (_pageImages[_currentPageIndex].isNotEmpty) {
      _pageImages[_currentPageIndex].removeLast();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _pages[_currentPageIndex].add(_redoStack.removeLast());
      _deselectAll();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void clearCanvas() {
    _pages[_currentPageIndex].clear();
    _pageImages[_currentPageIndex].clear();
    _redoStack.clear();
    activeStrokeNotifier.value = null;
    laserTrailNotifier.value = [];
    _deselectAll();
    _scheduleAutoSave();
    notifyListeners();
  }
}