import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class AddCompanyButton extends StatelessWidget {
  const AddCompanyButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      color: const Color(0xFFF2F3F7),
      pressedColor: const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const Text(
          AppStrings.addCompany,
          style: TextStyle(
            color: Color(0xFF666666),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
