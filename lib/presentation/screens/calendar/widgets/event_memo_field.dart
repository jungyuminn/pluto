import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';

class EventMemoField extends StatelessWidget {
  const EventMemoField({
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
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamily: AppFonts.pretendard,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475569),
      ),
      decoration: const InputDecoration(
        hintText: AppStrings.eventMemoHint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.pretendard,
          color: Color(0xFF666666),
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
