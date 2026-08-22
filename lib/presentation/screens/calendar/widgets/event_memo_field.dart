import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class EventMemoField extends StatelessWidget {
  const EventMemoField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 4,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: TextInputAction.newline,
      style: TextStyle(
        fontFamily: AppFonts.of(context),
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: colors.secondary,
      ),
      decoration: InputDecoration(
        hintText: hintText ?? AppStrings.eventMemoHint,
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
