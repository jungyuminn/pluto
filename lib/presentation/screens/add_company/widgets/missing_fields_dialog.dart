import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

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

  static const _blue = Color(0xFF60A5FA);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          PressBounce(
            onPressed: () => Navigator.of(context).pop(),
            color: _blue,
            pressedColor: Color.lerp(_blue, Colors.black, 0.16)!,
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
