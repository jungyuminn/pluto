import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

enum RepeatDeleteScope { thisOnly, thisAndAfter, all }

Future<RepeatDeleteScope?> showDeleteRepeatEventDialog(BuildContext context) {
  return showDialog<RepeatDeleteScope>(
    context: context,
    builder: (context) => const DeleteRepeatEventDialog(),
  );
}

class DeleteRepeatEventDialog extends StatelessWidget {
  const DeleteRepeatEventDialog({super.key});

  static const _red = Color(0xFFEF4444);
  static const _gray = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.deleteRepeatTitle,
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 20),
            _OptionButton(
              label: AppStrings.deleteRepeatThis,
              onPressed: () {
                Navigator.of(context).pop(RepeatDeleteScope.thisOnly);
              },
            ),
            const SizedBox(height: 10),
            _OptionButton(
              label: AppStrings.deleteRepeatFollowing,
              onPressed: () {
                Navigator.of(context).pop(RepeatDeleteScope.thisAndAfter);
              },
            ),
            const SizedBox(height: 10),
            _OptionButton(
              label: AppStrings.deleteRepeatAll,
              onPressed: () => Navigator.of(context).pop(RepeatDeleteScope.all),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      color: DeleteRepeatEventDialog._gray,
      pressedColor: Color.lerp(DeleteRepeatEventDialog._gray, Colors.black, 0.08)!,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DeleteRepeatEventDialog._red,
            ),
          ),
        ),
      ),
    );
  }
}
