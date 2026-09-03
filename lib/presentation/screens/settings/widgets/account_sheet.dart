import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/app_auth_service.dart';
import 'package:job_planner/presentation/screens/settings/widgets/backup_dialogs.dart';
import 'package:job_planner/presentation/screens/settings/widgets/dots_loading_dialog.dart';

String _shortError(Object error) {
  if (error is FirebaseAuthException) return error.code;
  final text = error.toString();
  return text.length > 80 ? text.substring(0, 80) : text;
}

Future<bool> runAccountAction(
  BuildContext context,
  Future<void> Function() action, {
  bool popSheetOnSuccess = false,
}) async {
  var loadingShown = false;
  final work = action();
  var finished = false;
  work.whenComplete(() => finished = true).ignore();
  await Future.any([
    work.then((_) {}, onError: (_) {}),
    Future<void>.delayed(const Duration(milliseconds: 200)),
  ]);
  if (!finished && context.mounted) {
    loadingShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: const Color(0x4D000000),
      builder: (context) => const DotsLoadingDialog(),
    );
    await WidgetsBinding.instance.endOfFrame;
  }
  try {
    await work;
    if (!context.mounted) return false;
    if (loadingShown) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (popSheetOnSuccess && context.mounted) {
      Navigator.of(context).pop();
    }
    return true;
  } on AppAuthException catch (error) {
    if (loadingShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (error.code == 'canceled') return false;
    if (!context.mounted) return false;
    await showBackupMessageDialog(
      context,
      title: error.code == 'account_delete'
          ? AppStrings.accountDeleteFailedTitle
          : AppStrings.accountFailedTitle,
      body: switch (error.code) {
        'kakao_key' => AppStrings.accountKakaoKeyBody,
        'kakao_web_key' => AppStrings.accountKakaoWebKeyBody,
        'kakao_web_aud' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountKakaoWebAudBody
            : '${AppStrings.accountKakaoWebAudBody}\n${error.detail}',
        'kakao_web_misconfigured' =>
          error.detail == null || error.detail!.isEmpty
              ? AppStrings.accountKakaoWebMisconfiguredBody
              : '${AppStrings.accountKakaoWebMisconfiguredBody}\n(${error.detail})',
        'kakao_misconfigured' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountKakaoMisconfiguredBody
            : '${AppStrings.accountKakaoMisconfiguredBody}\n(${error.detail})',
        'kakao_oidc' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountKakaoOidcBody
            : '${AppStrings.accountKakaoOidcBody}\n${error.detail}',
        'unavailable' => AppStrings.accountUnavailableBody,
        'account_delete' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountFailedBody
            : '${AppStrings.accountFailedBody}\n(${error.detail})',
        'sync_logout' => AppStrings.accountLogoutSyncBody,
        'sync' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountSyncFailedBody
            : '${AppStrings.accountSyncFailedBody}\n(${error.detail})',
        _ => AppStrings.accountFailedBody,
      },
    );
    return false;
  } catch (error) {
    if (loadingShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (AppAuthService.isUserCanceled(error)) return false;
    if (!context.mounted) return false;
    await showBackupMessageDialog(
      context,
      title: AppStrings.accountFailedTitle,
      body: '${AppStrings.accountFailedBody}\n(${_shortError(error)})',
    );
    return false;
  }
}

Future<bool> showAccountDeleteConfirmDialog(
  BuildContext context, {
  required String provider,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = AppColors.of(context);
      return AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.accountDeleteTitle,
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
              AppStrings.accountDeleteBody(provider),
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
                    pressedColor:
                        Color.lerp(colors.danger, Colors.black, 0.16)!,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          AppStrings.accountDelete,
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
    },
  );
  return confirmed == true;
}
