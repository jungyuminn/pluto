import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/domain/entities/diary_cover.dart';

class DiaryCoverLook {
  const DiaryCoverLook({
    required this.paper,
    required this.rule,
    required this.fiber,
    required this.edge,
    required this.torn,
  });

  final Color paper;
  final Color rule;
  final Color fiber;
  final Color edge;
  final bool torn;

  factory DiaryCoverLook.of(
    DiaryCover cover,
    AppColors colors,
    Brightness brightness,
  ) {
    final tint = switch (cover) {
      DiaryCover.basic => const Color(0xFFF7F1E3),
      DiaryCover.lined => const Color(0xFFF7F1E3),
      DiaryCover.grid => const Color(0xFFF2EEE3),
      DiaryCover.dotted => const Color(0xFFF6F1E6),
      DiaryCover.kraft => const Color(0xFFD8C19A),
      DiaryCover.sky => const Color(0xFFE3F0F8),
      DiaryCover.rose => const Color(0xFFF8E4E8),
      DiaryCover.mint => const Color(0xFFDCEFE6),
      DiaryCover.blank => const Color(0xFFF7F1E3),
    };
    final darkTint = switch (cover) {
      DiaryCover.basic => const Color(0xFF2C261E),
      DiaryCover.lined => const Color(0xFF2C261E),
      DiaryCover.grid => const Color(0xFF2A2822),
      DiaryCover.dotted => const Color(0xFF2C261E),
      DiaryCover.kraft => const Color(0xFF3A2C1C),
      DiaryCover.sky => const Color(0xFF1E2A32),
      DiaryCover.rose => const Color(0xFF322428),
      DiaryCover.mint => const Color(0xFF1E2C26),
      DiaryCover.blank => const Color(0xFF2C261E),
    };
    final paper = brightness == Brightness.dark
        ? Color.lerp(colors.card, darkTint, 0.55)!
        : Color.lerp(colors.card, tint, 0.78)!;
    return DiaryCoverLook(
      paper: paper,
      rule: Color.lerp(paper, colors.text, 0.12)!,
      fiber: Color.lerp(paper, Colors.white, 0.4)!,
      edge: Color.lerp(paper, colors.text, 0.16)!,
      torn: cover == DiaryCover.basic,
    );
  }

  static String label(DiaryCover cover) {
    return switch (cover) {
      DiaryCover.basic => AppStrings.diaryCoverBasic,
      DiaryCover.lined => AppStrings.diaryCoverLined,
      DiaryCover.grid => AppStrings.diaryCoverGrid,
      DiaryCover.dotted => AppStrings.diaryCoverDotted,
      DiaryCover.kraft => AppStrings.diaryCoverKraft,
      DiaryCover.sky => AppStrings.diaryCoverSky,
      DiaryCover.rose => AppStrings.diaryCoverRose,
      DiaryCover.mint => AppStrings.diaryCoverMint,
      DiaryCover.blank => AppStrings.diaryCoverBlank,
    };
  }
}

class DiaryCoverPaper extends StatelessWidget {
  const DiaryCoverPaper({
    super.key,
    required this.look,
    required this.child,
    this.elevation = 0,
    this.radius = 20,
  });

  final DiaryCoverLook look;
  final Widget child;
  final double elevation;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (look.torn) {
      return PhysicalShape(
        clipper: const TornNotebookClipper(),
        color: look.paper,
        elevation: elevation,
        shadowColor: const Color(0x4D000000),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: TornEdgePainter(edge: look.edge, fiber: look.fiber),
          child: child,
        ),
      );
    }
    return PhysicalModel(
      color: look.paper,
      elevation: elevation,
      shadowColor: const Color(0x4D000000),
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class TornNotebookClipper extends CustomClipper<Path> {
  const TornNotebookClipper();

  @override
  Path getClip(Size size) => TornNotebook.path(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TornNotebook {
  static const inset = 12.0;
  static const step = 6.5;

  static double jag(int i) {
    final n = math.sin(i * 12.9898) * 43758.5453;
    return n - n.floorToDouble();
  }

  static List<Offset> topEdge(Size size) {
    final points = <Offset>[];
    var i = 0;
    for (var x = 0.0; x <= size.width + step; x += step) {
      final dip = (jag(i) - 0.5) * 9;
      final notch = i % 13 == 4 ? 5.5 : (i % 9 == 2 ? 3.0 : 0.0);
      final y = (inset + dip + notch).clamp(2.0, 18.0);
      points.add(Offset(math.min(x, size.width), y));
      i++;
    }
    return points;
  }

  static Path path(Size size) {
    final points = topEdge(size);
    final path = Path()..moveTo(0, size.height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }
}

class TornEdgePainter extends CustomPainter {
  const TornEdgePainter({required this.edge, required this.fiber});

  final Color edge;
  final Color fiber;

  @override
  void paint(Canvas canvas, Size size) {
    final points = TornNotebook.topEdge(size);
    if (points.isEmpty) return;

    final torn = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      torn.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      torn,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );

    final ticks = Paint()
      ..color = fiber
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;
    for (var i = 2; i < points.length - 2; i += 3) {
      final point = points[i];
      final len = 2.5 + TornNotebook.jag(i + 7) * 3.5;
      canvas.drawLine(
        point,
        Offset(point.dx + (i.isEven ? 1.6 : -1.6), point.dy + len),
        ticks,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TornEdgePainter oldDelegate) {
    return oldDelegate.edge != edge || oldDelegate.fiber != fiber;
  }
}

class DiaryCoverPatternPainter extends CustomPainter {
  const DiaryCoverPatternPainter({
    required this.cover,
    required this.color,
    required this.lineHeight,
  });

  final DiaryCover cover;
  final Color color;
  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    switch (cover) {
      case DiaryCover.grid:
        _paintGrid(canvas, size);
      case DiaryCover.dotted:
        _paintDots(canvas, size);
      case DiaryCover.blank:
        return;
      case DiaryCover.basic:
      case DiaryCover.lined:
      case DiaryCover.kraft:
      case DiaryCover.sky:
      case DiaryCover.rose:
      case DiaryCover.mint:
        _paintLines(canvas, size);
    }
  }

  void _paintLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = lineHeight - 2; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final step = math.max(10.0, lineHeight / 2);
    for (var y = step - 2; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final step = math.max(10.0, lineHeight / 2);
    final radius = math.max(0.7, step * 0.08);
    for (var y = step - 2; y < size.height; y += step) {
      for (var x = step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DiaryCoverPatternPainter oldDelegate) {
    return oldDelegate.cover != cover ||
        oldDelegate.color != color ||
        oldDelegate.lineHeight != lineHeight;
  }
}

class DiaryCoverPreview extends StatelessWidget {
  const DiaryCoverPreview({super.key, required this.cover});

  final DiaryCover cover;

  @override
  Widget build(BuildContext context) {
    final look = DiaryCoverLook.of(
      cover,
      AppColors.of(context),
      Theme.of(context).brightness,
    );
    return DiaryCoverPaper(
      look: look,
      radius: 12,
      child: CustomPaint(
        painter: DiaryCoverPatternPainter(
          cover: cover,
          color: look.rule,
          lineHeight: 16,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
