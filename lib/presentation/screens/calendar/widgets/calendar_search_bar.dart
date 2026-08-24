import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class CalendarSearchBar extends StatelessWidget {
  const CalendarSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onPrevious,
    required this.onNext,
    required this.index,
    required this.total,
    this.hintText = AppStrings.calendarSearchHint,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final int index;
  final int total;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasQuery = controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontFamily: AppFonts.of(context),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: AppFonts.of(context),
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: colors.card,
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          suffixIcon: hasQuery
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total == 0 ? '0/0' : '${index + 1}/$total',
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    _StepButton(
                      icon: Icons.keyboard_arrow_up_rounded,
                      onPressed: total == 0 ? null : onPrevious,
                    ),
                    _StepButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      onPressed: total == 0 ? null : onNext,
                    ),
                    const SizedBox(width: 4),
                  ],
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 40,
            maxHeight: 40,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.92,
      color: Colors.transparent,
      pressedColor: AppColors.of(context).pressed,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 22,
          color: onPressed == null
              ? AppColors.of(context).muted
              : AppColors.of(context).icon,
        ),
      ),
    );
  }
}
