import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class HomeLeftoverCard extends StatelessWidget {
  const HomeLeftoverCard({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  static const _blue = Color(0xFF40A6FF);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        pressedScale: 0.98,
        color: Colors.white,
        pressedColor: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.leftoverTodos(count),
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: _blue,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: _blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
