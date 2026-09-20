import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/focused_ime_text.dart';

class EventTitleField extends StatefulWidget {
  const EventTitleField({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = true,
    this.readOnly = false,
    this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  @override
  State<EventTitleField> createState() => _EventTitleFieldState();
}

class _EventTitleFieldState extends State<EventTitleField> {
  FocusNode? _ownedFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());
  ImeTextWatcher? _ime;
  Timer? _poll;
  String? _lastEmitted;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _ime = ImeTextWatcher(_onIme);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ime?.dispose();
    if (kIsWeb) {
      _focus.removeListener(_onFocus);
    }
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    _poll?.cancel();
    if (!_focus.hasFocus) return;
    _push();
    _poll = Timer.periodic(const Duration(milliseconds: 160), (_) {
      if (!_focus.hasFocus) return;
      _push();
    });
  }

  void _onIme(String text) => _push(ime: text);

  void _push({String? ime, String? flutter}) {
    if (kIsWeb && !_focus.hasFocus) return;
    final text = mergeSuggestTitle(
      flutter: flutter ?? widget.controller.text,
      ime: ime ?? (kIsWeb ? focusedImeText() : null),
    );
    if (text == _lastEmitted) return;
    _lastEmitted = text;
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      textInputAction: TextInputAction.done,
      onChanged: (value) => _push(flutter: value),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: AppFonts.of(context),
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText ?? AppStrings.eventTitleHint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.of(context),
          color: colors.hint,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
