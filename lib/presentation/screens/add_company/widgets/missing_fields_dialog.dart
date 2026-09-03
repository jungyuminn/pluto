import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

Future<void> showMissingFieldsDialog(
  BuildContext context, {
  String title = AppStrings.missingFieldsTitle,
  String body = AppStrings.missingFieldsBody,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => MissingFieldsDialog(title: title, body: body),
  );
}

class MissingFieldsDialog extends StatelessWidget {
  const MissingFieldsDialog({
    super.key,
    this.title = AppStrings.missingFieldsTitle,
    this.body = AppStrings.missingFieldsBody,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          PressBounce(
            onPressed: () => Navigator.of(context).pop(),
            color: colors.accentBright,
            pressedColor: Color.lerp(colors.accentBright, Colors.black, 0.16)!,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  AppStrings.confirm,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
