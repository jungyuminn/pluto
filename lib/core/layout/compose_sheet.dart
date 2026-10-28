import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';

double composeSheetBottomOf(BuildContext context, {double covered = 16}) {
  final insets = MediaQuery.viewInsetsOf(context).bottom;
  final extra = (MediaQuery.viewPaddingOf(context).bottom - covered)
      .clamp(0.0, double.infinity);
  return insets > extra ? insets : extra;
}

Future<T?> showComposeSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool enableDrag = true,
  double maxWidth = PcLayout.pcAddEventWidth,
}) async {
  if (!PcLayout.isPc) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      showDragHandle: false,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.barrier,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.barrier,
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(context).height - 48,
            ),
            child: Material(
              color: Colors.transparent,
              child: builder(context),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final t = Curves.easeOutCubic.transform(animation.value);
      return Opacity(
        opacity: t,
        child: Transform.scale(
          scale: lerpDouble(0.94, 1, t)!,
          child: child,
        ),
      );
    },
  );
}

Future<T?> showKeyboardComposer<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = PcLayout.pcAddEventWidth,
}) {
  if (PcLayout.isPc) {
    return showComposeSheet<T>(
      context,
      builder: builder,
      maxWidth: maxWidth,
    );
  }
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _KeyboardComposer(
        animation: animation,
        builder: builder,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

class KeyboardComposerScope extends InheritedWidget {
  const KeyboardComposerScope({
    required this.pop,
    required super.child,
  });

  final void Function([Object? result]) pop;

  static void close<T>(BuildContext context, [T? result]) {
    final scope =
        context.getInheritedWidgetOfExactType<KeyboardComposerScope>();
    if (scope != null) {
      scope.pop(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  bool updateShouldNotify(KeyboardComposerScope oldWidget) =>
      pop != oldWidget.pop;
}

class _KeyboardComposer extends StatefulWidget {
  const _KeyboardComposer({
    required this.animation,
    required this.builder,
  });

  final Animation<double> animation;
  final WidgetBuilder builder;

  @override
  State<_KeyboardComposer> createState() => _KeyboardComposerState();
}

class _KeyboardComposerState extends State<_KeyboardComposer>
    with SingleTickerProviderStateMixin {
  var _shown = false;
  var _closing = false;
  var _sheetHeight = 220.0;
  final _sheetKey = GlobalKey();
  late final AnimationController _dim;
  late final Animation<double> _dimIn;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
    _dim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _dimIn = CurvedAnimation(parent: _dim, curve: Curves.easeOutCubic);
    Future<void>.delayed(const Duration(milliseconds: 400), _reveal);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    _dim.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _reveal() {
    if (!mounted || _shown) return;
    setState(() => _shown = true);
    _dim.forward();
  }

  double _extraOf(BuildContext context) {
    return (MediaQuery.viewPaddingOf(context).bottom - 16)
        .clamp(0.0, double.infinity);
  }

  void _measure() {
    final box = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.height > 0) {
      _sheetHeight = box.size.height;
    }
  }

  void _requestClose([Object? result]) {
    if (_closing) return;
    _closing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    _measure();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final extra = _extraOf(context);
    if (insets > extra) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _requestClose(result);
      },
      child: KeyboardComposerScope(
        pop: _requestClose,
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.animation, _dimIn]),
          builder: (context, child) {
            final closing =
                widget.animation.status == AnimationStatus.reverse;
            final t = closing
                ? 1 - Curves.easeInCubic.transform(widget.animation.value)
                : 0.0;
            return Stack(
              fit: StackFit.expand,
              children: [
                ModalBarrier(
                  color: Color.fromRGBO(
                    0,
                    0,
                    0,
                    AppColors.barrierOpacity * _dimIn.value * (1 - t),
                  ),
                  dismissible: !_closing,
                  onDismiss: _requestClose,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Offstage(
                    offstage: !_shown,
                    child: Opacity(
                      opacity: _dimIn.value,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          (1 - _dimIn.value) * 12 + t * _sheetHeight,
                        ),
                        child: KeyedSubtree(
                          key: _sheetKey,
                          child: Material(
                            color: Colors.transparent,
                            child: widget.builder(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
