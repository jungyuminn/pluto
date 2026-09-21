import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/presentation/screens/settings/widgets/login_page.dart';
import 'package:pluto/presentation/screens/settings/widgets/release_note_demos.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

bool _classicDefault(BuildContext context) {
  final theme = AppScope.maybeOf(context)?.themePreference;
  return (theme?.skin ?? AppSkin.classic) == AppSkin.classic &&
      !(theme?.usesCustom ?? false);
}

class CalendarFeatureIntroBanner extends StatelessWidget {
  const CalendarFeatureIntroBanner({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    if (kIsWeb) return const SizedBox.shrink();
    final tutorial = TutorialController.maybeOf(context);
    if (tutorial == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: tutorial,
      builder: (context, _) {
        return StreamBuilder(
          stream: AppAuthService.instance.authState,
          initialData: AppAuthService.instance.user,
          builder: (context, snapshot) {
            final signedIn = snapshot.data != null;
            if (signedIn && tutorial.showFeatureIntro) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                tutorial.dismissFeatureIntro();
              });
            }
            final show =
                !tutorial.active && tutorial.showFeatureIntro && !signedIn;
            return _BannerReveal(show: show);
          },
        );
      },
    );
  }
}

class _BannerReveal extends StatefulWidget {
  const _BannerReveal({required this.show});

  final bool show;

  @override
  State<_BannerReveal> createState() => _BannerRevealState();
}

