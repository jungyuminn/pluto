import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlanetFill extends StatefulWidget {
  const PlanetFill({
    super.key,
    required this.level,
    required this.wave,
    required this.outline,
    required this.empty,
    this.phase = 0,
    this.pokeable = true,
  });

  final int level;
  final double wave;
  final Color outline;
  final Color empty;
  final double phase;
  final bool pokeable;

  @override
  State<PlanetFill> createState() => _PlanetFillState();
}

class _PlanetFillState extends State<PlanetFill>
    with TickerProviderStateMixin {
  AnimationController? _idle;
  AnimationController? _poke;

  AnimationController get _idleAnim => _idle ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      )..repeat();

  AnimationController get _pokeAnim {
    const want = Duration(milliseconds: 780);
    _poke ??= AnimationController(vsync: this, duration: want);
    if (_poke!.duration != want) _poke!.duration = want;
    return _poke!;
  }

  @override
  void initState() {
    super.initState();
    _idleAnim;
    _pokeAnim;
  }

  @override
  void dispose() {
    _idle?.dispose();
    _poke?.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.pokeable) return;
    HapticFeedback.lightImpact();
    _pokeAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final planet = AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleAnim, _pokeAnim]),
        builder: (context, _) {
          return CustomPaint(
            painter: _PlanetPainter(
              level: widget.level.clamp(1, 10),
              wave: widget.wave,
              time: (_idleAnim.value + widget.phase) % 1,
              poke: _pokeAnim.value,
              outline: widget.outline,
              empty: widget.empty,
            ),
          );
        },
      ),
    );
    if (!widget.pokeable) return planet;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: planet,
    );
  }
}

enum _Face { sleep, yawn, round, shy, smile, happy }

class _Look {
  const _Look({
    required this.top,
    required this.mid,
    required this.bottom,
    required this.face,
    required this.kind,
    this.land = false,
    this.clouds = false,
    this.haze = false,
    this.ring = false,
    this.ring2 = false,
    this.moon = false,
    this.sparkle = false,
    this.gleam = false,
    this.gold = false,
    this.sunset = false,
    this.blush = false,
    this.brows = false,
  });

  final Color top;
  final Color mid;
  final Color bottom;
  final Color face;
  final _Face kind;
  final bool land;
  final bool clouds;
  final bool haze;
  final bool ring;
  final bool ring2;
  final bool moon;
  final bool sparkle;
  final bool gleam;
  final bool gold;
  final bool sunset;
  final bool blush;
  final bool brows;

