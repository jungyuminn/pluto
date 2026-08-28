import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class EventActionIcon extends StatelessWidget {
  const EventActionIcon({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    this.label,
    this.text,
    this.selected = false,
    this.size = 20,
  });

  final VoidCallback onPressed;
  final Widget child;
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
    return Semantics(
      button: true,
      label: label ?? caption,
      child: PressBounce(
        onPressed: onPressed,
        color: selected || hasText ? colors.card : Colors.transparent,
        pressedColor: selected || hasText ? colors.pressed : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 5, hasText ? 10 : 8, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (hasText) ...[
                const SizedBox(width: 6),
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
            ],
          ),
        ),
      ),
    );
  }
}
