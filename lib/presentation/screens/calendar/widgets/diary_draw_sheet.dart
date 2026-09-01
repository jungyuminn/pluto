import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<DiaryDrawResult?> showDiaryDrawSheet(
  BuildContext context, {
  String? backgroundPath,
}) {
  final captured = MediaQueryData.fromView(View.of(context));
  return Navigator.of(context, rootNavigator: true).push<DiaryDrawResult>(
    _DiaryDrawRoute(
      mediaQuery: captured.copyWith(
        viewInsets: EdgeInsets.zero,
        padding: captured.viewPadding,
      ),
      builder: (context) => DiaryDrawSheet(backgroundPath: backgroundPath),
    ),
  );
}

class _DiaryDrawRoute<T> extends PageRouteBuilder<T> {
  _DiaryDrawRoute({
    required this.mediaQuery,
    required WidgetBuilder builder,
  }) : super(
          opaque: true,
          fullscreenDialog: false,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return MediaQuery(
              data: mediaQuery,
              child: builder(context),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );

  final MediaQueryData mediaQuery;

  @override
  bool get barrierDismissible => false;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;
}

class DiaryDrawResult {
  const DiaryDrawResult.image(this.path, this.name) : cleared = false;
  const DiaryDrawResult.cleared()
      : path = null,
        name = null,
        cleared = true;

  final String? path;
  final String? name;
  final bool cleared;
}

class DiaryPhotoSlot {
  static const height = 340.0;
  static const formPad = 20.0;
  static const imagePad = EdgeInsets.fromLTRB(8, 8, 8, 14);

  static double aspectOf(BuildContext context) {
    final outer = MediaQuery.sizeOf(context).width - formPad * 2;
    final innerW = (outer - imagePad.horizontal).clamp(1.0, 4096.0);
    final innerH = height - imagePad.vertical;
    return innerW / innerH;
  }

  static bool isDrawingPath(String path) {
    return path.contains('diary_draw_') || path.contains('_drawing.png');
  }
}

class DiaryDrawSheet extends StatefulWidget {
  const DiaryDrawSheet({super.key, this.backgroundPath});

  final String? backgroundPath;

  @override
  State<DiaryDrawSheet> createState() => _DiaryDrawSheetState();
}

class _DiaryDrawSheetState extends State<DiaryDrawSheet> {
  static const _black = Color(0xFF1A1A1A);
  static const _inks = <Color>[
    Color(0xFFE24B4B),
    Color(0xFFF07820),
    Color(0xFFF5C400),
    Color(0xFF8BC34A),
    Color(0xFF2E9B57),
    Color(0xFF26C6B0),
    Color(0xFF42B6F0),
    Color(0xFF2F62E8),
    Color(0xFF2A348F),
    Color(0xFF7E57C2),
    Color(0xFFD81B60),
    Color(0xFFF48FB1),
    Color(0xFFFFB074),
    Color(0xFF8D5A3A),
    _black,
    Color(0xFF78909C),
    Color(0xFFFFFFFF),
  ];
  static const _widths = <double>[1, 2, 4, 8, 12, 18, 26];
  static const _minZoom = 1.0;
  static const _maxZoom = 5.0;
  static const _zoomStep = 1.25;

  final _paintKey = GlobalKey();
  final _viewerKey = GlobalKey();
  final _tx = TransformationController();
  final _pointers = <int, Offset>{};
  final _strokes = <_DrawStroke>[];
  final _redo = <_DrawStroke>[];
  ui.Image? _background;
  var _color = _black;
  var _width = _widths[3];
  var _tool = _DrawTool.pen;
  var _penKind = _PenKind.brush;
  var _tick = 0;
  var _saving = false;
  var _filling = false;
  var _drawing = false;
  int? _pointer;
  Offset? _zoomTap;
  int? _zoomPointer;
  var _zoomMoved = false;
  var _zoomDrag = 0.0;
  var _viewport = Size.zero;
  Offset? _eraserCursor;

  BoxFit get _backgroundFit {
    final path = widget.backgroundPath;
    if (path != null && DiaryPhotoSlot.isDrawingPath(path)) {
      return BoxFit.cover;
    }
    return BoxFit.contain;
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.primaryFocus?.unfocus();
    _loadBackground();
  }

  @override
  void dispose() {
    _background?.dispose();
    _disposeFills(_strokes);
    _disposeFills(_redo);
    _tx.dispose();
    super.dispose();
  }

  void _disposeFills(List<_DrawStroke> strokes) {
    for (final stroke in strokes) {
      stroke.fillImage?.dispose();
    }
  }

  void _discardRedo() {
    _disposeFills(_redo);
    _redo.clear();
  }

