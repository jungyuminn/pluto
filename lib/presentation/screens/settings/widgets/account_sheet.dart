import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/app_auth_service.dart';
import 'package:job_planner/presentation/screens/settings/widgets/backup_dialogs.dart';

String _shortError(Object error) {
  if (error is FirebaseAuthException) return error.code;
  final text = error.toString();
  return text.length > 80 ? text.substring(0, 80) : text;
}

Future<void> runAccountAction(
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
      builder: (context) => const _AuthLoadingDialog(),
    );
    await WidgetsBinding.instance.endOfFrame;
  }
  try {
    await work;
    if (!context.mounted) return;
    if (loadingShown) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (popSheetOnSuccess && context.mounted) {
      Navigator.of(context).pop();
    }
  } on AppAuthException catch (error) {
    if (loadingShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (error.code == 'canceled') return;
    if (!context.mounted) return;
    await showBackupMessageDialog(
      context,
      title: error.code == 'account_delete'
          ? AppStrings.accountDeleteFailedTitle
          : AppStrings.accountFailedTitle,
      body: switch (error.code) {
        'kakao_key' => AppStrings.accountKakaoKeyBody,
        'kakao_misconfigured' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountKakaoMisconfiguredBody
            : '${AppStrings.accountKakaoMisconfiguredBody}\n(${error.detail})',
        'kakao_oidc' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountKakaoOidcBody
            : '${AppStrings.accountKakaoOidcBody}\n(${error.detail})',
        'unavailable' => AppStrings.accountUnavailableBody,
        'account_delete' => error.detail == null || error.detail!.isEmpty
            ? AppStrings.accountFailedBody
            : '${AppStrings.accountFailedBody}\n(${error.detail})',
        _ => AppStrings.accountFailedBody,
      },
    );
  } catch (error) {
    if (loadingShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (AppAuthService.isUserCanceled(error)) return;
    if (!context.mounted) return;
    await showBackupMessageDialog(
      context,
      title: AppStrings.accountFailedTitle,
      body: '${AppStrings.accountFailedBody}\n(${_shortError(error)})',
    );
  }
}

class _AuthLoadingDialog extends StatelessWidget {
  const _AuthLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Center(child: _AuthDotsLoader()),
    );
  }
}

class _AuthDotsLoader extends StatefulWidget {
  const _AuthDotsLoader();

  @override
  State<_AuthDotsLoader> createState() => _AuthDotsLoaderState();
}

class _AuthDotsLoaderState extends State<_AuthDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.of(context).accentBright;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Transform.translate(
                offset: Offset(0, -4 * _bounce(i)),
                child: Opacity(
                  opacity: 0.35 + 0.65 * _bounce(i),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 10, height: 10),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  double _bounce(int index) {
    final t = (_controller.value - index / 3) % 1;
    return math.sin(t * math.pi).clamp(0, 1);
  }
}

Future<bool> showAccountDeleteConfirmDialog(BuildContext context) async {
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
              AppStrings.accountDeleteBody,
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
