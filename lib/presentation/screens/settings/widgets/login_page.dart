import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/constants/oauth_config.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_skin_background.dart';
import 'package:pluto/core/utils/fade_in.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/cloud_sync_service.dart';
import 'package:pluto/presentation/screens/settings/widgets/account_sheet.dart';
import 'package:pluto/presentation/screens/settings/widgets/backup_dialogs.dart';
import 'package:pluto/presentation/screens/settings/widgets/cloud_sync_dialogs.dart';
import 'package:pluto/presentation/screens/settings/widgets/dots_loading_dialog.dart';
import 'package:pluto/presentation/screens/shell/shell_screen.dart';

Future<void> openLoginPage(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
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
  if (!context.mounted) return;
  if (AppAuthService.instance.user == null) return;
  if (CloudSyncService.instance.isBound) return;
  try {
    await bindCloudAccount(context);
  } on AppAuthException catch (error) {
    if (!context.mounted || error.code == 'canceled') return;
    await showBackupMessageDialog(
      context,
      title: AppStrings.accountFailedTitle,
      body: error.detail == null || error.detail!.isEmpty
          ? AppStrings.accountSyncFailedBody
          : '${AppStrings.accountSyncFailedBody}\n(${error.detail})',
    );
  }
}

class WebAuthGate extends StatefulWidget {
  const WebAuthGate({super.key});

  @override
  State<WebAuthGate> createState() => _WebAuthGateState();
}