  Future<void> _loadBackground() async {
    final path = widget.backgroundPath;
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) return;
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() {
      _background?.dispose();
      _background = frame.image;
    });
  }

  void _hideEraser() {
    _eraserCursor = null;
  }

  bool get _erasing => _tool == _DrawTool.eraser;

  double get _eraserSize => math.max(8.0, _strokeWidth() * _zoom);

  void _showEraserAt(Offset local) {
    if (!_erasing || _pointers.length >= 2) {
      _eraserCursor = null;
      return;
    }
    _eraserCursor = local;
  }

  double get _zoom => _tx.value.getMaxScaleOnAxis();

  bool get _showZoomHint =>
      _zoom > _minZoom + 0.01 ||
      _tool == _DrawTool.zoomIn ||
      _tool == _DrawTool.zoomOut;

  void _clearPendingZoom() {
    _zoomTap = null;
    _zoomPointer = null;
    _zoomMoved = false;
    _zoomDrag = 0;
  }

  bool get _zoomTool =>
      _tool == _DrawTool.zoomIn || _tool == _DrawTool.zoomOut;

  Color _strokeColor() => _color;

  double _strokeWidth() => _width;

  Offset _sceneOf(Offset viewport) => _tx.toScene(viewport);

  Matrix4 _constrained(Matrix4 matrix) {
    final scale = matrix.getMaxScaleOnAxis();
    final view = _viewport;
    if (view.isEmpty || scale <= _minZoom + 0.001) {
      return Matrix4.identity();
    }
    final minTx = view.width * (1 - scale);
    final minTy = view.height * (1 - scale);
    final tx = matrix.storage[12].clamp(minTx, 0.0);
    final ty = matrix.storage[13].clamp(minTy, 0.0);
    final next = Matrix4.diagonal3Values(scale, scale, 1);
    next.setTranslationRaw(tx, ty, 0);
    return next;
  }

  void _setTransform(Matrix4 matrix) {
    _tx.value = _constrained(matrix);
  }

  void _zoomAt(Offset scenePoint, double factor) {
    final current = _zoom;
    final next = (current * factor).clamp(_minZoom, _maxZoom);
    if (next <= _minZoom + 0.001) {
      _setTransform(Matrix4.identity());
      setState(() {});
      return;
    }
    final box = _viewport;
    if (box.isEmpty) return;
    final center = Offset(box.width / 2, box.height / 2);
    _setTransform(
      Matrix4.identity()
        ..translate(center.dx, center.dy)
        ..scale(next)
        ..translate(-scenePoint.dx, -scenePoint.dy),
    );
    setState(() {});
  }

  void _cancelOpenStroke() {
    if (!_drawing) return;
    if (_strokes.isNotEmpty) {
      final last = _strokes.removeLast();
      last.fillImage?.dispose();
    }
    _drawing = false;
    _pointer = null;
    setState(() => _tick++);
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2) {
      _clearPendingZoom();
      _cancelOpenStroke();
      _hideEraser();
      return;
    }
    _showEraserAt(event.localPosition);
    final scene = _sceneOf(event.localPosition);
    if (_tool == _DrawTool.fill) {
      _fillAt(scene);
      return;
    }
    if (_zoomTool) {
      _zoomPointer = event.pointer;
      _zoomTap = scene;
      _zoomMoved = false;
      return;
    }
    _pointer = event.pointer;
    _drawing = true;
    _discardRedo();
    final freehand = _tool == _DrawTool.pen || _tool == _DrawTool.eraser;
    _strokes.add(
      _DrawStroke(
        tool: _tool,
        color: _strokeColor(),
        width: _strokeWidth(),
        points: freehand ? [scene] : [scene, scene],
        penKind: _penKind,
        seed: Object.hash(_tick, scene.dx.round(), scene.dy.round()),
      ),
    );
    setState(() => _tick++);
  }

  void _onPointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2) {
      _clearPendingZoom();
      _hideEraser();
      if (_zoom > _minZoom + 0.01) {
        _setTransform(
          Matrix4.translationValues(event.delta.dx, event.delta.dy, 0)
              .multiplied(_tx.value),
        );
      }
      setState(() {});
      return;
    }
    _showEraserAt(event.localPosition);
    if (_zoomPointer == event.pointer && _zoomTap != null) {
      _zoomDrag += event.localDelta.distance;
      if (_zoomDrag > 12) _zoomMoved = true;
      return;
    }
    if (_pointer != event.pointer || _strokes.isEmpty || !_drawing) return;
    final scene = _sceneOf(event.localPosition);
    final stroke = _strokes.last;
    if (stroke.tool == _DrawTool.fill) return;
    if (stroke.tool == _DrawTool.pen || stroke.tool == _DrawTool.eraser) {
      stroke.points.add(scene);
    } else {
      stroke.points[1] = scene;
    }
    setState(() => _tick++);
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_zoomPointer == event.pointer) {
      final tap = _zoomTap;
      final moved = _zoomMoved;
      _clearPendingZoom();
      if (tap != null && !moved && _pointers.isEmpty) {
        if (_tool == _DrawTool.zoomIn) {
          _zoomAt(tap, _zoomStep);
        } else if (_tool == _DrawTool.zoomOut) {
          _zoomAt(tap, 1 / _zoomStep);
        }
      }
      if (_pointers.isEmpty) _hideEraser();
      setState(() {});
      return;
    }
    if (_pointer != event.pointer) {
      if (_pointers.isEmpty) _hideEraser();
      return;
    }
    _pointer = null;
    _drawing = false;
    if (_pointers.isEmpty) _hideEraser();
    setState(() {});
  }

  void _onPointerCancel(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_zoomPointer == event.pointer) _clearPendingZoom();
    if (_pointer == event.pointer) {
      _pointer = null;
      _drawing = false;
    }
    if (_pointers.isEmpty) _hideEraser();
    setState(() {});
  }

  void _onPointerHover(PointerEvent event) {
    if (!_erasing) return;
    setState(() => _showEraserAt(event.localPosition));
  }

  Future<void> _fillAt(Offset local) async {
    if (_filling) return;
    _filling = true;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final size = _paintKey.currentContext?.size;
      if (boundary == null || size == null || size.isEmpty) return;
      const ratio = 2.0;
      final snapshot = await boundary.toImage(pixelRatio: ratio);
      final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = snapshot.width;
      final height = snapshot.height;
      snapshot.dispose();
      if (bytes == null || !mounted) return;
      final x = (local.dx / size.width * width).floor().clamp(0, width - 1);
      final y = (local.dy / size.height * height).floor().clamp(0, height - 1);
      final overlay = _floodFillPixels(
        src: bytes.buffer.asUint8List(),
        width: width,
        height: height,
        x: x,
        y: y,
        color: _color,
      );
      if (overlay == null || !mounted) return;
      final image = await _imageFromPixels(overlay, width, height);
      if (!mounted) {
        image.dispose();
        return;
      }
      _discardRedo();
      _strokes.add(
        _DrawStroke(
          tool: _DrawTool.fill,
          color: _color,
          width: _width,
          points: const [],
          fillImage: image,
        ),
      );
      setState(() => _tick++);
    } finally {
      _filling = false;
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redo.add(_strokes.removeLast());
      _tick++;
    });
  }

  void _redoStroke() {
    if (_redo.isEmpty) return;
    setState(() {
      _strokes.add(_redo.removeLast());
      _tick++;
    });
  }

  bool get _canClear => _strokes.isNotEmpty || _background != null;

  void _clear() {
    if (!_canClear) return;
    setState(() {
      _disposeFills(_strokes);
      _strokes.clear();
      _discardRedo();
      _background?.dispose();
      _background = null;
      _tick++;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final hadBackground =
        widget.backgroundPath != null && widget.backgroundPath!.isNotEmpty;
    if (_strokes.isEmpty) {
      if (_background != null || !hadBackground) {
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pop(const DiaryDrawResult.cleared());
      return;
    }
    setState(() => _saving = true);
    try {
      final logical = _viewport;
      if (logical.isEmpty) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      final bg = _background;
      final ratio = MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0);
      var outW = math.max(1, (logical.width * ratio).round());
      var outH = math.max(1, (logical.height * ratio).round());
      if (bg != null && bg.width > 0 && bg.height > 0) {
        final bgAspect = bg.width / bg.height;
        final outAspect = outW / outH;
        if ((bgAspect - outAspect).abs() <= 0.03 * outAspect) {
          outW = bg.width;
          outH = bg.height;
        }
      }
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      if (bg != null) {
        paintImage(
          canvas: canvas,
          rect: Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
          image: bg,
          fit: _backgroundFit,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        );
      }
      canvas.save();
      canvas.scale(outW / logical.width, outH / logical.height);
      _BoardPainter(
        strokes: _strokes,
        background: null,
        backgroundFit: _backgroundFit,
        tick: _tick,
        fillPaper: false,
      ).paint(canvas, logical);
      canvas.restore();
      final picture = recorder.endRecording();
      final image = await picture.toImage(outW, outH);
      picture.dispose();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null || !mounted) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      final folder = await getTemporaryDirectory();
      final file = File(
        p.join(
          folder.path,
          'diary_draw_${DateTime.now().microsecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (!mounted) return;
      Navigator.of(context).pop(DiaryDrawResult.image(file.path, 'drawing.png'));
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    const paper = Color(0xFFFFFFFF);
    final padding = MediaQuery.paddingOf(context);

    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colors.background,
        body: Padding(
        padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, padding.bottom + 8),
        child: Column(
          children: [
            Row(
              children: [
                PressBounce(
                  onPressed: () => Navigator.of(context).pop(),
                  color: colors.card,
                  pressedColor: colors.pressed,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 44,
                    width: 72,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppStrings.diaryDrawTitle,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const Spacer(),
                PressBounce(
                  onPressed: _saving ? null : _save,
                  color: colors.accent,
                  pressedColor: Color.lerp(colors.accent, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 44,
                    width: 72,
                    child: Center(
                      child: Text(
                        AppStrings.done,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final aspect = DiaryPhotoSlot.aspectOf(context);
                  var canvasW = constraints.maxWidth;
                  var canvasH = canvasW / aspect;
                  if (canvasH > constraints.maxHeight) {
                    canvasH = constraints.maxHeight;
                    canvasW = canvasH * aspect;
                  }
                  final canvasSize = Size(canvasW, canvasH);
                  if (_viewport != canvasSize) {
                    _viewport = canvasSize;
                  }
                  return Center(
                    child: SizedBox(
                      width: canvasW,
                      height: canvasH,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: paper,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Listener(
                                    key: _viewerKey,
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: _onPointerDown,
                                    onPointerMove: _onPointerMove,
                                    onPointerHover: _onPointerHover,
                                    onPointerUp: _onPointerUp,
                                    onPointerCancel: _onPointerCancel,
                                    child: ClipRect(
                                      child: AnimatedBuilder(
                                        animation: _tx,
                                        builder: (context, child) {
                                          final zoomed =
                                              _zoom > _minZoom + 0.01;
                                          if (!zoomed) return child!;
                                          return Transform(
                                            alignment: Alignment.topLeft,
                                            transform: _tx.value,
                                            filterQuality: FilterQuality.none,
                                            child: child,
                                          );
                                        },
                                        child: RepaintBoundary(
                                          key: _paintKey,
                                          child: CustomPaint(
                                            painter: _BoardPainter(
                                              strokes: _strokes,
                                              background: _background,
                                              backgroundFit: _backgroundFit,
                                              tick: _tick,
                                            ),
                                            size: canvasSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_erasing && _eraserCursor != null)
                                    Positioned(
                                      left: _eraserCursor!.dx - _eraserSize / 2,
                                      top: _eraserCursor!.dy - _eraserSize / 2,
                                      width: _eraserSize,
                                      height: _eraserSize,
                                      child: const IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Color(0xF2FFFFFF),
                                            border: Border.fromBorderSide(
                                              BorderSide(
                                                color: Color(0x661A1A1A),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedSlide(
                                      duration: const Duration(milliseconds: 340),
                                      curve: Curves.easeOutCubic,
                                      offset: _showZoomHint
                                          ? Offset.zero
                                          : const Offset(0, 1.15),
                                      child: AnimatedOpacity(
                                        duration: const Duration(milliseconds: 280),
                                        curve: Curves.easeOut,
                                        opacity: _showZoomHint ? 1 : 0,
                                        child: IgnorePointer(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              12,
                                            ),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color.lerp(
                                                  paper,
                                                  colors.card,
                                                  0.35,
                                                )!
                                                    .withValues(alpha: 0.92),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: Text(
                                                  AppStrings.diaryDrawZoomPanHint,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: font,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: colors.secondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Positioned(
                            top: -8,
                            left: 18,
                            right: 18,
                            height: 28,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _SketchbookRingsPainter(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ToolChip(
                          label: AppStrings.diaryDrawUndo,
                          onPressed: _strokes.isEmpty ? null : _undo,
                        ),
                        _ToolChip(
                          label: AppStrings.diaryDrawRedo,
                          onPressed: _redo.isEmpty ? null : _redoStroke,
                        ),
                        _ToolChip(
                          label: AppStrings.diaryDrawClear,
                          onPressed: _canClear ? _clear : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final width in _widths)
                          _WidthDot(
                            width: width,
                            selected: _width == width,
                            color: _erasing
                                ? const Color(0xFF9CA3AF)
                                : _color,
                            onPressed: () =>
                                setState(() => _width = width),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tool in _DrawTool.values)
                          _ToolChip(
                            label: tool.label,
                            asset: tool.asset(selected: _tool == tool),
                            selected: _tool == tool,
                            onPressed: () {
                              setState(() {
                                _tool = tool;
                                if (tool != _DrawTool.eraser) _hideEraser();
                              });
                            },
                          ),
                      ],
                    ),
                    if (_tool == _DrawTool.pen)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final kind in _PenKind.values)
                              _ToolChip(
                                label: kind.label,
                                selected: _penKind == kind,
                                emphasis: true,
                                onPressed: () =>
                                    setState(() => _penKind = kind),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final ink in _inks)
                          _InkDot(
                            color: ink,
                            selected: !_erasing && _color == ink,
                            onPressed: () {
                              setState(() {
                                _color = ink;
                                if (_erasing) _tool = _DrawTool.pen;
                                if (_tool != _DrawTool.eraser) _hideEraser();
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
          ],
        ),
      ),
      ),
    );
  }
}

enum _DrawTool {
  pen,
  fill,
  line,
  rect,
  oval,
  eraser,
  zoomIn,
  zoomOut,
}

extension on _DrawTool {
  String get label => switch (this) {
        _DrawTool.pen => AppStrings.diaryDrawPen,
        _DrawTool.fill => AppStrings.diaryDrawFill,
        _DrawTool.line => AppStrings.diaryDrawLine,
        _DrawTool.rect => AppStrings.diaryDrawRect,
        _DrawTool.oval => AppStrings.diaryDrawOval,
        _DrawTool.eraser => AppStrings.diaryDrawEraser,
        _DrawTool.zoomIn => AppStrings.diaryDrawZoomIn,
        _DrawTool.zoomOut => AppStrings.diaryDrawZoomOut,
      };

  String? asset({required bool selected}) => switch (this) {
        _DrawTool.pen => selected ? AppIcons.pen : AppIcons.penOutlined,
        _DrawTool.fill =>
          selected ? AppIcons.paintBrush : AppIcons.paintBrushOutlined,
        _DrawTool.line => selected ? AppIcons.line : AppIcons.lineOutlined,
        _DrawTool.rect => selected ? AppIcons.square : AppIcons.squareOutlined,
        _DrawTool.oval => selected ? AppIcons.circle : AppIcons.circleOutlined,
        _DrawTool.eraser => selected ? AppIcons.erase : AppIcons.eraseOutlined,
        _DrawTool.zoomIn => selected ? AppIcons.zoomIn : AppIcons.zoomInOutlined,
        _DrawTool.zoomOut =>
          selected ? AppIcons.zoomOut : AppIcons.zoomOutOutlined,
      };
}

enum _PenKind {
  brush,
  crayon,
  calligraphy,
  watercolor,
  pencil,
  marker,
  highlighter,
  chalk,
  spray,
}

extension on _PenKind {
  String get label => switch (this) {
        _PenKind.brush => AppStrings.diaryDrawBrush,
        _PenKind.crayon => AppStrings.diaryDrawCrayon,
        _PenKind.calligraphy => AppStrings.diaryDrawCalligraphy,
        _PenKind.watercolor => AppStrings.diaryDrawWatercolor,
        _PenKind.pencil => AppStrings.diaryDrawPencil,
        _PenKind.marker => AppStrings.diaryDrawMarker,
        _PenKind.highlighter => AppStrings.diaryDrawHighlighter,
        _PenKind.chalk => AppStrings.diaryDrawChalk,
        _PenKind.spray => AppStrings.diaryDrawSpray,
      };
}

class _DrawStroke {
  _DrawStroke({
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
    this.fillImage,
    this.penKind = _PenKind.brush,
    this.seed = 0,
  });

  final _DrawTool tool;
  final Color color;
  final double width;
  final List<Offset> points;
  final ui.Image? fillImage;
  final _PenKind penKind;
  final int seed;
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.strokes,
    required this.background,
    required this.backgroundFit,
    required this.tick,
    this.fillPaper = true,
  });

  final List<_DrawStroke> strokes;
  final ui.Image? background;
  final BoxFit backgroundFit;
  final int tick;
  final bool fillPaper;

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPaper) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    }
    final image = background;
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: image,
        fit: backgroundFit,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
      );
    }
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in strokes) {
      if (stroke.tool == _DrawTool.fill) {
        _paintStroke(canvas, size, stroke);
      }
    }
    for (final stroke in strokes) {
      if (stroke.tool != _DrawTool.fill) {
        _paintStroke(canvas, size, stroke);
      }
    }
    canvas.restore();
  }

  Paint _paintFor(_DrawStroke stroke) {
    return Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width
      ..style = PaintingStyle.stroke
      ..blendMode =
          stroke.tool == _DrawTool.eraser ? BlendMode.clear : BlendMode.srcOver
      ..color = stroke.tool == _DrawTool.eraser
          ? const Color(0xFFFFFFFF)
          : stroke.color;
  }

  void _paintStroke(Canvas canvas, Size size, _DrawStroke stroke) {
    if (stroke.tool == _DrawTool.fill) {
      final image = stroke.fillImage;
      if (image == null) return;
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: image,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      );
      return;
    }
    final points = stroke.points;
    if (points.isEmpty) return;
    final paint = _paintFor(stroke);
    switch (stroke.tool) {
      case _DrawTool.line:
        canvas.drawLine(points.first, points.last, paint);
      case _DrawTool.rect:
        canvas.drawRect(Rect.fromPoints(points.first, points.last), paint);
      case _DrawTool.oval:
        canvas.drawOval(Rect.fromPoints(points.first, points.last), paint);
      case _DrawTool.pen:
      case _DrawTool.eraser:
        _paintFreehand(canvas, stroke, paint);
      case _DrawTool.fill:
      case _DrawTool.zoomIn:
      case _DrawTool.zoomOut:
        break;
    }
  }

  void _paintFreehand(Canvas canvas, _DrawStroke stroke, Paint paint) {
    if (stroke.tool == _DrawTool.eraser) {
      _paintBrushPath(canvas, stroke, paint);
      return;
    }
    switch (stroke.penKind) {
      case _PenKind.brush:
        _paintBrushPath(canvas, stroke, paint);
      case _PenKind.crayon:
        _paintCrayon(canvas, stroke);
      case _PenKind.calligraphy:
        _paintCalligraphy(canvas, stroke);
      case _PenKind.watercolor:
        _paintWatercolor(canvas, stroke);
      case _PenKind.pencil:
        _paintPencil(canvas, stroke);
      case _PenKind.marker:
        _paintMarker(canvas, stroke);
      case _PenKind.highlighter:
        _paintHighlighter(canvas, stroke);
      case _PenKind.chalk:
        _paintChalk(canvas, stroke);
      case _PenKind.spray:
        _paintSpray(canvas, stroke);
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final mid = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  void _paintBrushPath(Canvas canvas, _DrawStroke stroke, Paint paint) {
    final points = stroke.points;
    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        stroke.width / 2,
        paint
          ..style = PaintingStyle.fill
          ..blendMode = stroke.tool == _DrawTool.eraser
              ? BlendMode.clear
              : BlendMode.srcOver,
      );
      return;
    }
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(_smoothPath(points), paint);
  }

  void _paintMarker(Canvas canvas, _DrawStroke stroke) {
    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width * 1.35
      ..style = PaintingStyle.stroke
      ..color = stroke.color.withValues(alpha: 0.48);
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        paint.strokeWidth / 2,
        paint
          ..style = PaintingStyle.fill
          ..color = stroke.color.withValues(alpha: 0.48),
      );
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  void _paintHighlighter(Canvas canvas, _DrawStroke stroke) {
    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width * 2.1
      ..style = PaintingStyle.stroke
      ..color = stroke.color.withValues(alpha: 0.22);
    if (stroke.points.length == 1) {
      canvas.drawRect(
        Rect.fromCenter(
          center: stroke.points.first,
          width: paint.strokeWidth,
          height: paint.strokeWidth * 0.7,
        ),
        paint
          ..style = PaintingStyle.fill
          ..color = stroke.color.withValues(alpha: 0.22),
      );
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  void _paintChalk(Canvas canvas, _DrawStroke stroke) {
    final ink = Color.lerp(stroke.color, Colors.white, 0.28)!;
    _stampGrain(
      canvas,
      stroke,
      count: 8,
      spread: 1.15,
      radiusMin: 0.1,
      radiusMax: 0.26,
      alphaMin: 0.12,
      alphaMax: 0.38,
      spacing: 0.34,
      color: ink,
    );
  }

  void _paintSpray(Canvas canvas, _DrawStroke stroke) {
    _stampGrain(
      canvas,
      stroke,
      count: 14,
      spread: 2.4,
      radiusMin: 0.05,
      radiusMax: 0.14,
      alphaMin: 0.08,
      alphaMax: 0.32,
      spacing: 0.55,
    );
  }

  void _paintWatercolor(Canvas canvas, _DrawStroke stroke) {
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        stroke.width * 0.9,
        Paint()
          ..isAntiAlias = true
          ..color = stroke.color.withValues(alpha: 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.width * 0.45),
      );
      return;
    }
    final path = _smoothPath(stroke.points);
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * 2.2
        ..color = stroke.color.withValues(alpha: 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.width * 0.55),
    );
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * 1.35
        ..color = stroke.color.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * 0.85
        ..color = stroke.color.withValues(alpha: 0.28),
    );
  }

  void _paintCalligraphy(Canvas canvas, _DrawStroke stroke) {
    final points = stroke.points;
    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        stroke.width * 0.55,
        Paint()
          ..isAntiAlias = true
          ..color = stroke.color,
      );
      return;
    }
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final prev = points[i == 0 ? 0 : i - 1];
      final next = points[i == points.length - 1 ? i : i + 1];
      var dir = next - prev;
      final len = dir.distance;
      dir = len < 0.001 ? const Offset(1, 0) : dir / len;
      final normal = Offset(-dir.dy, dir.dx);
      final gap = i == 0 ? 0.0 : (points[i] - points[i - 1]).distance;
      final speed = (gap / (stroke.width * 1.8)).clamp(0.0, 1.0);
      final half = stroke.width *
          (0.28 + 0.72 * dir.dx.abs() + 0.35 * (1 - speed));
      left.add(points[i] + normal * half);
      right.add(points[i] - normal * half);
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (var i = 1; i < left.length; i++) {
      path.lineTo(left[i].dx, left[i].dy);
    }
    for (var i = right.length - 1; i >= 0; i--) {
      path.lineTo(right[i].dx, right[i].dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = stroke.color,
    );
  }

  void _paintCrayon(Canvas canvas, _DrawStroke stroke) {
    _stampGrain(
      canvas,
      stroke,
      count: 5,
      spread: 0.95,
      radiusMin: 0.16,
      radiusMax: 0.34,
      alphaMin: 0.2,
      alphaMax: 0.48,
      spacing: 0.3,
    );
  }

  void _paintPencil(Canvas canvas, _DrawStroke stroke) {
    final ink = Color.lerp(stroke.color, const Color(0xFF4B5563), 0.22)!;
    _stampGrain(
      canvas,
      stroke,
      count: 7,
      spread: 0.55,
      radiusMin: 0.08,
      radiusMax: 0.18,
      alphaMin: 0.18,
      alphaMax: 0.42,
      spacing: 0.22,
      color: ink,
    );
    if (stroke.points.length < 2) return;
    canvas.drawPath(
      _smoothPath(stroke.points),
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1.0, stroke.width * 0.38)
        ..color = ink.withValues(alpha: 0.55),
    );
  }

  void _stampGrain(
    Canvas canvas,
    _DrawStroke stroke, {
    required int count,
    required double spread,
    required double radiusMin,
    required double radiusMax,
    required double alphaMin,
    required double alphaMax,
    required double spacing,
    Color? color,
  }) {
    final ink = color ?? stroke.color;
    final paint = Paint()..isAntiAlias = true;
    final points = stroke.points;
    var k = 0;

    void stamp(Offset p) {
      final rng = math.Random(stroke.seed + k * 9176);
      k++;
      for (var n = 0; n < count; n++) {
        final ox = (rng.nextDouble() - 0.5) * stroke.width * spread;
        final oy = (rng.nextDouble() - 0.5) * stroke.width * spread;
        final r = stroke.width *
            (radiusMin + rng.nextDouble() * (radiusMax - radiusMin));
        final a = alphaMin + rng.nextDouble() * (alphaMax - alphaMin);
        canvas.drawCircle(
          p + Offset(ox, oy),
          r,
          paint..color = ink.withValues(alpha: a),
        );
      }
    }

    if (points.length == 1) {
      stamp(points.first);
      return;
    }
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final dist = (b - a).distance;
      final steps = math.max(1, (dist / (stroke.width * spacing)).ceil());
      for (var s = 1; s <= steps; s++) {
        stamp(Offset.lerp(a, b, s / steps)!);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.tick != tick ||
        oldDelegate.background != background ||
        oldDelegate.backgroundFit != backgroundFit ||
        oldDelegate.fillPaper != fillPaper;
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.emphasis = false,
    this.asset,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool emphasis;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final icon = asset;
    return Semantics(
      button: true,
      label: label,
      child: PressBounce(
        onPressed: onPressed,
        color: selected
            ? (emphasis
                ? Color.lerp(colors.selected, colors.text, 0.08)!
                : colors.selected)
            : colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: icon == null ? 12 : 10,
            vertical: 10,
          ),
          child: icon == null
              ? Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: onPressed == null ? colors.muted : colors.text,
                  ),
                )
              : ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    onPressed == null ? colors.muted : colors.text,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    icon,
                    width: 20,
                    height: 20,
                  ),
                ),
        ),
      ),
    );
  }
}

class _InkDot extends StatefulWidget {
  const _InkDot({
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_InkDot> createState() => _InkDotState();
}

class _InkDotState extends State<_InkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _check;

  @override
  void initState() {
    super.initState();
    _check = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    if (widget.selected) _check.forward();
  }

  @override
  void didUpdateWidget(covariant _InkDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _check.forward(from: 0);
    } else if (!widget.selected && oldWidget.selected) {
      _check.value = 0;
    }
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final light = widget.color.computeLuminance() > 0.55;
    return PressBounce(
      onPressed: widget.onPressed,
      color: Colors.transparent,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: light ? colors.muted : colors.border,
            width: 1,
          ),
        ),
        child: AnimatedBuilder(
          animation: _check,
          builder: (context, child) {
            return CustomPaint(
              painter: _CheckPainter(
                progress: Curves.easeOutCubic.transform(_check.value),
                color: light ? const Color(0xFF1A1A1A) : Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.isEmpty) return;
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.70)
      ..lineTo(size.width * 0.76, size.height * 0.32);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SketchbookRingsPainter extends CustomPainter {
  const _SketchbookRingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final count = (size.width / 26).floor().clamp(7, 13);
    final gap = size.width / count;
    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8B95A5);
    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = const Color(0xFFE8ECF1);
    final hole = Paint()..color = const Color(0xFFD2D6DE);
    final holeInner = Paint()..color = const Color(0xFFFFFFFF);

    for (var i = 0; i < count; i++) {
      final x = gap * (i + 0.5);
      final cy = size.height * 0.48;
      final ring = Rect.fromCenter(
        center: Offset(x, cy),
        width: 9,
        height: 22,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, cy + 6), width: 5.6, height: 5.6),
        hole,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, cy + 6), width: 3.1, height: 3.1),
        holeInner,
      );
      canvas.drawOval(ring, metal);
      canvas.drawArc(ring.deflate(1.35), -2.0, 1.15, false, shine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WidthDot extends StatelessWidget {
  const _WidthDot({
    required this.width,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final double width;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = (8.0 + width * 0.62).clamp(9.0, 22.0);
    return PressBounce(
      onPressed: onPressed,
      color: selected ? colors.selected : colors.card,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: value ?? color,
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<ui.Image> _imageFromPixels(Uint8List pixels, int width, int height) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

int _channel(double value) => (value * 255.0).round().clamp(0, 255);

bool _nearColor(Uint8List src, int i, int r, int g, int b, int a) {
  const tol = 20;
  return (src[i] - r).abs() <= tol &&
      (src[i + 1] - g).abs() <= tol &&
      (src[i + 2] - b).abs() <= tol &&
      (src[i + 3] - a).abs() <= tol;
}

Uint8List? _floodFillPixels({
  required Uint8List src,
  required int width,
  required int height,
  required int x,
  required int y,
  required Color color,
}) {
  final fillR = _channel(color.r);
  final fillG = _channel(color.g);
  final fillB = _channel(color.b);
  final fillA = _channel(color.a);
  final start = (y * width + x) * 4;
  final targetR = src[start];
  final targetG = src[start + 1];
  final targetB = src[start + 2];
  final targetA = src[start + 3];
  if (_nearColor(src, start, fillR, fillG, fillB, fillA)) return null;

  final out = Uint8List(width * height * 4);
  final seen = Uint8List(width * height);
  final stackX = <int>[x];
  final stackY = <int>[y];

  bool matches(int px, int py) {
    return _nearColor(
      src,
      (py * width + px) * 4,
      targetR,
      targetG,
      targetB,
      targetA,
    );
  }

  while (stackX.isNotEmpty) {
    var cx = stackX.removeLast();
    final cy = stackY.removeLast();
    if (seen[cy * width + cx] == 1) continue;
    while (cx > 0 && seen[cy * width + cx - 1] == 0 && matches(cx - 1, cy)) {
      cx--;
    }
    var spanUp = false;
    var spanDown = false;
    while (cx < width && seen[cy * width + cx] == 0 && matches(cx, cy)) {
      seen[cy * width + cx] = 1;
      final i = (cy * width + cx) * 4;
      out[i] = fillR;
      out[i + 1] = fillG;
      out[i + 2] = fillB;
      out[i + 3] = fillA;
      if (cy > 0) {
        if (seen[(cy - 1) * width + cx] == 0 && matches(cx, cy - 1)) {
          if (!spanUp) {
            stackX.add(cx);
            stackY.add(cy - 1);
            spanUp = true;
          }
        } else {
          spanUp = false;
        }
      }
      if (cy < height - 1) {
        if (seen[(cy + 1) * width + cx] == 0 && matches(cx, cy + 1)) {
          if (!spanDown) {
            stackX.add(cx);
            stackY.add(cy + 1);
            spanDown = true;
          }
        } else {
          spanDown = false;
        }
      }
      cx++;
    }
  }
  _dilateFill(
    out,
    width,
    height,
    fillR,
    fillG,
    fillB,
    fillA,
    radius: 3,
  );
  return out;
}

void _dilateFill(
  Uint8List out,
  int width,
  int height,
  int fillR,
  int fillG,
  int fillB,
  int fillA, {
  required int radius,
}) {
  const neighbors = <List<int>>[
    [-1, -1],
    [0, -1],
    [1, -1],
    [-1, 0],
    [1, 0],
    [-1, 1],
    [0, 1],
    [1, 1],
  ];
  for (var step = 0; step < radius; step++) {
    final extra = <int>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (out[(y * width + x) * 4 + 3] == 0) continue;
        for (final offset in neighbors) {
          final nx = x + offset[0];
          final ny = y + offset[1];
          if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
          final ni = (ny * width + nx) * 4;
          if (out[ni + 3] == 0) extra.add(ni);
        }
      }
    }
    for (final ni in extra) {
      out[ni] = fillR;
      out[ni + 1] = fillG;
      out[ni + 2] = fillB;
      out[ni + 3] = fillA;
    }
  }
}