class _BannerRevealState extends State<_BannerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  var _held = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _motion,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      ),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _motion,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
        reverseCurve: const Interval(0.35, 1, curve: Curves.easeIn),
      ),
    );
    if (widget.show) {
      _held = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _motion.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_BannerReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show == oldWidget.show) return;
    if (widget.show) {
      setState(() => _held = true);
      _motion.forward(from: 0);
      return;
    }
    _motion.reverse().whenComplete(() {
      if (!mounted || widget.show) return;
      setState(() => _held = false);
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: _held
          ? FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: const _BannerBody(),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final defaultTheme = _classicDefault(context);
    final fill = defaultTheme
        ? colors.selected
        : colors.tint(colors.accent, 0.16);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: PressBounce(
                onPressed: () => showCalendarFeatureIntro(context),
                color: Colors.transparent,
                pressedColor: defaultTheme
                    ? Color.lerp(colors.selected, Colors.black, 0.08)!
                    : colors.tint(colors.accent, 0.26),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 8, 18),
                  child: Row(
                    children: [
                      AppAssetImage(
                        asset: AppIcons.plutoLogo,
                        width: 22,
                        height: 22,
                        color: defaultTheme ? null : colors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.featureIntroBanner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: colors.accentBright,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PressBounce(
              onPressed: () {
                TutorialController.maybeOf(context)?.dismissFeatureIntro();
              },
              pressedScale: 0.88,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 18, 12, 18),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colors.muted,
                  semanticLabel: AppStrings.featureIntroClose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _IntroClose { login }

Future<void> showCalendarFeatureIntro(BuildContext context) async {
  var feature = _IntroFeature.pc;
  while (context.mounted) {
    final action = await showModalBottomSheet<_IntroClose>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useSafeArea: false,
      showDragHandle: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x4D000000),
      elevation: 0,
      builder: (sheetContext) {
        return CalendarFeatureIntroSheet(
          initial: feature,
          onFeatureChanged: (value) => feature = value,
          onLogin: () => Navigator.of(sheetContext).pop(_IntroClose.login),
        );
      },
    );
    if (!context.mounted) return;
    if (action != _IntroClose.login) return;
    await openLoginPage(context);
    if (!context.mounted) return;
    if (AppAuthService.instance.user != null) return;
  }
}

class CalendarFeatureIntroSheet extends StatefulWidget {
  const CalendarFeatureIntroSheet({
    super.key,
    this.initial = _IntroFeature.pc,
    this.onFeatureChanged,
    required this.onLogin,
  });

  final _IntroFeature initial;
  final ValueChanged<_IntroFeature>? onFeatureChanged;
  final VoidCallback onLogin;

  @override
  State<CalendarFeatureIntroSheet> createState() =>
      _CalendarFeatureIntroSheetState();
}

enum _IntroFeature { pc, sync, ai, friends }

class _CalendarFeatureIntroSheetState extends State<CalendarFeatureIntroSheet> {
  late _IntroFeature _open = widget.initial;

  void _select(_IntroFeature feature) {
    setState(() => _open = feature);
    widget.onFeatureChanged?.call(feature);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final defaultTheme = _classicDefault(context);
    final rowHighlight =
        defaultTheme ? colors.selected : colors.tint(colors.accent, 0.16);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

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
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.muted.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const SizedBox(width: 36, height: 4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: IgnorePointer(
                        key: ValueKey(_open),
                        child: ReleaseDemoView(demo: _open.demo),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _open.body,
                        key: ValueKey(_open.body),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: colors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    asset: AppIcons.monitor,
                    title: AppStrings.featureIntroPcTitle,
                    selected: _open == _IntroFeature.pc,
                    iconColor: defaultTheme ? colors.muted : colors.accent,
                    highlight: rowHighlight,
                    onPressed: () => _select(_IntroFeature.pc),
                  ),
                  _FeatureRow(
                    asset: AppIcons.link,
                    title: AppStrings.featureIntroSyncTitle,
                    selected: _open == _IntroFeature.sync,
                    iconColor: defaultTheme ? colors.muted : colors.accent,
                    highlight: rowHighlight,
                    onPressed: () => _select(_IntroFeature.sync),
                  ),
                  _FeatureRow(
                    asset: AppIcons.stars,
                    title: AppStrings.featureIntroAiTitle,
                    selected: _open == _IntroFeature.ai,
                    iconColor: defaultTheme ? colors.muted : colors.accent,
                    highlight: rowHighlight,
                    onPressed: () => _select(_IntroFeature.ai),
                  ),
                  _FeatureRow(
                    asset: AppIcons.addFriend,
                    title: AppStrings.featureIntroFriendsTitle,
                    selected: _open == _IntroFeature.friends,
                    iconColor: defaultTheme ? colors.muted : colors.accent,
                    highlight: rowHighlight,
                    onPressed: () => _select(_IntroFeature.friends),
                  ),
                  const SizedBox(height: 16),
                  PressBounce(
                    onPressed: widget.onLogin,
                    color: colors.tint(colors.accent, 0.16),
                    pressedColor: colors.tint(colors.accent, 0.26),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Text(
                        AppStrings.accountLogin,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on _IntroFeature {
  String get body => switch (this) {
    _IntroFeature.pc => AppStrings.featureIntroPcBody,
    _IntroFeature.sync => AppStrings.featureIntroSyncBody,
    _IntroFeature.ai => AppStrings.featureIntroAiBody,
    _IntroFeature.friends => AppStrings.featureIntroFriendsBody,
  };

  ReleaseDemo get demo => switch (this) {
    _IntroFeature.pc => ReleaseDemo.pcLaunch,
    _IntroFeature.sync => ReleaseDemo.accountSync,
    _IntroFeature.ai => ReleaseDemo.categoryAi,
    _IntroFeature.friends => ReleaseDemo.friendsMiniCal,
  };
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.asset,
    required this.title,
    required this.selected,
    required this.iconColor,
    required this.highlight,
    required this.onPressed,
  });

  final String asset;
  final String title;
  final bool selected;
  final Color iconColor;
  final Color highlight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PressBounce(
        onPressed: onPressed,
        pressedScale: 0.98,
        alignment: Alignment.centerLeft,
        color: selected ? highlight : Colors.transparent,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: AppAssetImage(
                    asset: asset,
                    width: 22,
                    height: 22,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
