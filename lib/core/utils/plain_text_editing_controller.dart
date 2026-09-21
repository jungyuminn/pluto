import 'package:flutter/material.dart';

class PlainTextEditingController extends TextEditingController {
  PlainTextEditingController({super.text});

  TextRange? _highlight;

  TextRange? get highlight => _highlight;

  void setHighlight(TextRange? range, {bool force = false}) {
    if (!force && _highlight == range) return;
    _highlight = range;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final highlight = _highlight;
    final color = Theme.of(context).textSelectionTheme.selectionColor;
    if (highlight == null ||
        color == null ||
        text.isEmpty ||
        highlight.start < 0 ||
        highlight.end > text.length ||
        highlight.start >= highlight.end) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: false,
      );
    }
    return TextSpan(
      style: style,
      children: [
        if (highlight.start > 0)
          TextSpan(text: text.substring(0, highlight.start)),
        TextSpan(
          text: text.substring(highlight.start, highlight.end),
          style: TextStyle(backgroundColor: color),
        ),
        if (highlight.end < text.length)
          TextSpan(text: text.substring(highlight.end)),
      ],
    );
  }
}
