import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class CalendarOverflowMenu extends StatelessWidget {
  const CalendarOverflowMenu({
    super.key,
    required this.onVisibleItems,
    required this.onSortMode,
    required this.onEditCategories,
    required this.showDiary,
    required this.onShowDiaryChanged,
    required this.showLedger,
    required this.onShowLedgerChanged,
  });

  final VoidCallback onVisibleItems;
  final VoidCallback onSortMode;
  final VoidCallback onEditCategories;
  final bool showDiary;
  final ValueChanged<bool> onShowDiaryChanged;
  final bool showLedger;
  final ValueChanged<bool> onShowLedgerChanged;

  @override
  Widget build(BuildContext context) {
    return _MenuCard(
      children: [
        _MenuReveal(
          visible: !showDiary,
          child: _MenuItem(
            label: AppStrings.calendarVisibleItems,
            trailingAsset: AppIcons.calendarList,
            onPressed: onVisibleItems,
          ),
        ),
        _MenuReveal(
          visible: !showDiary,
          child: _MenuItem(
            label: AppStrings.calendarSortMode,
            trailingAsset: AppIcons.calendarList,
            trailingQuarterTurns: 1,
            onPressed: onSortMode,
          ),
        ),
        _MenuItem(
          label: AppStrings.categoryEditTitle,
          trailingAsset: AppIcons.editOutlined,
          onPressed: onEditCategories,
        ),
        _FilterItem(
          label: AppStrings.calendarDiaryMode,
          checked: showDiary,
          onChanged: onShowDiaryChanged,
        ),
        _FilterItem(
          label: AppStrings.calendarLedgerMode,
          checked: showLedger,
          onChanged: onShowLedgerChanged,
        ),
      ],
    );
  }
}

class CalendarFilterMenu extends StatelessWidget {
  const CalendarFilterMenu({
    super.key,
    required this.showTodos,
    required this.showCompanies,
    required this.onShowTodosChanged,
    required this.onShowCompaniesChanged,
    this.showJobFilter = true,
    this.ledgerMode = false,
    this.showLedgerTitle = true,
    this.showLedgerAmount = false,
    this.showLedgerKind = true,
    this.showLedgerMonthStats = true,
    this.onShowLedgerTitleChanged,
    this.onShowLedgerAmountChanged,
    this.onShowLedgerKindChanged,
    this.onShowLedgerMonthStatsChanged,
    this.onBack,
  });

