import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class SaveCompanyButton extends StatelessWidget {
  const SaveCompanyButton({
    super.key,
    required this.onPressed,
    required this.color,
  });

  final VoidCallback onPressed;
  final Color color;

  static const size = 44.0;
  static const _iconSize = 22.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.26),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: color,
        pressedColor: Color.lerp(color, Colors.black, 0.16)!,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                AppIcons.cursor,
                width: _iconSize,
                height: _iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
