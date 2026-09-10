import 'package:flutter/material.dart';
import 'package:pluto/core/calendar/repeat_dates.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/widgets/sliding_kind_bar.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class AppCalendarRepeatPanel extends StatelessWidget {
  const AppCalendarRepeatPanel({
    super.key,
    required this.kind,
    required this.weekdays,
    required this.start,
    required this.end,
    required this.accent,
    this.startMonday = false,
    this.monthRule = RepeatMonthRule.date,
    this.monthWeek = RepeatMonthWeek.first,
    this.monthWeekday = 0,
    required this.onKindChanged,
    required this.onWeekdayPressed,
    required this.onMonthRuleChanged,
    required this.onMonthWeekChanged,
    required this.onMonthWeekdayChanged,
    required this.onStartPressed,
    required this.onEndChanged,
  });

  final RepeatKind kind;
  final Set<int> weekdays;
  final DateTime start;
  final DateTime? end;
  final Color accent;
  final bool startMonday;
  final RepeatMonthRule monthRule;
  final RepeatMonthWeek monthWeek;
  final int monthWeekday;
  final ValueChanged<RepeatKind> onKindChanged;
  final ValueChanged<int> onWeekdayPressed;
  final ValueChanged<RepeatMonthRule> onMonthRuleChanged;
  final ValueChanged<RepeatMonthWeek> onMonthWeekChanged;
  final ValueChanged<int> onMonthWeekdayChanged;
  final VoidCallback onStartPressed;
  final ValueChanged<DateTime?> onEndChanged;

  static const _kindLabels = {
    RepeatKind.weekly: AppStrings.repeatKindWeekly,
    RepeatKind.monthly: AppStrings.repeatKindMonthly,
    RepeatKind.yearly: AppStrings.repeatKindYearly,
  };

  static String _weekLabel(RepeatMonthWeek week) {
    return switch (week) {
      RepeatMonthWeek.first => AppStrings.ledgerPayWeekFirst,
      RepeatMonthWeek.second => AppStrings.ledgerPayWeekSecond,
      RepeatMonthWeek.third => AppStrings.ledgerPayWeekThird,
      RepeatMonthWeek.fourth => AppStrings.ledgerPayWeekFourth,
      RepeatMonthWeek.last => AppStrings.ledgerPayWeekLast,
    };
  }

  @override
  Widget build(BuildContext context) {
    final endOptions = RepeatDates.endOptions(
      kind: kind,
      start: start,
      monthRule: monthRule,
      monthWeek: monthWeek,
      monthWeekday: monthWeekday,
    );
    final highlight = AppColors.of(context).tint(accent, 0.14);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChevronMenu<RepeatKind>(
              label: _kindLabels[kind]!,
              compact: true,
              items: [
                for (final item in RepeatKind.values)
                  (item, _kindLabels[item]!),
              ],
              onSelected: onKindChanged,
              child: _RepeatRow(
                icon: Icons.repeat_rounded,
                label: AppStrings.repeatTypeLabel,
                child: _ChevronLabel(label: _kindLabels[kind]!),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: kind == RepeatKind.weekly
                  ? _WeekdayRow(
                      selected: weekdays,
                      startMonday: startMonday,
                      selectedColor: highlight,
                      onPressed: onWeekdayPressed,
                    )
                  : kind == RepeatKind.monthly
                      ? _MonthlyRule(
                          accent: highlight,
                          startMonday: startMonday,
                          monthRule: monthRule,
                          monthWeek: monthWeek,
                          monthWeekday: monthWeekday,
                          weekLabel: _weekLabel,
                          onRuleChanged: onMonthRuleChanged,
                          onWeekChanged: onMonthWeekChanged,
                          onWeekdayChanged: onMonthWeekdayChanged,
                        )
                      : const SizedBox(width: double.infinity),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: kind == RepeatKind.monthly &&
                      monthRule == RepeatMonthRule.weekday
                  ? const SizedBox(width: double.infinity)
                  : _RepeatRow(
                      iconAsset: AppIcons.calendar,
                      label: AppStrings.repeatStartLabel,
                      child: _ChevronButton(
                        label: RepeatDates.format(start),
                        onPressed: onStartPressed,
                      ),
                    ),
            ),
            _RepeatRow(
              iconAsset: AppIcons.calendar,
              label: AppStrings.repeatEndLabel,
              child: _ChevronMenu<DateTime?>(
                label: end == null
                    ? AppStrings.repeatEndNone
                    : RepeatDates.format(end!),
                items: [
                  (null, AppStrings.repeatEndNone),
                  for (final date in endOptions) (date, RepeatDates.format(date)),
                ],
                onSelected: onEndChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyRule extends StatelessWidget {
  const _MonthlyRule({
    required this.accent,
    required this.startMonday,
    required this.monthRule,
    required this.monthWeek,
    required this.monthWeekday,
    required this.weekLabel,
    required this.onRuleChanged,
    required this.onWeekChanged,
    required this.onWeekdayChanged,
  });

  final Color accent;
  final bool startMonday;
  final RepeatMonthRule monthRule;
  final RepeatMonthWeek monthWeek;
  final int monthWeekday;
  final String Function(RepeatMonthWeek week) weekLabel;
  final ValueChanged<RepeatMonthRule> onRuleChanged;
  final ValueChanged<RepeatMonthWeek> onWeekChanged;
  final ValueChanged<int> onWeekdayChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        children: [
          SlidingKindBar(
            values: RepeatMonthRule.values,
            selected: monthRule,
            height: 36,
            accent: accent,
            barColor: colors.pressed,
            labelOf: (rule) => rule == RepeatMonthRule.date
                ? AppStrings.repeatMonthByDate
                : AppStrings.repeatMonthByWeekday,
            onChanged: onRuleChanged,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: monthRule == RepeatMonthRule.weekday
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        SlidingKindBar(
                          values: RepeatMonthWeek.values,
                          selected: monthWeek,
                          height: 36,
                          accent: accent,
                          barColor: colors.pressed,
                          labelOf: weekLabel,
                          onChanged: onWeekChanged,
                        ),
                        _WeekdayRow(
                          selected: {monthWeekday},
                          startMonday: startMonday,
                          padding: const EdgeInsets.only(top: 2),
                          selectedColor: accent,
                          onPressed: onWeekdayChanged,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _RepeatRow extends StatelessWidget {
  const _RepeatRow({
    this.icon,
    this.iconAsset,
    required this.label,
    required this.child,
  });

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: iconAsset != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      colors.icon,
                      BlendMode.srcIn,
                    ),
                    child: AppAssetImage(
                      asset: iconAsset!,
                      width: 20,
                      height: 20,
                    ),
                  )
                : Icon(icon, size: 22, color: colors.icon),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({
    required this.selected,
    required this.onPressed,
    this.startMonday = false,
    this.padding = const EdgeInsets.only(bottom: 12, top: 8),
    this.selectedColor,
  });

  final Set<int> selected;
  final ValueChanged<int> onPressed;
  final bool startMonday;
  final EdgeInsetsGeometry padding;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final highlight = selectedColor ?? colors.text;
    final onHighlight = highlight.computeLuminance() > 0.45
        ? colors.text
        : Colors.white;
    final order = startMonday
        ? const [1, 2, 3, 4, 5, 6, 0]
        : const [0, 1, 2, 3, 4, 5, 6];
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final i in order)
            Expanded(
              child: PressBounce(
                onPressed: () => onPressed(i),
                pressedScale: 0.92,
                color: Colors.transparent,
                pressedColor: Colors.transparent,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected.contains(i)
                          ? highlight
                          : Colors.transparent,
                    ),
                    child: Text(
                      AppStrings.weekdays[i],
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected.contains(i)
                            ? onHighlight
                            : colors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChevronLabel extends StatelessWidget {
  const _ChevronLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 22,
          color: colors.muted,
        ),
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.97,
      color: Colors.transparent,
      pressedColor: Colors.transparent,
      child: _ChevronLabel(label: label),
    );
  }
}

class _ChevronMenu<T> extends StatefulWidget {
  const _ChevronMenu({
    required this.label,
    required this.items,
    required this.onSelected,
    this.child,
    this.compact = false,
  });

  final String label;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;
  final Widget? child;
  final bool compact;

  @override
  State<_ChevronMenu<T>> createState() => _ChevronMenuState<T>();
}

class _ChevronMenuState<T> extends State<_ChevronMenu<T>>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final AnimationController _animation;
  late final CurvedAnimation _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _fade = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _scale = Tween<double>(begin: 0.86, end: 1).animate(_fade);
    _slide = Tween<Offset>(
      begin: const Offset(0.12, 0.18),
      end: Offset.zero,
    ).animate(_fade);
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
      _portal.show();
      _animation.forward(from: 0);
    }
  }

  Future<void> _close() async {
    if (!_portal.isShowing || _closing) return;
    _closing = true;
    await _animation.reverse();
    if (mounted) _portal.hide();
    _closing = false;
  }

  Future<void> _select(T value) async {
    widget.onSelected(value);
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return SizedBox.expand(
          child: Stack(
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
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.bottomRight,
                offset: const Offset(0, -6),
                child: UnconstrainedBox(
                  alignment: Alignment.bottomRight,
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: ScaleTransition(
                        alignment: Alignment.bottomRight,
                        scale: _scale,
                        child: Material(
                          color: AppColors.of(context).card,
                          elevation: 8,
                          shadowColor: const Color(0x33000000),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: widget.compact ? 148 : 240,
                              minWidth: widget.compact ? 124 : 148,
                              maxWidth: widget.compact ? 148 : 200,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              shrinkWrap: true,
                              itemCount: widget.items.length,
                              itemBuilder: (context, index) {
                                final item = widget.items[index];
                                final colors = AppColors.of(context);
                                return PressBounce(
                                  onPressed: () => _select(item.$1),
                                  pressedScale: 0.98,
                                  pressedColor: colors.pressed,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      item.$2,
                                      style: TextStyle(
                                        fontFamily: AppFonts.of(context),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: colors.text,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
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
        child: PressBounce(
          onPressed: _toggle,
          pressedScale: 0.99,
          color: Colors.transparent,
          pressedColor: AppColors.of(context).pressed,
          borderRadius: BorderRadius.circular(12),
          child: widget.child ?? _ChevronLabel(label: widget.label),
        ),
      ),
    );
  }
}
