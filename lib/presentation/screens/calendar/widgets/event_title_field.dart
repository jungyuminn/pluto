import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class EventTitleField extends StatelessWidget {
  const EventTitleField({
    super.key,
    required this.controller,
    this.focusNode,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.done,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: AppFonts.pretendard,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.eventTitleHint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: colors.hint,
          fontWeight: FontWeight.w600,
          fontSize: 20,
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
