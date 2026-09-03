import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class EventActionIcon extends StatelessWidget {
  const EventActionIcon({
    super.key,
    required this.onPressed,
    required this.color,
    this.child,
    this.label,
    this.text,
    this.selected = false,
    this.size = 20,
  });

  final VoidCallback onPressed;
  final Widget? child;
  final Color color;
  final String? label;
  final String? text;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final caption = text?.trim() ?? '';
    final hasText = caption.isNotEmpty;
    final hasIcon = child != null;
    return Semantics(
      button: true,
      label: label ?? caption,
      child: PressBounce(
        onPressed: onPressed,
        color: selected || hasText ? colors.card : Colors.transparent,
        pressedColor: selected || hasText ? colors.pressed : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.fromLTRB(hasIcon ? 8 : 10, 5, 10, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon)
                ColorFiltered(
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: child,
                    ),
                  ),
                ),
              if (hasIcon && hasText) const SizedBox(width: 6),
              if (hasText)
                Text(
                  caption,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
