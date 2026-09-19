import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/widgets/app_bar_icon_group.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class OverflowMenuCard extends StatelessWidget {
  const OverflowMenuCard({super.key, required this.children});

  final List<Widget> children;

  static double _minWidthOf(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.of(context),
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    final label = [
      AppStrings.calendarVisibleItems,
      AppStrings.jobVisibleItems,
      AppStrings.licenseVisibleItems,
      AppStrings.searchVisibleItems,
    ].map(widthOf).reduce((a, b) => a > b ? a : b);
    return label + 74;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).card,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: _minWidthOf(context)),
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class OverflowMenuItem extends StatelessWidget {
  const OverflowMenuItem({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailingAsset,
    this.trailingQuarterTurns = 0,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leading;
  final String? trailingAsset;
  final int trailingQuarterTurns;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.of(context).text;
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.96,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              if (leading != null) ...[
                Icon(leading, size: 22, color: color ?? AppColors.of(context).icon),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: tint,
                  ),
                ),
              ),
              if (trailingAsset != null) ...[
                const SizedBox(width: 10),
                RotatedBox(
                  quarterTurns: trailingQuarterTurns,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      AppColors.light.icon,
                      BlendMode.srcIn,
                    ),
                    child: AppAssetImage(
                      asset: trailingAsset!,
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OverflowMenuAction {
  const OverflowMenuAction({
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;
}

class OverflowMenuButton extends StatefulWidget {
  const OverflowMenuButton({super.key, required this.actions});

  final List<OverflowMenuAction> actions;

  @override
  State<OverflowMenuButton> createState() => _OverflowMenuButtonState();
}

class _OverflowMenuButtonState extends State<OverflowMenuButton>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final AnimationController _animation;
  late final CurvedAnimation _fade;
  late final Animation<double> _scale;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _fade = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(_fade);
  }

  @override
  void dispose() {
    _fade.dispose();
    _animation.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_portal.isShowing) {
      await _close();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      _portal.show();
      _animation.forward(from: 0);
      setState(() {});
    }
  }

  Future<void> _close() async {
    if (!_portal.isShowing || _closing) return;
    _closing = true;
    await _animation.reverse();
    if (mounted) {
      _portal.hide();
      setState(() {});
    }
    _closing = false;
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _close,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 6),
                child: UnconstrainedBox(
                  alignment: Alignment.topRight,
                  clipBehavior: Clip.none,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      alignment: Alignment.topRight,
                      scale: _scale,
                      child: OverflowMenuCard(
                        children: [
                          for (final action in widget.actions)
                            OverflowMenuItem(
                              label: action.label,
                              color: action.color,
                              onPressed: () async {
                                await _close();
                                action.onPressed();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: AppBarIconSlot(
          selected: _portal.isShowing,
          onPressed: _toggle,
          child: AppAssetImage(
            asset: AppIcons.more,
            width: 19,
            height: 19,
            color: AppColors.of(context).muted,
          ),
        ),
      ),
    );
  }
}
