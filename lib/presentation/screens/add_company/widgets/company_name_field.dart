import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';

class CompanyNameField extends StatelessWidget {
  const CompanyNameField({
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
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: AppFonts.pretendard,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.companyNameHint,
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
