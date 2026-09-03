import 'package:flutter/material.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 28,
  });

  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.chevron_left_rounded,
            size: iconSize,
            color: colors.icon,
          ),
        ),
      ),
    );
  }
}
