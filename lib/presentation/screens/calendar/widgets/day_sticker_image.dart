import 'package:flutter/material.dart';

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
        child: Image.asset(
          widget.asset,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
