import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';

Future<bool> showDeleteCoverLetterDialog(
  BuildContext context, {
  required String fileName,
  String title = AppStrings.deleteCoverLetterTitle,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => DeleteCoverLetterDialog(
      fileName: fileName,
      title: title,
    ),
  );
  return confirmed == true;
}

class DeleteCoverLetterDialog extends StatelessWidget {
  const DeleteCoverLetterDialog({
    super.key,
    required this.fileName,
    this.title = AppStrings.deleteCoverLetterTitle,
  });

  final String fileName;
  final String title;

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
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.danger,
                  ),
                ),
                const TextSpan(text: ' ${AppStrings.deleteCoverLetterBody}'),
              ],
            ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(false),
                  color: colors.border,
                  pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
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
                  color: colors.danger,
                  pressedColor: Color.lerp(colors.danger, Colors.black, 0.16)!,
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
