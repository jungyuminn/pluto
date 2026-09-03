import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

enum RepeatDeleteScope { thisOnly, thisAndAfter, all }

Future<RepeatDeleteScope?> showDeleteRepeatEventDialog(BuildContext context) {
  return showDialog<RepeatDeleteScope>(
    context: context,
    builder: (context) => const DeleteRepeatEventDialog(),
  );
}

class DeleteRepeatEventDialog extends StatelessWidget {
  const DeleteRepeatEventDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.deleteRepeatTitle,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: colors.text,
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
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.pressed,
      pressedColor: Color.lerp(colors.pressed, Colors.black, 0.08)!,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.danger,
            ),
          ),
        ),
      ),
    );
  }
}
