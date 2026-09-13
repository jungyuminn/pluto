import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/presentation/widgets/app_bar_icon_group.dart';
import 'package:pluto/presentation/widgets/overflow_menu.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

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
    return OverflowMenuCard(
      children: [
        _MenuReveal(
          visible: !showDiary,
          child: OverflowMenuItem(
            label: AppStrings.calendarVisibleItems,
            trailingAsset: AppIcons.calendarList,
            onPressed: onVisibleItems,
          ),
        ),
        _MenuReveal(
          visible: !showDiary,
          child: OverflowMenuItem(
            label: AppStrings.calendarSortMode,
            trailingAsset: AppIcons.calendarList,
            trailingQuarterTurns: 1,
            onPressed: onSortMode,
          ),
        ),
        OverflowMenuItem(
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
    return OverflowMenuCard(
      children: [
        if (onBack != null)
          OverflowMenuItem(
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
    return OverflowMenuCard(
      children: [
        if (onBack != null)
          OverflowMenuItem(
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
    required this.showLicense,
    required this.onShowLicenseChanged,
  });

  final VoidCallback onVisibleItems;
  final VoidCallback onSortMode;
  final VoidCallback onEditCategories;
  final bool showLicense;
  final ValueChanged<bool> onShowLicenseChanged;

  @override
  Widget build(BuildContext context) {
    return OverflowMenuCard(
      children: [
        OverflowMenuItem(
          label: showLicense
              ? AppStrings.licenseVisibleItems
              : AppStrings.jobVisibleItems,
          trailingAsset: AppIcons.calendarList,
          onPressed: onVisibleItems,
        ),
        OverflowMenuItem(
          label: AppStrings.calendarSortMode,
          trailingAsset: AppIcons.calendarList,
          trailingQuarterTurns: 1,
          onPressed: onSortMode,
        ),
        OverflowMenuItem(
          label: AppStrings.categoryEditTitle,
          trailingAsset: AppIcons.editOutlined,
          onPressed: onEditCategories,
        ),
        _FilterItem(
          label: AppStrings.licenseMode,
          checked: showLicense,
          onChanged: onShowLicenseChanged,
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
    return OverflowMenuCard(
      children: [
        if (onBack != null)
          OverflowMenuItem(
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

class LicenseVisibleItemsMenu extends StatelessWidget {
  const LicenseVisibleItemsMenu({
    super.key,
    required this.compact,
    required this.onCompactChanged,
    required this.showExpired,
    required this.onShowExpiredChanged,
    this.onBack,
  });

  final bool compact;
  final ValueChanged<bool> onCompactChanged;
  final bool showExpired;
  final ValueChanged<bool> onShowExpiredChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return OverflowMenuCard(
      children: [
        if (onBack != null)
          OverflowMenuItem(
            label: AppStrings.licenseVisibleItems,
            leading: Icons.chevron_left_rounded,
            onPressed: onBack!,
          ),
        _FilterItem(
          label: AppStrings.compactView,
          checked: compact,
          onChanged: onCompactChanged,
        ),
        _FilterItem(
          label: AppStrings.licenseShowExpired,
          checked: showExpired,
          onChanged: onShowExpiredChanged,
        ),
      ],
    );
  }
}

class AllEventsOverflowMenu extends StatelessWidget {
  const AllEventsOverflowMenu({
    super.key,
    required this.onPickRange,
    required this.onVisibleItems,
    required this.onSortMode,
  });

  final VoidCallback onPickRange;
  final VoidCallback onVisibleItems;
  final VoidCallback onSortMode;

  @override
  Widget build(BuildContext context) {
    return OverflowMenuCard(
      children: [
        OverflowMenuItem(
          label: AppStrings.searchVisibleItems,
          trailingAsset: AppIcons.calendarList,
          onPressed: onVisibleItems,
        ),
        OverflowMenuItem(
          label: AppStrings.calendarSortMode,
          trailingAsset: AppIcons.calendarList,
          trailingQuarterTurns: 1,
          onPressed: onSortMode,
        ),
        OverflowMenuItem(
          label: AppStrings.searchRangeSetting,
          trailingAsset: AppIcons.calendarOutlined,
          onPressed: onPickRange,
        ),
      ],
    );
  }
}

class AllEventsVisibleMenu extends StatelessWidget {
  const AllEventsVisibleMenu({
    super.key,
    required this.showTodos,
    required this.showJobs,
    required this.onShowTodosChanged,
    required this.onShowJobsChanged,
    this.showJobFilter = true,
    this.onBack,
  });

  final bool showTodos;
  final bool showJobs;
  final ValueChanged<bool> onShowTodosChanged;
  final ValueChanged<bool> onShowJobsChanged;
  final bool showJobFilter;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return OverflowMenuCard(
      children: [
        if (onBack != null)
          OverflowMenuItem(
            label: AppStrings.searchVisibleItems,
            leading: Icons.chevron_left_rounded,
            onPressed: onBack!,
          ),
        _FilterItem(
          label: AppStrings.calendarShowTodos,
          checked: showTodos,
          onChanged: onShowTodosChanged,
        ),
        if (showJobFilter)
          _FilterItem(
            label: AppStrings.calendarShowCompanies,
            checked: showJobs,
            onChanged: onShowJobsChanged,
          ),
      ],
    );
  }
}

class AllEventsSortMenu extends StatelessWidget {
  const AllEventsSortMenu({
    super.key,
    required this.newestFirst,
    required this.onNewestFirstChanged,
    required this.groupByDate,
    required this.onGroupByDateChanged,
    this.onBack,
  });

  final bool newestFirst;
  final ValueChanged<bool> onNewestFirstChanged;
  final bool groupByDate;
  final ValueChanged<bool> onGroupByDateChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return OverflowMenuCard(
      children: [
        if (onBack != null)
          OverflowMenuItem(
            label: AppStrings.calendarSortMode,
            leading: Icons.chevron_left_rounded,
            onPressed: onBack!,
          ),
        _FilterItem(
          label: AppStrings.categoryView,
          checked: !groupByDate,
          onChanged: (value) => onGroupByDateChanged(!value),
        ),
        _FilterItem(
          label: AppStrings.searchDateView,
          checked: groupByDate,
          onChanged: (value) => onGroupByDateChanged(value),
        ),
        _FilterItem(
          label: AppStrings.searchSortOldest,
          checked: !newestFirst,
          onChanged: (value) => onNewestFirstChanged(!value),
        ),
      ],
    );
  }
}

enum _AllEventsMenuPage { root, visible, sort }

class AllEventsFilterMenuButton extends StatefulWidget {
  const AllEventsFilterMenuButton({
    super.key,
    required this.filterTodos,
    required this.filterJobs,
    required this.showJobFilter,
    required this.onFilterTodosChanged,
    required this.onFilterJobsChanged,
    required this.newestFirst,
    required this.onNewestFirstChanged,
    required this.groupByDate,
    required this.onGroupByDateChanged,
    required this.onPickRange,
  });

  final bool filterTodos;
  final bool filterJobs;
  final bool showJobFilter;
  final ValueChanged<bool> onFilterTodosChanged;
  final ValueChanged<bool> onFilterJobsChanged;
  final bool newestFirst;
  final ValueChanged<bool> onNewestFirstChanged;
  final bool groupByDate;
  final ValueChanged<bool> onGroupByDateChanged;
  final Future<void> Function() onPickRange;

  @override
  State<AllEventsFilterMenuButton> createState() =>
      _AllEventsFilterMenuButtonState();
}

class _AllEventsFilterMenuButtonState extends State<AllEventsFilterMenuButton>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final AnimationController _animation;
  late final CurvedAnimation _fade;
  late final Animation<double> _scale;
  var _closing = false;
  var _page = _AllEventsMenuPage.root;

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
      _page = _AllEventsMenuPage.root;
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
      _page = _AllEventsMenuPage.root;
      setState(() {});
    }
    _closing = false;
  }

  Future<void> _pickRange() async {
    await _close();
    if (!mounted) return;
    await widget.onPickRange();
  }

  Widget _menuPage() {
    return switch (_page) {
      _AllEventsMenuPage.visible => AllEventsVisibleMenu(
        key: const ValueKey('visible'),
        showTodos: widget.filterTodos,
        showJobs: widget.filterJobs,
        showJobFilter: widget.showJobFilter,
        onShowTodosChanged: (value) {
          widget.onFilterTodosChanged(value);
          setState(() {});
        },
        onShowJobsChanged: (value) {
          widget.onFilterJobsChanged(value);
          setState(() {});
        },
        onBack: () => setState(() => _page = _AllEventsMenuPage.root),
      ),
      _AllEventsMenuPage.sort => AllEventsSortMenu(
        key: const ValueKey('sort'),
        newestFirst: widget.newestFirst,
        onNewestFirstChanged: (value) {
          widget.onNewestFirstChanged(value);
          setState(() {});
        },
        groupByDate: widget.groupByDate,
        onGroupByDateChanged: (value) {
          widget.onGroupByDateChanged(value);
          setState(() {});
        },
        onBack: () => setState(() => _page = _AllEventsMenuPage.root),
      ),
      _AllEventsMenuPage.root => AllEventsOverflowMenu(
        key: const ValueKey('root'),
        onPickRange: _pickRange,
        onVisibleItems: () => setState(() => _page = _AllEventsMenuPage.visible),
        onSortMode: () => setState(() => _page = _AllEventsMenuPage.sort),
      ),
    };
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
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topRight,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          layoutBuilder: (current, previous) {
                            return Stack(
                              alignment: Alignment.topRight,
                              clipBehavior: Clip.none,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            final submenu = child.key != const ValueKey('root');
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(submenu ? 0.14 : -0.14, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _menuPage(),
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
        child: AppBarIconSlot(
          selected: _portal.isShowing,
          onPressed: _toggle,
          child: ThemedAsset(
            asset: AppIcons.more,
            width: 18,
            height: 18,
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