  final bool showTodos;
  final bool showCompanies;
  final bool showJobFilter;
  final ValueChanged<bool> onShowTodosChanged;
  final ValueChanged<bool> onShowCompaniesChanged;
  final bool ledgerMode;
  final bool showLedgerTitle;
  final bool showLedgerAmount;
  final bool showLedgerKind;
  final bool showLedgerMonthStats;
  final ValueChanged<bool>? onShowLedgerTitleChanged;
  final ValueChanged<bool>? onShowLedgerAmountChanged;
  final ValueChanged<bool>? onShowLedgerKindChanged;
  final ValueChanged<bool>? onShowLedgerMonthStatsChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return _MenuCard(
      children: [
        if (onBack != null)
          _MenuItem(
            label: AppStrings.calendarVisibleItems,
            leading: Icons.chevron_left_rounded,
            onPressed: onBack!,
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Column(
              key: ValueKey(ledgerMode),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: ledgerMode
                  ? [
                      _FilterItem(
                        label: AppStrings.calendarShowLedgerTitle,
                        checked: showLedgerTitle,
                        onChanged: onShowLedgerTitleChanged ?? (_) {},
                      ),
                      _FilterItem(
                        label: AppStrings.calendarShowLedgerAmount,
                        checked: showLedgerAmount,
                        onChanged: onShowLedgerAmountChanged ?? (_) {},
                      ),
                      _FilterItem(
                        label: AppStrings.calendarShowLedgerKind,
                        checked: showLedgerKind,
                        onChanged: onShowLedgerKindChanged ?? (_) {},
                      ),
                      _FilterItem(
                        label: AppStrings.calendarShowLedgerMonthStats,
                        checked: showLedgerMonthStats,
                        onChanged: onShowLedgerMonthStatsChanged ?? (_) {},
                      ),
                    ]
                  : [
                      _FilterItem(
                        label: AppStrings.calendarShowTodos,
                        checked: showTodos,
                        onChanged: onShowTodosChanged,
                      ),
                      if (showJobFilter)
                        _FilterItem(
                          label: AppStrings.calendarShowCompanies,
                          checked: showCompanies,
                          onChanged: onShowCompaniesChanged,
                        ),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

class CalendarSortMenu extends StatelessWidget {
  const CalendarSortMenu({
    super.key,
    required this.sortByTime,
    required this.showTime,
    required this.onSortByTimeChanged,
    required this.onShowTimeChanged,
    this.showTimeOption = true,
    this.showTimeSortOption = true,
    this.categoryView = false,
    this.onCategoryViewChanged,
    this.showCategoryOption = false,
    this.ledgerKindColor = false,
    this.onLedgerKindColorChanged,
    this.showLedgerKindColorOption = false,
    this.onBack,
  });

  final bool sortByTime;
  final bool showTime;
  final ValueChanged<bool> onSortByTimeChanged;
  final ValueChanged<bool> onShowTimeChanged;
  final bool showTimeOption;
  final bool showTimeSortOption;
  final bool categoryView;
  final ValueChanged<bool>? onCategoryViewChanged;
  final bool showCategoryOption;
  final bool ledgerKindColor;
  final ValueChanged<bool>? onLedgerKindColorChanged;
  final bool showLedgerKindColorOption;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return _MenuCard(
      children: [
        if (onBack != null)
          _MenuItem(
            label: AppStrings.calendarSortMode,
            leading: Icons.chevron_left_rounded,
            onPressed: onBack!,
          ),
        _MenuReveal(
          visible: showTimeSortOption,
          child: _FilterItem(
            label: AppStrings.timeSortView,
            checked: sortByTime,
            onChanged: onSortByTimeChanged,
          ),
        ),
        _MenuReveal(
          visible: showTimeOption,
          child: _FilterItem(
            label: AppStrings.timeDisplay,
            checked: showTime,
            onChanged: onShowTimeChanged,
          ),
        ),
        _MenuReveal(
          visible: showCategoryOption && onCategoryViewChanged != null,
          child: _FilterItem(
            label: AppStrings.categoryView,
            checked: categoryView,
            onChanged: onCategoryViewChanged ?? (_) {},
          ),
        ),
        _MenuReveal(
          visible: showLedgerKindColorOption &&
              onLedgerKindColorChanged != null,
          child: _FilterItem(
            label: AppStrings.ledgerKindColorView,
            checked: ledgerKindColor,
            onChanged: onLedgerKindColorChanged ?? (_) {},
          ),
        ),
      ],
    );
  }
}

class JobOverflowMenu extends StatelessWidget {
  const JobOverflowMenu({
    super.key,
    required this.onVisibleItems,
    required this.onSortMode,
    required this.onEditCategories,
  });

  final VoidCallback onVisibleItems;
  final VoidCallback onSortMode;
  final VoidCallback onEditCategories;

  @override
  Widget build(BuildContext context) {
    return _MenuCard(
      children: [
        _MenuItem(
          label: AppStrings.jobVisibleItems,
          trailingAsset: AppIcons.calendarList,
          onPressed: onVisibleItems,
        ),
        _MenuItem(
          label: AppStrings.calendarSortMode,
          trailingAsset: AppIcons.calendarList,
          trailingQuarterTurns: 1,
          onPressed: onSortMode,
        ),
        _MenuItem(
          label: AppStrings.categoryEditTitle,
          trailingAsset: AppIcons.editOutlined,
          onPressed: onEditCategories,
        ),
      ],
    );
  }
}

class JobVisibleItemsMenu extends StatelessWidget {
  const JobVisibleItemsMenu({
    super.key,
    required this.compact,
    required this.onCompactChanged,
    required this.showRejected,
    required this.onShowRejectedChanged,
    this.onBack,
  });

  final bool compact;
  final ValueChanged<bool> onCompactChanged;
  final bool showRejected;
  final ValueChanged<bool> onShowRejectedChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return _MenuCard(
      children: [
        if (onBack != null)
          _MenuItem(
            label: AppStrings.jobVisibleItems,
            leading: Icons.chevron_left_rounded,
            onPressed: onBack!,
          ),
        _FilterItem(
          label: AppStrings.compactView,
          checked: compact,
          onChanged: onCompactChanged,
        ),
        _FilterItem(
          label: AppStrings.jobShowRejected,
          checked: showRejected,
          onChanged: onShowRejectedChanged,
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

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

class _MenuReveal extends StatefulWidget {
  const _MenuReveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_MenuReveal> createState() => _MenuRevealState();
}

class _MenuRevealState extends State<_MenuReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
      value: widget.visible ? 1 : 0,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(_MenuReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _fade,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fade,
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailingAsset,
    this.trailingQuarterTurns = 0,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leading;
  final String? trailingAsset;
  final int trailingQuarterTurns;

  @override
  Widget build(BuildContext context) {
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
                Icon(leading, size: 22, color: AppColors.of(context).icon),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).text,
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
                    child: Image.asset(
                      trailingAsset!,
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

class _FilterItem extends StatelessWidget {
  const _FilterItem({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(!checked),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: CupertinoSwitch(
                  value: checked,
                  activeTrackColor: AppColors.of(context).accentBright,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
