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
    return label + 90;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).card,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(32),
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
    this.leadingAsset,
    this.leadingFlipX = false,
    this.trailingAsset,
    this.trailingQuarterTurns = 0,
    this.value,
    this.onChanged,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leading;
  final String? leadingAsset;
  final bool leadingFlipX;
  final String? trailingAsset;
  final int trailingQuarterTurns;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.of(context).text;
    final colors = AppColors.of(context);
    final toggle = value;
    final row = SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, size: 22, color: color ?? colors.icon),
              const SizedBox(width: 10),
            ],
            if (leadingAsset != null) ...[
              Transform.flip(
                flipX: leadingFlipX,
                child: AppAssetImage(
                  asset: leadingAsset!,
                  width: 22,
                  height: 22,
                  color: color ?? colors.icon,
                ),
              ),
              const SizedBox(width: 10),
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
            if (toggle != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 22,
                height: 22,
                child: toggle
                    ? Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: colors.icon,
                      )
                    : null,
              ),
            ],
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
    );
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.96,
      borderRadius: BorderRadius.circular(14),
      child: row,
    );
  }
}

class OverflowMenuAction {
  const OverflowMenuAction({
    required this.label,
    this.onPressed,
    this.value,
    this.onChanged,
    this.leadingAsset,
    this.leadingFlipX = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String? leadingAsset;
  final bool leadingFlipX;
  final Color? color;

  bool get isToggle => onChanged != null && value != null;
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
  final _targetKey = GlobalKey();
  final _portal = OverlayPortalController();
  late final AnimationController _animation;
  late final CurvedAnimation _fade;
  late final Animation<double> _scale;
  var _closing = false;
  var _openUp = false;

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

  double _menuHeight() => 16 + widget.actions.length * 50;

  bool _shouldOpenUp() {
    final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || overlay == null || !overlay.hasSize) {
      return false;
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    const gap = 6.0;
    final needed = _menuHeight() + 8;
    final spaceBelow = overlay.size.height - topLeft.dy - box.size.height - gap;
    if (spaceBelow >= needed) return false;
    final spaceAbove = topLeft.dy - gap;
    return spaceAbove > spaceBelow;
  }

  Future<void> _toggle() async {
    if (_portal.isShowing) {
      await _close();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      _openUp = _shouldOpenUp();
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
                targetAnchor:
                    _openUp ? Alignment.topRight : Alignment.bottomRight,
                followerAnchor:
                    _openUp ? Alignment.bottomRight : Alignment.topRight,
                offset: Offset(0, _openUp ? -6 : 6),
                child: UnconstrainedBox(
                  alignment: _openUp ? Alignment.bottomRight : Alignment.topRight,
                  clipBehavior: Clip.none,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      alignment:
                          _openUp ? Alignment.bottomRight : Alignment.topRight,
                      scale: _scale,
                      child: OverflowMenuCard(
                        children: [
                          for (final action in widget.actions)
                            OverflowMenuItem(
                              label: action.label,
                              color: action.color,
                              leadingAsset: action.leadingAsset,
                              leadingFlipX: action.leadingFlipX,
                              value: action.value,
                              onChanged: action.onChanged,
                              onPressed: () async {
                                if (action.isToggle) {
                                  action.onChanged!(!action.value!);
                                  return;
                                }
                                await _close();
                                action.onPressed?.call();
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
        key: _targetKey,
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
