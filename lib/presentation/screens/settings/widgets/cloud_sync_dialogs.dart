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

Future<CloudOverlapChoice?> showCloudOverlapDialog(BuildContext context) {
  return showDialog<CloudOverlapChoice>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) => const _CloudChoiceDialog(
      title: AppStrings.cloudOverlapTitle,
      body: AppStrings.cloudOverlapBody,
      firstLabel: AppStrings.cloudOverlapMerge,
      firstValue: CloudOverlapChoice.merge,
      secondLabel: AppStrings.cloudOverlapAccount,
      secondValue: CloudOverlapChoice.accountOnly,
    ),
  );
}

Future<CloudSwitchChoice?> showCloudSwitchDialog(BuildContext context) {
  return showDialog<CloudSwitchChoice>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) => const _CloudChoiceDialog(
      title: AppStrings.cloudSwitchTitle,
      body: AppStrings.cloudSwitchBody,
      firstLabel: AppStrings.cloudSwitchFresh,
      firstValue: CloudSwitchChoice.fresh,
      secondLabel: AppStrings.cloudSwitchCopy,
      secondValue: CloudSwitchChoice.copy,
    ),
  );
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

class _CloudChoiceDialog<T> extends StatelessWidget {
  const _CloudChoiceDialog({
    required this.title,
    required this.body,
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
  });

  final String title;
  final String body;
  final String firstLabel;
  final T firstValue;
  final String secondLabel;
  final T secondValue;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(firstValue),
            color: colors.accentBright,
            pressedColor: Color.lerp(colors.accentBright, Colors.black, 0.16)!,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 52,
              child: Center(
                child: Text(
                  firstLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PressBounce(
            onPressed: () => Navigator.of(context).pop(secondValue),
            color: colors.border,
            pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 52,
              child: Center(
                child: Text(
                  secondLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
