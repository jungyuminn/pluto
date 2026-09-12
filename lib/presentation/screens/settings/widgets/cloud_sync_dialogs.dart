import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/cloud_sync_service.dart';

Future<void> bindCloudAccount(
  BuildContext context, {
  VoidCallback? onSettingsReady,
}) {
  return CloudSyncService.instance.reconcileAfterLogin(
    context,
    onSettingsReady: onSettingsReady,
  );
}

Future<void> ensureCloudBound(BuildContext context) {
  return CloudSyncService.instance.ensureBound(context);
}

Future<bool> showAccountDeleteLocalDialog(BuildContext context) async {
  final reset = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final colors = AppColors.of(context);
      return AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.accountDeleteLocalTitle,
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
              AppStrings.accountDeleteLocalBody,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            PressBounce(
              onPressed: () => Navigator.of(context).pop(false),
              color: colors.border,
              pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    AppStrings.accountDeleteKeepLocal,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            PressBounce(
              onPressed: () => Navigator.of(context).pop(true),
              color: colors.danger,
              pressedColor: Color.lerp(colors.danger, Colors.black, 0.16)!,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    AppStrings.accountDeleteResetLocal,
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
    },
  );
  return reset == true;
}
