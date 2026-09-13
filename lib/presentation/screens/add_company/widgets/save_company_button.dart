import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class SaveCompanyButton extends StatefulWidget {
  const SaveCompanyButton({
    super.key,
    required this.onPressed,
    required this.color,
  });

  final VoidCallback onPressed;
  final Color color;

  static const size = 44.0;
  static const _iconSize = 22.0;

  @override
  State<SaveCompanyButton> createState() => _SaveCompanyButtonState();
}

class _SaveCompanyButtonState extends State<SaveCompanyButton> {
  static final _active = <_SaveCompanyButtonState>[];

  @override
  void initState() {
    super.initState();
    if (!PcLayout.isPc) return;
    _active.add(this);
    if (_active.length == 1) {
      HardwareKeyboard.instance.addHandler(_onGlobalKey);
    }
  }

  @override
  void dispose() {
    if (PcLayout.isPc) {
      _active.remove(this);
      if (_active.isEmpty) {
        HardwareKeyboard.instance.removeHandler(_onGlobalKey);
      }
    }
    super.dispose();
  }

  static bool _onGlobalKey(KeyEvent event) {
    if (_active.isEmpty) return false;
    return _active.last._handle(event);
  }

  bool _handle(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return false;
    }
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight)) {
      return false;
    }
    if (_keepEnterInField()) return false;
    widget.onPressed();
    return true;
  }

  bool _keepEnterInField() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    final state = context is StatefulElement && context.state is EditableTextState
        ? context.state as EditableTextState
        : context.findAncestorStateOfType<EditableTextState>();
    if (state == null) return false;
    if (!state.textEditingValue.composing.isCollapsed) return true;
    final action = state.widget.textInputAction;
    if (action == TextInputAction.newline) return true;
    final maxLines = state.widget.maxLines;
    if (maxLines == null || maxLines > 1) {
      return action != TextInputAction.done &&
          action != TextInputAction.send &&
          action != TextInputAction.go;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.26),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: widget.onPressed,
        color: widget.color,
        pressedColor: Color.lerp(widget.color, Colors.black, 0.16)!,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: SaveCompanyButton.size,
          height: SaveCompanyButton.size,
          child: Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: AppAssetImage(
                asset: AppIcons.cursor,
                width: SaveCompanyButton._iconSize,
                height: SaveCompanyButton._iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