  static _Look of(int level) {
    return switch (level) {
      1 => const _Look(
          top: Color(0xFFD5D0DC),
          mid: Color(0xFFB8B0C4),
          bottom: Color(0xFF8F879C),
          face: Color(0xFF5A5466),
          kind: _Face.sleep,
        ),
      2 => const _Look(
          top: Color(0xFFE8D4C8),
          mid: Color(0xFFD2B4A6),
          bottom: Color(0xFFB08A7C),
          face: Color(0xFF6A4A44),
          kind: _Face.yawn,
        ),
      3 => const _Look(
          top: Color(0xFFFFF0D8),
          mid: Color(0xFFF3C3A0),
          bottom: Color(0xFFE08B78),
          face: Color(0xFF5C3D42),
          kind: _Face.round,
        ),
      4 => const _Look(
          top: Color(0xFFFFE4E8),
          mid: Color(0xFFF4B4B8),
          bottom: Color(0xFFD9898A),
          face: Color(0xFF6A3E48),
          kind: _Face.shy,
          blush: true,
          brows: true,
        ),
      5 => const _Look(
          top: Color(0xFFFFD0A8),
          mid: Color(0xFFF07A62),
          bottom: Color(0xFFC45A78),
          face: Color(0xFF5C3D42),
          kind: _Face.round,
          land: true,
          haze: true,
          sunset: true,
          blush: true,
        ),
      6 => const _Look(
          top: Color(0xFFFFF6DE),
          mid: Color(0xFFFFD7A0),
          bottom: Color(0xFFE8A070),
          face: Color(0xFF5C3D42),
          kind: _Face.smile,
          land: true,
          clouds: true,
          haze: true,
          blush: true,
        ),
      7 => const _Look(
          top: Color(0xFFFFF6C4),
          mid: Color(0xFFFFD36A),
          bottom: Color(0xFFE8A03C),
          face: Color(0xFF5C3D42),
          kind: _Face.smile,
          land: true,
          clouds: true,
          haze: true,
          sparkle: true,
          gleam: true,
          gold: true,
          blush: true,
        ),
      8 => const _Look(
          top: Color(0xFFFFE7C2),
          mid: Color(0xFFF3C3A0),
          bottom: Color(0xFFD9898A),
          face: Color(0xFF5C3D42),
          kind: _Face.smile,
          land: true,
          clouds: true,
          haze: true,
          ring: true,
          sparkle: true,
          blush: true,
        ),
      9 => const _Look(
          top: Color(0xFFFFF0D0),
          mid: Color(0xFFE8C4F0),
          bottom: Color(0xFFB08AD4),
          face: Color(0xFF4A3A66),
          kind: _Face.smile,
          land: true,
          clouds: true,
          haze: true,
          ring: true,
          moon: true,
          sparkle: true,
          gleam: true,
          blush: true,
        ),
      _ => const _Look(
          top: Color(0xFFFFF6DE),
          mid: Color(0xFFFFD36A),
          bottom: Color(0xFFE8895A),
          face: Color(0xFF5C3D42),
          kind: _Face.happy,
          land: true,
          clouds: true,
          haze: true,
          ring: true,
          moon: true,
          sparkle: true,
          gleam: true,
          blush: true,
        ),
    };
  }
}

class _PlanetPainter extends CustomPainter {
  const _PlanetPainter({
    required this.level,
    required this.wave,
    required this.time,
    required this.poke,
    required this.outline,
    required this.empty,
  });

  final int level;
  final double wave;
  final double time;
  final double poke;
  final Color outline;
  final Color empty;

  static const _blush = Color(0xFFFF8DA6);
  static const _land = Color(0xFFE7A07A);

  @override
  void paint(Canvas canvas, Size size) {
    final look = _Look.of(level);
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final clock = (time + level * 0.17) % 1;
    final pokeT = poke.clamp(0.0, 1.0);
    final pulse = math.sin(pokeT * math.pi);
    final kind = _pokedFace(look.kind, pokeT);
    final blink = () {
      if (kind == _Face.sleep || kind == _Face.happy) return 1.0;
      final idle = _blink(look.kind, clock);
      if (pokeT <= 0) return idle;
      return idle.clamp(0.45 + pulse * 0.55, 1.0);
    }();
    final breathe = 1 + math.sin((wave + clock) * math.pi * 2) * 0.008;
    final radius = s * 0.30 * breathe;
    final squash = _squash(pokeT);
    final hop = radius * _hop(pokeT);

    canvas.save();
    canvas.translate(center.dx, center.dy - hop + radius * 0.35);
    canvas.rotate(_tilt(pokeT));
    canvas.scale(1 + squash * 0.16, 1 - squash * 0.14);
    canvas.translate(-center.dx, -(center.dy + radius * 0.35));

    if (look.haze) _drawAtmosphere(canvas, center, radius, look);
    if (look.sunset) {
      _drawSun(canvas, center, radius * (1 + pulse * 0.12));
    }
    if (look.ring) {
      _drawRing(canvas, center, radius, look, behind: true, thin: false);
    }
    if (look.ring2) {
      _drawRing(canvas, center, radius * 1.1, look, behind: true, thin: true);
    }
    _drawBody(canvas, center, radius, look);
    if (look.clouds) _drawClouds(canvas, center, radius, look);
    if (look.gleam) _drawGleam(canvas, center, radius, look);
    _drawFace(canvas, center, radius, look, blink, kind: kind, poke: pokeT);
    if (look.ring) {
      _drawRing(canvas, center, radius, look, behind: false, thin: false);
    }
    if (look.ring2) {
      _drawRing(canvas, center, radius * 1.1, look, behind: false, thin: true);
    }
    if (look.moon) {
      _drawMoon(
        canvas,
        center,
        radius,
        look,
        _blink(_Face.round, clock),
        hop: pulse * radius * 0.18,
      );
    }
    if (look.sparkle || look.gleam || pokeT > 0 && level >= 7) {
      _drawSparkles(canvas, center, radius, look, burst: pulse);
    }
    _drawPokeFx(canvas, center, radius, look, pokeT);
    canvas.restore();
  }

