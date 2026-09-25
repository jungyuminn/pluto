import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

class AddEventButton extends StatelessWidget {
  const AddEventButton({super.key, this.onPressed, this.label});

  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.pressed,
      pressedColor: colors.border,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          label ?? AppStrings.addEvent,
          style: TextStyle(
            color: Color.lerp(colors.muted, colors.hint, 0.4),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
