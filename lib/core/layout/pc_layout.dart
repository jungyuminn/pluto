import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PcLayout {
  PcLayout._();

  static bool get isPc => kIsWeb;

  static const homeCardWidth = 480.0;
  static const navLift = 20.0;
  static const contentMaxWidth = homeCardWidth + 32;
  static const dayDialogWidth = 260.0;
  static const pcDayDialogWidth = 360.0;
  static const dayLabelHeight = 52.0;
  static const pcDayLabelHeight = 56.0;
  static const compactWidth = 720.0;

  static bool showCalendarArrowsOf(double width) =>
      isPc && width >= compactWidth;

  static double dayDialogWidthOf() => isPc ? pcDayDialogWidth : dayDialogWidth;

  static double dayDialogHeightOf(double screenHeight) {
    if (isPc) {
      final maxH = math.min(640.0, screenHeight * 0.82);
      final minH = math.min(520.0, screenHeight * 0.62);
      return (screenHeight * 0.68).clamp(minH, maxH).toDouble();
    }
    final maxH = math.min(530.0, screenHeight * 0.82);
    final minH = math.min(420.0, screenHeight * 0.52);
    return (screenHeight * 0.56).clamp(minH, maxH).toDouble();
  }

  static double dayLabelHeightOf() =>
      isPc ? pcDayLabelHeight : dayLabelHeight;

  static double dayLabelExtentOf() => dayLabelHeightOf() + 10;

  static Widget constrainWidth(Widget child) {
    if (!isPc) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: child,
      ),
    );
  }
}