  _Face _pokedFace(_Face kind, double t) {
    if (t <= 0) return kind;
    return switch (level) {
      2 when t > 0.42 => _Face.round,
      4 when t > 0.18 && t < 0.82 => _Face.shy,
      10 => _Face.happy,
      _ => kind,
    };
  }

  double _squash(double t) {
    if (t <= 0 || t >= 1) return 0;
    final raw = () {
      if (t < 0.2) return Curves.easeOut.transform(t / 0.2);
      if (t < 0.52) {
        final u = (t - 0.2) / 0.32;
        return ui.lerpDouble(1, -0.55, Curves.easeOut.transform(u))!;
      }
      final u = (t - 0.52) / 0.48;
      return ui.lerpDouble(-0.55, 0, Curves.easeOutCubic.transform(u))!;
    }();
    return raw * (level == 1 ? 1.4 : 1);
  }

  double _hop(double t) {
    if (t <= 0.18 || t >= 1) return 0;
    final u = (t - 0.18) / 0.82;
    final height = switch (level) {
      1 => 0.02,
      2 => 0.07,
      4 => 0.06,
      10 => 0.16,
      _ => 0.14,
    };
    return math.sin(u * math.pi) * height;
  }

  double _tilt(double t) {
    final pulse = math.sin(t * math.pi);
    return switch (level) {
      1 => pulse * 0.12,
      4 => pulse * 0.16,
      8 => math.sin(t * math.pi * 2) * 0.08,
      9 => pulse * -0.08,
      _ => pulse * 0.03,
    };
  }

  double _blink(_Face kind, double clock) {
    if (kind == _Face.sleep || kind == _Face.happy) return 1;
    const windows = [(0.28, 0.08), (0.72, 0.08)];
    for (final window in windows) {
      final start = window.$1;
      final span = window.$2;
      if (clock < start || clock > start + span) continue;
      final u = (clock - start) / span;
      final close = u < 0.5 ? u * 2 : (1 - u) * 2;
      return 1 - close * 0.88;
    }
    return 1;
  }

