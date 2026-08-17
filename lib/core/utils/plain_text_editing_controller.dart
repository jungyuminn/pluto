import 'package:flutter/material.dart';

class PlainTextEditingController extends TextEditingController {
  PlainTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return super.buildTextSpan(
      context: context,
      style: style,
      withComposing: false,
    );
  }
}
