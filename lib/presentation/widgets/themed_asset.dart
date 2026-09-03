import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/data/datasources/theme_preference.dart';

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
      gaplessPlayback: true,
    );
    final dark = Theme.of(context).brightness == Brightness.dark;
    final skin =
        AppScope.maybeOf(context)?.themePreference.skin ?? AppSkin.classic;
    final custom =
        AppScope.maybeOf(context)?.themePreference.usesCustom ?? false;
    if (!dark &&
        !forceTint &&
        skin == AppSkin.classic &&
        !custom &&
        AppColors.of(context).icon == AppColors.light.icon) {
      return image;
    }
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppColors.of(context).icon,
        BlendMode.srcIn,
      ),
      child: image,
    );
  }
}