  void _drawAtmosphere(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look,
  ) {
    final inner = look.sunset
        ? const Color(0xFFFF8A6A).withValues(alpha: 0.5)
        : look.gold
            ? const Color(0xFFFFE08A).withValues(alpha: 0.48)
            : look.mid.withValues(alpha: 0.4);
    final mid = look.sunset
        ? const Color(0xFFFF6B8A).withValues(alpha: 0.22)
        : look.gold
            ? const Color(0xFFFFD36A).withValues(alpha: 0.2)
            : look.top.withValues(alpha: 0.14);
    canvas.drawCircle(
      center,
      radius * 1.46,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius * 1.46,
          [inner, mid, look.top.withValues(alpha: 0)],
          const [0.46, 0.72, 1],
        ),
    );
  }

  void _drawSun(Canvas canvas, Offset center, double radius) {
    final sun = center.translate(radius * 0.58, radius * 0.16);
    final r = radius * 0.34;
    canvas.drawCircle(
      sun,
      r * 2.35,
      Paint()
        ..shader = ui.Gradient.radial(
          sun,
          r * 2.35,
          [
            const Color(0xFFFFF2B0).withValues(alpha: 0.9),
            const Color(0xFFFF8A5C).withValues(alpha: 0.5),
            const Color(0xFFFF5A7A).withValues(alpha: 0),
          ],
          const [0.12, 0.46, 1],
        ),
    );
    canvas.drawCircle(
      sun,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          sun.translate(-r * 0.2, -r * 0.24),
          r * 1.2,
          const [
            Color(0xFFFFF7C8),
            Color(0xFFFFC04A),
            Color(0xFFFF6B3C),
          ],
          const [0, 0.52, 1],
        ),
    );
  }

  void _drawBody(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look,
  ) {
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.1),
      radius * 0.94,
      Paint()..color = look.bottom.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-radius * 0.24, -radius * 0.3),
          radius * 1.28,
          [look.top, look.mid, look.bottom],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    if (look.land) {
      final paint = Paint()..color = _land.withValues(alpha: 0.28);
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(-radius * 0.22, radius * 0.18),
          width: radius * 0.72,
          height: radius * 0.4,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(radius * 0.34, -radius * 0.06),
          width: radius * 0.44,
          height: radius * 0.3,
        ),
        paint,
      );
      canvas.drawCircle(
        center.translate(radius * 0.06, radius * 0.44),
        radius * 0.17,
        paint,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.2, -radius * 0.3),
        width: radius * 0.7,
        height: radius * 0.34,
      ),
      Paint()
        ..color = (look.gold ? const Color(0xFFFFF4C2) : Colors.white)
            .withValues(alpha: look.gold ? 0.48 : 0.32),
    );
    if (look.sunset) {
      canvas.drawRect(
        Rect.fromLTRB(
          center.dx - radius,
          center.dy + radius * 0.02,
          center.dx + radius,
          center.dy + radius,
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(center.dx, center.dy - radius * 0.1),
            Offset(center.dx, center.dy + radius),
            [
              const Color(0xFFFF8A6A).withValues(alpha: 0),
              const Color(0xFFFF6B7A).withValues(alpha: 0.34),
              const Color(0xFFB04A78).withValues(alpha: 0.4),
            ],
            const [0, 0.45, 1],
          ),
      );
    }
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = look.bottom.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, radius * 0.04),
    );
  }

  void _drawClouds(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look,
  ) {
    final drift = math.sin(time * math.pi * 2) * radius * 0.05;
    final fluffy = look.clouds && !look.sparkle && !look.ring;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: fluffy ? 0.5 : 0.34);
    void puff(Offset at, double w, double h) {
      canvas.drawOval(
        Rect.fromCenter(center: at, width: w, height: h),
        paint,
      );
    }

    puff(
      center.translate(-radius * 0.34 + drift, -radius * 0.46),
      radius * (fluffy ? 0.58 : 0.44),
      radius * (fluffy ? 0.2 : 0.15),
    );
    puff(
      center.translate(radius * 0.3 - drift * 0.7, radius * 0.36),
      radius * (fluffy ? 0.5 : 0.38),
      radius * (fluffy ? 0.18 : 0.13),
    );
    if (fluffy) {
      puff(
        center.translate(radius * 0.08 + drift * 0.4, -radius * 0.18),
        radius * 0.42,
        radius * 0.16,
      );
      puff(
        center.translate(-radius * 0.08 - drift * 0.5, radius * 0.08),
        radius * 0.5,
        radius * 0.18,
      );
    }
    canvas.restore();
    if (!fluffy) return;
    final rim = Paint()..color = Colors.white.withValues(alpha: 0.62);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.72 + drift, -radius * 0.18),
        width: radius * 0.4,
        height: radius * 0.16,
      ),
      rim,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(radius * 0.7 - drift * 0.6, radius * 0.22),
        width: radius * 0.36,
        height: radius * 0.14,
      ),
      rim,
    );
  }

  void _drawFace(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look,
    double blink, {
    required _Face kind,
    required double poke,
  }) {
    final pulse = math.sin(poke * math.pi);
    final glance = switch (level) {
      4 => pulse * radius * 0.08,
      9 => pulse * -radius * 0.04,
      _ => 0.0,
    };
    final eyeY = center.dy - radius * 0.05;
    final eyeDx = radius * 0.27;
    final eyeR = radius * 0.09;
    final blushOn = look.blush || (poke > 0 && level == 4);
    if (blushOn) {
      final paint = Paint()
        ..color = _blush.withValues(alpha: 0.42 + pulse * 0.28);
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              center.dx + side * radius * 0.44 + glance,
              center.dy + radius * 0.18,
            ),
            width: radius * (0.24 + pulse * 0.06),
            height: radius * (0.13 + pulse * 0.04),
          ),
          paint,
        );
      }
    }
    if (look.brows) {
      final lift = pulse * eyeR * 0.35;
      for (final side in [-1.0, 1.0]) {
        final brow = Path()
          ..moveTo(
            center.dx + side * (eyeDx - eyeR) + glance,
            eyeY - eyeR * 1.55 - lift,
          )
          ..quadraticBezierTo(
            center.dx + side * eyeDx + glance,
            eyeY - eyeR * 2.05 - lift,
            center.dx + side * (eyeDx + eyeR) + glance,
            eyeY - eyeR * 1.4 - lift,
          );
        canvas.drawPath(
          brow,
          Paint()
            ..color = look.face.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = math.max(1.5, radius * 0.032),
        );
      }
    }
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(center.dx + side * eyeDx + glance, eyeY);
      switch (kind) {
        case _Face.sleep:
          _arcEye(
            canvas,
            eye.translate(0, pulse * eyeR * 0.18),
            eyeR,
            look.face,
            down: true,
            heavy: pulse,
          );
        case _Face.happy:
          _arcEye(canvas, eye, eyeR, look.face, down: false);
        case _Face.yawn:
        case _Face.round:
        case _Face.shy:
        case _Face.smile:
          _roundEye(canvas, eye, eyeR, look.face, lid: blink);
      }
    }
    final mouthY = center.dy + radius * 0.2;
    if (kind == _Face.yawn) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, mouthY + radius * 0.02),
          width: radius * (0.15 + pulse * 0.06),
          height: radius * (0.17 + pulse * 0.12),
        ),
        Paint()..color = look.face.withValues(alpha: 0.55),
      );
      return;
    }
    if (kind == _Face.sleep) {
      canvas.drawLine(
        Offset(center.dx - radius * 0.06, mouthY + pulse * radius * 0.02),
        Offset(center.dx + radius * 0.06, mouthY + pulse * radius * 0.02),
        Paint()
          ..color = look.face.withValues(alpha: 0.4)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.6, radius * 0.04),
      );
      if (pulse > 0.15) {
        final bubble = Offset(
          center.dx + radius * 0.2,
          mouthY - radius * 0.06 - pulse * radius * 0.04,
        );
        canvas.drawCircle(
          bubble,
          radius * 0.04 * pulse,
          Paint()..color = Colors.white.withValues(alpha: 0.72 * pulse),
        );
        canvas.drawCircle(
          bubble.translate(radius * 0.08, -radius * 0.1),
          radius * 0.07 * pulse,
          Paint()..color = Colors.white.withValues(alpha: 0.5 * pulse),
        );
      }
      return;
    }
    final wide =
        kind == _Face.smile || kind == _Face.happy || (poke > 0.2 && level >= 6);
    final mouthW = radius * ((wide ? 0.28 : 0.16) + pulse * 0.05);
    final mouth = Path()
      ..moveTo(center.dx - mouthW + glance * 0.4, mouthY)
      ..quadraticBezierTo(
        center.dx + glance * 0.4,
        mouthY + radius * ((wide ? 0.16 : 0.08) + pulse * 0.05),
        center.dx + mouthW + glance * 0.4,
        mouthY,
      );
    canvas.drawPath(
      mouth,
      Paint()
        ..color = look.face.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.0, radius * 0.055),
    );
  }

  void _arcEye(
    Canvas canvas,
    Offset eye,
    double r,
    Color color, {
    required bool down,
    double heavy = 0,
  }) {
    final dip = down ? r * (0.65 + heavy * 0.35) : -r * 0.92;
    final path = Path()
      ..moveTo(eye.dx - r * 1.1, eye.dy + (down ? heavy * r * 0.12 : r * 0.12))
      ..quadraticBezierTo(
        eye.dx,
        eye.dy + dip,
        eye.dx + r * 1.1,
        eye.dy + (down ? heavy * r * 0.12 : r * 0.12),
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.0, r * 0.62),
    );
  }

  void _roundEye(
    Canvas canvas,
    Offset eye,
    double r,
    Color color, {
    required double lid,
  }) {
    canvas.save();
    canvas.clipRect(
      Rect.fromCenter(
        center: eye,
        width: r * 2.1,
        height: r * 2.3 * lid.clamp(0.08, 1.0),
      ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: eye, width: r * 1.9, height: r * 2.25),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: eye.translate(0, r * 0.08),
        width: r * 1.35,
        height: r * 1.7,
      ),
      Paint()..color = color,
    );
    canvas.drawCircle(
      eye.translate(-r * 0.22, -r * 0.32),
      r * 0.32,
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look, {
    required bool behind,
    required bool thin,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((thin ? -0.2 : -0.34) + math.sin(poke * math.pi * 2) * 0.12);
    final oval = Rect.fromCenter(
      center: Offset.zero,
      width: radius * (thin ? 2.55 : 2.32),
      height: radius * (thin ? 0.5 : 0.62),
    );
    canvas.drawArc(
      oval,
      behind ? math.pi * 0.08 : math.pi * 1.08,
      math.pi * 0.84,
      false,
      Paint()
        ..color = look.top.withValues(alpha: behind ? 0.34 : 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * (thin ? 0.055 : 0.13)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawMoon(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look,
    double blink, {
    double hop = 0,
  }) {
    final moon = Offset(
      center.dx + radius * 1.2,
      center.dy - radius * 0.82 - hop,
    );
    final r = radius * 0.2;
    canvas.drawCircle(
      moon,
      r * 2,
      Paint()
        ..shader = ui.Gradient.radial(
          moon,
          r * 2,
          [
            look.top.withValues(alpha: 0.28),
            look.top.withValues(alpha: 0),
          ],
        ),
    );
    canvas.drawCircle(
      moon,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          moon.translate(-r * 0.26, -r * 0.3),
          r * 1.2,
          [const Color(0xFFFFF6DE), look.mid],
        ),
    );
    final eyeR = r * 0.2;
    for (final side in [-1.0, 1.0]) {
      _roundEye(
        canvas,
        Offset(moon.dx + side * r * 0.3, moon.dy - r * 0.02),
        eyeR,
        look.face,
        lid: blink,
      );
    }
  }

  void _drawGleam(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look,
  ) {
    final pulse = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(time * math.pi * 2));
    final shine = Offset(
      center.dx - radius * 0.26,
      center.dy - radius * 0.32,
    );
    canvas.drawCircle(
      shine,
      radius * 0.7,
      Paint()
        ..shader = ui.Gradient.radial(
          shine,
          radius * 0.7,
          [
            Colors.white.withValues(alpha: 0.55 * pulse),
            Colors.white.withValues(alpha: 0.16 * pulse),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, 0.42, 1],
        ),
    );
  }

  void _drawSparkles(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look, {
    double burst = 0,
  }) {
    final spots = <(Offset, double, double)>[
      (center.translate(-radius * 1.08, -radius * 0.62), 0.08, 0.0),
      (center.translate(radius * 0.96, radius * 0.7), 0.06, 0.33),
      (center.translate(-radius * 0.88, radius * 0.86), 0.05, 0.66),
      if (look.gleam) (center.translate(radius * 0.78, -radius * 0.98), 0.12, 0.12),
      if (look.gleam) (center.translate(-radius * 1.16, radius * 0.18), 0.09, 0.48),
      if (look.gleam) (center.translate(radius * 1.18, radius * 0.36), 0.07, 0.78),
      if (look.gleam) (center.translate(-radius * 0.2, -radius * 1.18), 0.1, 0.22),
      if (look.moon) (center.translate(radius * 1.42, -radius * 1.08), 0.08, 0.55),
      if (burst > 0.2) (center.translate(radius * 0.2, -radius * 1.28), 0.09, 0.18),
      if (burst > 0.2) (center.translate(-radius * 1.28, -radius * 0.2), 0.07, 0.4),
      if (burst > 0.2) (center.translate(radius * 1.24, 0), 0.08, 0.62),
    ];
    for (final spot in spots) {
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin((time + spot.$3) * math.pi * 4));
      _drawStar(
        canvas,
        spot.$1,
        radius * spot.$2 * twinkle * (1 + burst * 0.55),
        look.gold
            ? const Color(0xFFFFE082)
            : look.gleam
                ? const Color(0xFFFFF8E8)
                : look.top,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final p = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      final b = a + math.pi / 4;
      path.lineTo(
        center.dx + math.cos(b) * r * 0.3,
        center.dy + math.sin(b) * r * 0.3,
      );
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 1));
  }

  void _drawPokeFx(
    Canvas canvas,
    Offset center,
    double radius,
    _Look look,
    double t,
  ) {
    if (t <= 0 || t >= 1) return;
    final pulse = math.sin(t * math.pi);
    final rise = t * radius * 0.9;
    switch (level) {
      case 1:
        _drawZ(
          canvas,
          center.translate(-radius * 0.55, -radius * 0.85 - rise * 0.55),
          radius * 0.16,
          look.face.withValues(alpha: 0.45 * pulse),
          -0.2,
        );
        _drawZ(
          canvas,
          center.translate(-radius * 0.22, -radius * 1.15 - rise * 0.8),
          radius * 0.22,
          look.face.withValues(alpha: 0.38 * pulse),
          0.15,
        );
        _drawZ(
          canvas,
          center.translate(radius * 0.18, -radius * 1.42 - rise),
          radius * 0.28,
          look.face.withValues(alpha: 0.28 * pulse),
          -0.08,
        );
      case 2:
        _drawPuff(
          canvas,
          center.translate(radius * 0.18, -radius * 0.08 - rise * 0.35),
          radius * 0.16 * pulse,
        );
        _drawPuff(
          canvas,
          center.translate(-radius * 0.12, -radius * 0.22 - rise * 0.5),
          radius * 0.12 * pulse,
        );
        _drawDrop(
          canvas,
          center.translate(radius * 0.58, -radius * 0.12 + rise * 0.15),
          radius * 0.08 * pulse,
          look.face.withValues(alpha: 0.35 * pulse),
        );
        _drawStar(
          canvas,
          center.translate(-radius * 0.78, -radius * 0.72 - rise * 0.15),
          radius * 0.08 * pulse,
          look.top,
        );
      case 3:
        _drawStar(
          canvas,
          center.translate(radius * 0.78, -radius * 0.9 - rise * 0.2),
          radius * 0.1 * pulse,
          look.top,
        );
        _drawStar(
          canvas,
          center.translate(-radius * 0.86, -radius * 0.55),
          radius * 0.07 * pulse,
          look.mid,
        );
      case 4:
        _drawHeart(
          canvas,
          center.translate(radius * 0.72, -radius * 0.82 - rise * 0.25),
          radius * 0.1 * pulse,
          _blush.withValues(alpha: 0.7 * pulse),
        );
      case 5:
        _drawStar(
          canvas,
          center.translate(-radius * 0.92, -radius * 0.4),
          radius * 0.09 * pulse,
          const Color(0xFFFFB08A),
        );
        _drawStar(
          canvas,
          center.translate(radius * 0.88, radius * 0.2),
          radius * 0.07 * pulse,
          const Color(0xFFFF8A6A),
        );
      case 6:
        _drawPuff(
          canvas,
          center.translate(-radius * 1.05, -radius * 0.15 - rise * 0.15),
          radius * 0.22 * pulse,
        );
        _drawPuff(
          canvas,
          center.translate(radius * 1.02, radius * 0.18 - rise * 0.1),
          radius * 0.18 * pulse,
        );
      case 10:
        final u = Curves.easeInOut.transform(t);
        final from = center.translate(-radius * 1.05, -radius * 0.72);
        final to = center.translate(radius * 1.08, radius * 0.42);
        final star = Offset.lerp(from, to, u)!;
        final tail = Offset.lerp(from, to, (u - 0.18).clamp(0.0, 1.0))!;
        canvas.drawLine(
          tail,
          star,
          Paint()
            ..color = const Color(0xFFFFF8E8).withValues(alpha: 0.85 * pulse)
            ..strokeCap = StrokeCap.round
            ..strokeWidth = math.max(1.8, radius * 0.055),
        );
        _drawStar(
          canvas,
          star,
          radius * (0.11 + pulse * 0.04),
          const Color(0xFFFFF8E8),
        );
        _drawStar(
          canvas,
          center.translate(radius * 0.72, -radius * 0.88),
          radius * 0.07 * pulse,
          const Color(0xFFFFE082),
        );
      default:
        break;
    }
  }

  void _drawZ(
    Canvas canvas,
    Offset at,
    double size,
    Color color,
    double rot,
  ) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(rot);
    final p = Paint()
      ..color = color
      ..strokeWidth = math.max(1.6, size * 0.18)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-size * 0.42, -size * 0.4), Offset(size * 0.42, -size * 0.4), p);
    canvas.drawLine(Offset(size * 0.42, -size * 0.4), Offset(-size * 0.42, size * 0.4), p);
    canvas.drawLine(Offset(-size * 0.42, size * 0.4), Offset(size * 0.42, size * 0.4), p);
    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset c, double r, Color color) {
    if (r <= 0.4) return;
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.72)
      ..cubicTo(
        c.dx - r * 1.35,
        c.dy - r * 0.08,
        c.dx - r * 0.48,
        c.dy - r * 1.12,
        c.dx,
        c.dy - r * 0.32,
      )
      ..cubicTo(
        c.dx + r * 0.48,
        c.dy - r * 1.12,
        c.dx + r * 1.35,
        c.dy - r * 0.08,
        c.dx,
        c.dy + r * 0.72,
      );
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawPuff(Canvas canvas, Offset c, double r) {
    if (r <= 0.4) return;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c.translate(-r * 0.55, r * 0.12), r * 0.7, paint);
    canvas.drawCircle(c.translate(r * 0.5, r * 0.18), r * 0.62, paint);
  }

  void _drawDrop(Canvas canvas, Offset c, double r, Color color) {
    if (r <= 0.4) return;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r, c.dy, c.dx, c.dy + r * 0.9)
      ..quadraticBezierTo(c.dx - r, c.dy, c.dx, c.dy - r);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.wave != wave ||
        oldDelegate.time != time ||
        oldDelegate.poke != poke ||
        oldDelegate.outline != outline ||
        oldDelegate.empty != empty;
  }
}
