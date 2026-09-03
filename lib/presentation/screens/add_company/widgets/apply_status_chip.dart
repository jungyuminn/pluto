import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/theme/app_colors.dart';

class ApplyStatusChip extends StatelessWidget {
  const ApplyStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: colors.secondary,
          ),
        ],
      ),
    );
  }
}
