import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class AppArrow extends StatelessWidget {
  const AppArrow.left({super.key, this.size = 22, this.color}) : left = true;

  const AppArrow.right({super.key, this.size = 22, this.color}) : left = false;

  final bool left;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppAssetImage(
      asset: left ? AppIcons.arrowLeft : AppIcons.arrowRight,
      width: size,
      height: size,
      color: color,
    );
  }
}
