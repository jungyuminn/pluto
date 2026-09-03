import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/fade_in.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/app_auth_service.dart';
import 'package:job_planner/presentation/screens/settings/widgets/account_sheet.dart';

Future<void> openLoginPage(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => const LoginSheet(),
  );
}

class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final previewWidth =
        (MediaQuery.sizeOf(context).width - 40).clamp(0.0, 360.0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 36 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const SizedBox(width: 36, height: 4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _appear(0, _DeviceCarousel(width: previewWidth)),
                  const SizedBox(height: 28),
                  _appear(
                    1,
                    Text(
                      AppStrings.accountLoginBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: colors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _appear(
                    2,
                    Text(
                      AppStrings.accountLoginPcHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: colors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _appear(
                        3,
                        _ProviderButton(
                          asset: AppIcons.kakaoLogo,
                          background: const Color(0xFFFEE500),
                          onPressed: () =>
                              _run(AppAuthService.instance.signInWithKakao),
                        ),
                      ),
                      const SizedBox(width: 44),
                      _appear(
                        4,
                        _ProviderButton(
                          asset: AppIcons.googleLogo,
                          background: Colors.white,
                          border: colors.border,
                          onPressed: () =>
                              _run(AppAuthService.instance.signInWithGoogle),
                        ),
                      ),
                      const SizedBox(width: 44),
                      _appear(
                        5,
                        _ProviderButton(
                          asset: AppIcons.appleLogo,
                          background: const Color(0xFF111111),
                          tint: Colors.white,
                          onPressed: () =>
                              _run(AppAuthService.instance.signInWithApple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appear(int order, Widget child) {
    return FadeIn(
      delay: Duration(milliseconds: 70 * order),
      duration: const Duration(milliseconds: 460),
      offset: const Offset(0, 14),
      child: child,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await runAccountAction(
        context,
        action,
        popSheetOnSuccess: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DeviceCarousel extends StatefulWidget {
  const _DeviceCarousel({required this.width});

  final double width;

  @override
  State<_DeviceCarousel> createState() => _DeviceCarouselState();
}

class _DeviceCarouselState extends State<_DeviceCarousel> {
  static const _assets = [AppIcons.notebook, AppIcons.tablet];
  static const _autoInterval = Duration(seconds: 4);

  late final PageController _pages;
  Timer? _auto;
  var _index = 0;
  var _held = false;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
    _arm();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _arm() {
    _auto?.cancel();
    _auto = Timer(_autoInterval, _next);
  }

  void _next() {
    if (!mounted || _held) return;
    final next = (_index + 1) % _assets.length;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final imageWidth = widget.width * 0.86;
    final height = imageWidth * 0.62;
    return Column(
      children: [
        SizedBox(
          width: widget.width,
          height: height,
          child: Listener(
            onPointerDown: (_) {
              _held = true;
              _auto?.cancel();
            },
            onPointerUp: (_) {
              _held = false;
              _arm();
            },
            onPointerCancel: (_) {
              _held = false;
              _arm();
            },
            child: PageView.builder(
              controller: _pages,
              itemCount: _assets.length,
              onPageChanged: (index) {
                setState(() => _index = index);
                if (!_held) _arm();
              },
              itemBuilder: (context, index) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: SizedBox(
                        width: imageWidth * 0.78,
                        height: imageWidth * 0.42,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          _assets[index],
                          width: imageWidth,
                          height: height,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _assets.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? colors.accentBright : colors.border,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.asset,
    required this.background,
    required this.onPressed,
    this.border,
    this.tint,
  });

  final String asset;
  final Color background;
  final Color? border;
  final Color? tint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tintColor = tint;
    final image = asset.endsWith('.svg')
        ? SvgPicture.asset(
            asset,
            width: 30,
            height: 30,
            colorFilter: tintColor == null
                ? null
                : ColorFilter.mode(tintColor, BlendMode.srcIn),
          )
        : Image.asset(
            asset,
            width: 30,
            height: 30,
            color: tint,
            colorBlendMode: BlendMode.srcIn,
            filterQuality: FilterQuality.high,
          );
    return PressBounce(
      onPressed: onPressed,
      color: background,
      pressedColor: Color.lerp(background, Colors.black, 0.08)!,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 56,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border!),
          ),
          child: Center(child: image),
        ),
      ),
    );
  }
}
