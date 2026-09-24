import 'package:flutter/material.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class AppBarPill extends StatelessWidget {
  const AppBarPill({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
  });

  final String asset;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: PressBounce(
        onPressed: onPressed,
        color: Colors.transparent,
        pressedColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: AppAssetImage(
            asset: asset,
            width: 21,
            height: 21,
            color: colors.muted,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}
