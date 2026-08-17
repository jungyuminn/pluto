import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class ThemedAsset extends StatelessWidget {
  const ThemedAsset({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.semanticLabel,
    this.forceTint = false,
  });

  final String asset;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final bool forceTint;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
    );
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!dark && !forceTint) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppColors.of(context).icon,
        BlendMode.srcIn,
      ),
      child: image,
    );
  }
}