class _WebAuthGateState extends State<WebAuthGate> {
  late final _auth = AppAuthService.instance.authState;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _auth,
      initialData: AppAuthService.instance.user,
      builder: (context, snapshot) {
        if (snapshot.data == null) return const WebLoginScreen();
        return const _WebBoundShell();
      },
    );
  }
}

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    return AppSkinBackground(
      liftForNav: false,
      child: SafeArea(
        child: _WebLoginIntro(
          busy: _busy,
          onGoogle: () => _run(AppAuthService.instance.signInWithGoogle),
          onApple: () => _run(AppAuthService.instance.signInWithApple),
          onKakao: () => _run(AppAuthService.instance.signInWithKakao),
        ),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await runAccountAction(context, action);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _WebBoundShell extends StatefulWidget {
  const _WebBoundShell();

  @override
  State<_WebBoundShell> createState() => _WebBoundShellState();
}

class _WebBoundShellState extends State<_WebBoundShell> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bind());
    });
  }

  Future<void> _bind() async {
    if (!mounted) return;
    try {
      await ensureCloudBound(context);
      if (mounted) setState(() => _ready = true);
    } on AppAuthException catch (error) {
      if (!mounted) return;
      if (error.code != 'canceled') {
        await showBackupMessageDialog(
          context,
          title: AppStrings.accountFailedTitle,
          body: error.detail == null || error.detail!.isEmpty
              ? AppStrings.accountSyncFailedBody
              : '${AppStrings.accountSyncFailedBody}\n(${error.detail})',
        );
      }
      if (mounted) await AppAuthService.instance.signOut();
    } catch (_) {
      if (!mounted) return;
      await showBackupMessageDialog(
        context,
        title: AppStrings.accountFailedTitle,
        body: AppStrings.accountSyncFailedBody,
      );
      if (mounted) await AppAuthService.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const ShellScreen();
    return const AppSkinBackground(
      liftForNav: false,
      child: Center(child: DotsLoadingDialog()),
    );
  }
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
                  _LoginIntro(
                    previewWidth: previewWidth,
                    busy: _busy,
                    onGoogle: () => _run(AppAuthService.instance.signInWithGoogle),
                    onApple: () => _run(AppAuthService.instance.signInWithApple),
                    onKakao: () => _run(AppAuthService.instance.signInWithKakao),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final signedIn = await runAccountAction(context, action);
      if (!signedIn || !mounted) return;
      await bindCloudAccount(
        context,
        onSettingsReady: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _WebLoginIntro extends StatelessWidget {
  const _WebLoginIntro({
    required this.busy,
    required this.onGoogle,
    required this.onApple,
    required this.onKakao,
  });

  final bool busy;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onKakao;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final showKakao = OauthConfig.kakaoEnabled;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 56),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          const logoSize = 208.0;
          const brandSize = 46.0;
          const taglineSize = 22.0;
          const buttonSize = 64.0;
          const buttonGap = 44.0;
          final logoTop = !height.isFinite ? 80.0 : height * 0.20;
          final tooShort = !height.isFinite || height < 640;

          Widget fade(int ms, Widget child) {
            return FadeIn(
              delay: Duration(milliseconds: ms),
              duration: const Duration(milliseconds: 460),
              offset: const Offset(0, 14),
              child: child,
            );
          }

          final column = Column(
            children: [
              SizedBox(height: tooShort ? 48 : logoTop),
              fade(
                40,
                Center(
                  child: SvgPicture.asset(
                    AppIcons.plutoLogo,
                    width: logoSize,
                    height: logoSize,
                  ),
                ),
              ),
              const SizedBox(height: 56),
              fade(
                110,
                Text(
                  AppStrings.webLoginBrand,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.jalnan,
                    fontSize: brandSize,
                    height: 1.1,
                    letterSpacing: 1.4,
                    color: colors.text,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              fade(
                180,
                Text(
                  AppStrings.webLoginTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: taglineSize,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: colors.text,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (tooShort) const SizedBox(height: 64) else const Spacer(),
              IgnorePointer(
                ignoring: busy,
                child: fade(
                  320,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showKakao) ...[
                        _ProviderButton(
                          asset: AppIcons.kakaoLogo,
                          background: const Color(0xFFFEE500),
                          size: buttonSize,
                          onPressed: onKakao,
                        ),
                        const SizedBox(width: buttonGap),
                      ],
                      _ProviderButton(
                        asset: AppIcons.googleLogo,
                        background: Colors.white,
                        border: colors.border,
                        size: buttonSize,
                        onPressed: onGoogle,
                      ),
                      const SizedBox(width: buttonGap),
                      _ProviderButton(
                        asset: AppIcons.appleLogo,
                        background: const Color(0xFF111111),
                        tint: Colors.white,
                        size: buttonSize,
                        onPressed: onApple,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              fade(
                380,
                Text(
                  AppStrings.webLoginPcLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colors.muted,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (!tooShort) const SizedBox(height: 172),
            ],
          );

          if (tooShort) {
            return SingleChildScrollView(child: column);
          }
          return column;
        },
      ),
    );
  }
}

class _LoginIntro extends StatelessWidget {
  const _LoginIntro({
    required this.previewWidth,
    required this.busy,
    required this.onGoogle,
    required this.onApple,
    required this.onKakao,
  });

  final double previewWidth;
  final bool busy;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onKakao;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final showKakao = OauthConfig.kakaoEnabled;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        IgnorePointer(
          ignoring: busy,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showKakao) ...[
                _appear(
                  3,
                  _ProviderButton(
                    asset: AppIcons.kakaoLogo,
                    background: const Color(0xFFFEE500),
                    onPressed: onKakao,
                  ),
                ),
                const SizedBox(width: 44),
              ],
              _appear(
                showKakao ? 4 : 3,
                _ProviderButton(
                  asset: AppIcons.googleLogo,
                  background: Colors.white,
                  border: colors.border,
                  onPressed: onGoogle,
                ),
              ),
              const SizedBox(width: 44),
              _appear(
                showKakao ? 5 : 4,
                _ProviderButton(
                  asset: AppIcons.appleLogo,
                  background: const Color(0xFF111111),
                  tint: Colors.white,
                  onPressed: onApple,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
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
    this.size = 56,
  });

  final String asset;
  final Color background;
  final Color? border;
  final Color? tint;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tintColor = tint;
    final iconSize = size * 30 / 56;
    final image = asset.endsWith('.svg')
        ? SvgPicture.asset(
            asset,
            width: iconSize,
            height: iconSize,
            colorFilter: tintColor == null
                ? null
                : ColorFilter.mode(tintColor, BlendMode.srcIn),
          )
        : Image.asset(
            asset,
            width: iconSize,
            height: iconSize,
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
        width: size,
        height: size,
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
