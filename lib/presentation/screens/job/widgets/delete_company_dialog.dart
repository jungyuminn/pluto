import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

Future<bool> showDeleteCompanyDialog(
  BuildContext context, {
  required String companyName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => DeleteCompanyDialog(companyName: companyName),
  );
  return confirmed == true;
}

class DeleteCompanyDialog extends StatelessWidget {
  const DeleteCompanyDialog({super.key, required this.companyName});

  final String companyName;

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
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: companyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _red,
                  ),
                ),
                const TextSpan(text: ' ${AppStrings.deleteCompanyBody}'),
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
