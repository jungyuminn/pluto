import 'package:flutter/material.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_emoji_sheet.dart';

class DayStickerImage extends StatefulWidget {
  const DayStickerImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.opacity = 1,
    this.pop = false,
  });

  final String asset;
  final double? width;
  final double? height;
  final double opacity;
  final bool pop;

  static const popDuration = Duration(milliseconds: 280);

  @override
  State<DayStickerImage> createState() => _DayStickerImageState();
}

class _DayStickerImageState extends State<DayStickerImage> {
  late var _scale = widget.pop ? 0.72 : 1.0;
  late var _opacity = widget.pop ? 0.0 : 1.0;

  @override
  void initState() {
    super.initState();
    if (!widget.pop) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _scale = 1;
        _opacity = 1;
      });
    });
  }

  int? _cachePx(BuildContext context, BoxConstraints constraints) {
    final boxW = widget.width ??
        (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
    final boxH = widget.height ??
        (constraints.maxHeight.isFinite ? constraints.maxHeight : null);
    final logical = switch ((boxW, boxH)) {
      (final w?, final h?) => w < h ? w : h,
      (final w?, null) => w,
      (null, final h?) => h,
      _ => 0.0,
    };
    if (logical <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final scale = PcLayout.isPc && dpr < 2 ? 2.0 : dpr;
    return (logical * scale).round().clamp(32, 512);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: DayStickerImage.popDuration,
      curve: Curves.easeOutCubic,
      opacity: _opacity * widget.opacity,
      child: AnimatedScale(
        duration: DayStickerImage.popDuration,
        curve: Curves.easeOutBack,
        scale: _scale,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Image.asset(
              DayStickers.resolve(widget.asset),
              width: widget.width,
              height: widget.height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              cacheWidth: _cachePx(context, constraints),
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
