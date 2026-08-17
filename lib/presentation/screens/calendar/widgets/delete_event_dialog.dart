import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

Future<bool> showDeleteEventDialog(
  BuildContext context, {
  required String title,
  String body = AppStrings.deleteEventBody,
  String? message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => DeleteEventDialog(
      title: title,
      body: body,
      message: message,
    ),
  );
  return confirmed == true;
}

class DeleteEventDialog extends StatelessWidget {
  const DeleteEventDialog({
    super.key,
    required this.title,
    this.body = AppStrings.deleteEventBody,
    this.message,
  });

  final String title;
  final String body;
  final String? message;

  static const _red = Color(0xFFEF4444);
  static const _gray = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        AppStrings.deleteTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null)
            Text(
              message!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            )
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _red,
                    ),
                  ),
                  TextSpan(text: ' $body'),
                ],
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(false),
                  color: _gray,
                  pressedColor: Color.lerp(_gray, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(true),
                  color: _red,
                  pressedColor: Color.lerp(_red, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.delete,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
