import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';

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
    final colors = AppColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: AppFonts.of(context),
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.roundStageNameHint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.of(context),
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
