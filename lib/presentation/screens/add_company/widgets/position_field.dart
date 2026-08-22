import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class PositionField extends StatelessWidget {
  const PositionField({
    super.key,
    required this.controller,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      style: TextStyle(
        fontFamily: AppFonts.of(context),
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: colors.secondary,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.positionHint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.of(context),
          color: colors.hint,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
