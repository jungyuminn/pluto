import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/ledger_month_stats.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_filter_menu.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/ledger_kind_stats.dart';
import 'package:pluto/presentation/tutorial/tutorial_anchor.dart';
import 'package:pluto/presentation/widgets/app_bar_icon_group.dart';
import 'package:pluto/presentation/widgets/app_calendar/calendar_zoom_picker.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class CalendarMonthHeader extends StatelessWidget {
  const CalendarMonthHeader({
    super.key,
    required this.month,
    this.title,
    this.onTitlePressed,
    this.showTodos = true,
    this.showCompanies = true,
    this.showJobFilter = true,
    this.showDiary = false,
    this.showLedger = false,
    this.onShowTodosChanged,
    this.onShowCompaniesChanged,
    this.onShowDiaryChanged,
    this.onShowLedgerChanged,
    this.onSortPrefsChanged,
    this.onCategoriesChanged,
    this.searchOpen = false,
    this.onSearchPressed,
    this.ledgerMonthStats,
    this.onLedgerStatsPressed,
    this.tutorial = true,
  });

  final DateTime month;
  final String? title;
  final VoidCallback? onTitlePressed;
  final bool showTodos;
  final bool showCompanies;
  final bool showJobFilter;
  final bool showDiary;
  final bool showLedger;
  final ValueChanged<bool>? onShowTodosChanged;
  final ValueChanged<bool>? onShowCompaniesChanged;
  final ValueChanged<bool>? onShowDiaryChanged;
  final ValueChanged<bool>? onShowLedgerChanged;
  final VoidCallback? onSortPrefsChanged;
  final VoidCallback? onCategoriesChanged;
  final bool searchOpen;
  final VoidCallback? onSearchPressed;
  final LedgerMonthStats? ledgerMonthStats;
  final VoidCallback? onLedgerStatsPressed;
  final bool tutorial;

  String get _title {
    if (title != null) return title!;
    final monthLabel = '${month.month}${AppStrings.monthSuffix}';
    if (month.year == DateTime.now().year) return monthLabel;
    return '${month.year}${AppStrings.yearSuffix} $monthLabel';
  }

  @override
  Widget build(BuildContext context) {
    final stats = ledgerMonthStats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _maybeAnchor(
                  TutorialAnchorId.calendarTitle,
                  CalendarZoomTitle(
                    text: _title,
                    onPressed: onTitlePressed,
                    fontSize: 32,
                  ),
                ),
                Flexible(
                  child: _LedgerMonthNet(
                    stats: stats,
                    onPressed: onLedgerStatsPressed,
                  ),
                ),
              ],
            ),
          ),
          _maybeAnchor(
            TutorialAnchorId.calendarMenu,
            AppBarIconGroup(
              actions: [
                if (onSearchPressed != null)
                  AppBarIconAction(
                    asset: AppIcons.search,
                    label: AppStrings.calendarSearchLabel,
                    selected: searchOpen,
                    onPressed: onSearchPressed!,
                  ),
              ],
              trailing: [
                CalendarMonthMenuButton(
                  showTodos: showTodos,
                  showCompanies: showCompanies,
                  showJobFilter: showJobFilter,
                  showDiary: showDiary,
                  showLedger: showLedger,
                  onShowTodosChanged: onShowTodosChanged,
                  onShowCompaniesChanged: onShowCompaniesChanged,
                  onShowDiaryChanged: onShowDiaryChanged,
                  onShowLedgerChanged: onShowLedgerChanged,
                  onSortPrefsChanged: onSortPrefsChanged,
                  onCategoriesChanged: onCategoriesChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _maybeAnchor(TutorialAnchorId id, Widget child) {
    if (!tutorial) return child;
    return TutorialAnchor(id: id, child: child);
  }
}

class _LedgerMonthNet extends StatefulWidget {
  const _LedgerMonthNet({
    required this.stats,
    this.onPressed,
  });

  final LedgerMonthStats? stats;
  final VoidCallback? onPressed;

  @override
  State<_LedgerMonthNet> createState() => _LedgerMonthNetState();
}

class _LedgerMonthNetState extends State<_LedgerMonthNet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;
  LedgerMonthStats? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.stats;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      value: widget.stats == null ? 0 : 1,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(_LedgerMonthNet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final visible = widget.stats != null;
    final wasVisible = oldWidget.stats != null;
    if (widget.stats != null) _shown = widget.stats;
    if (visible == wasVisible) return;
    if (visible) {
      _controller.forward();
    } else {
      _controller.reverse().whenComplete(() {
        if (!mounted || widget.stats != null) return;
        setState(() => _shown = null);
      });
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
    final stats = widget.stats ?? _shown;
    if (stats == null) return const SizedBox.shrink();
    final colors = AppColors.of(context);
    return FadeTransition(
      opacity: _fade,
      child: IgnorePointer(
        ignoring: widget.stats == null,
        child: PressBounce(
          onPressed: widget.onPressed,
          pressedScale: 0.97,
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: LedgerStatAmount(
              amount: stats.net,
              sign: LedgerSignMode.signed,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: LedgerEntry.netColor(stats.net, colors.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MenuPage { root, filter, sort }

class CalendarMonthMenuButton extends StatefulWidget {
  const CalendarMonthMenuButton({
    super.key,
    required this.showTodos,
    required this.showCompanies,
    this.showJobFilter = true,
    required this.showDiary,
    this.onShowTodosChanged,
    this.onShowCompaniesChanged,
    this.onShowDiaryChanged,
    this.onShowLedgerChanged,
    this.showLedger = false,
    this.onSortPrefsChanged,
    this.onCategoriesChanged,
  });

  final bool showTodos;
  final bool showCompanies;
  final bool showJobFilter;
  final bool showDiary;
  final bool showLedger;
  final ValueChanged<bool>? onShowTodosChanged;
  final ValueChanged<bool>? onShowCompaniesChanged;
  final ValueChanged<bool>? onShowDiaryChanged;
  final ValueChanged<bool>? onShowLedgerChanged;
  final VoidCallback? onSortPrefsChanged;
  final VoidCallback? onCategoriesChanged;

  @override
  State<CalendarMonthMenuButton> createState() =>
      _CalendarMonthMenuButtonState();
}

class _CalendarMonthMenuButtonState extends State<CalendarMonthMenuButton>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final AnimationController _animation;
  late final CurvedAnimation _fade;
  late final Animation<double> _scale;
  var _closing = false;
  var _page = _MenuPage.root;

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
      _portal.show();
      _page = _MenuPage.root;
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
      _page = _MenuPage.root;
      setState(() {});
    }
    _closing = false;
  }

  Future<void> _openCategories() async {
    await _close();
    if (!mounted) return;
    await showCategoryPickerSheet(
      context,
      selectable: false,
      kind: widget.showLedger ? CategoryKind.ledger : CategoryKind.event,
    );
    if (!mounted) return;
    widget.onCategoriesChanged?.call();
  }

  Widget _menuPage() {
    final prefs = AppScope.of(context).dayEventsViewPreference;
    final ledger = widget.showLedger;
    return switch (_page) {
      _MenuPage.filter => CalendarFilterMenu(
        key: const ValueKey('filter'),
        showTodos: widget.showTodos,
        showCompanies: widget.showCompanies,
        showJobFilter: widget.showJobFilter,
        onShowTodosChanged: (value) {
          widget.onShowTodosChanged?.call(value);
          if (mounted) setState(() {});
        },
        onShowCompaniesChanged: (value) {
          widget.onShowCompaniesChanged?.call(value);
          if (mounted) setState(() {});
        },
        ledgerMode: ledger,
        showLedgerTitle: prefs.showLedgerTitle,
        showLedgerAmount: prefs.showLedgerAmount,
        showLedgerKind: prefs.showLedgerKind,
        showLedgerMonthStats: prefs.showLedgerMonthStats,
        onShowLedgerTitleChanged: (value) async {
          await prefs.setShowLedgerTitle(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        onShowLedgerAmountChanged: (value) async {
          await prefs.setShowLedgerAmount(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        onShowLedgerKindChanged: (value) async {
          await prefs.setShowLedgerKind(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        onShowLedgerMonthStatsChanged: (value) async {
          await prefs.setShowLedgerMonthStats(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        onBack: () => setState(() => _page = _MenuPage.root),
      ),
      _MenuPage.sort => CalendarSortMenu(
        key: const ValueKey('sort'),
        sortByTime: prefs.sortByTime,
        showTime: prefs.showTime,
        onSortByTimeChanged: (value) async {
          await prefs.setSortByTime(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        onShowTimeChanged: (value) async {
          await prefs.setShowTime(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        hour24: prefs.hour24,
        onHour24Changed: (value) async {
          await prefs.setHour24(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        showTimeOption: !ledger,
        showTimeSortOption: !ledger,
        showCategoryOption: true,
        categoryView: prefs.categoryView,
        onCategoryViewChanged: (value) async {
          await prefs.setCategoryView(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        showLedgerKindColorOption: ledger,
        ledgerKindColor: prefs.ledgerKindColor,
        onLedgerKindColorChanged: (value) async {
          await prefs.setLedgerKindColor(value);
          if (mounted) setState(() {});
          widget.onSortPrefsChanged?.call();
        },
        onBack: () => setState(() => _page = _MenuPage.root),
      ),
      _MenuPage.root => CalendarOverflowMenu(
        key: const ValueKey('root'),
        onVisibleItems: () => setState(() => _page = _MenuPage.filter),
        onSortMode: () => setState(() => _page = _MenuPage.sort),
        onEditCategories: _openCategories,
        showDiary: widget.showDiary,
        onShowDiaryChanged: (value) {
          widget.onShowDiaryChanged?.call(value);
          setState(() {});
        },
        showLedger: ledger,
        onShowLedgerChanged: (value) {
          widget.onShowLedgerChanged?.call(value);
          setState(() {});
        },
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
            width: 19,
            height: 19,
          ),
        ),
      ),
    );
  }
}
