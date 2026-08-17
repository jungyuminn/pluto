import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';

class RoundNameField extends StatelessWidget {
  const RoundNameField({
    super.key,
    required this.controller,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: AppFonts.pretendard,
        fontWeight: FontWeight.w700,
      ),
      decoration: const InputDecoration(
        hintText: AppStrings.roundStageNameHint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: Color(0xFF666666),
          fontWeight: FontWeight.w600,
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
