import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_filter_menu.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/category_picker_sheet.dart';

class CalendarMonthHeader extends StatelessWidget {
  const CalendarMonthHeader({
    super.key,
    required this.month,
    this.onTitlePressed,
    this.showTodos = true,
    this.showCompanies = true,
    this.onShowTodosChanged,
    this.onShowCompaniesChanged,
    this.onSortPrefsChanged,
  });

  final DateTime month;
  final VoidCallback? onTitlePressed;
  final bool showTodos;
  final bool showCompanies;
  final ValueChanged<bool>? onShowTodosChanged;
  final ValueChanged<bool>? onShowCompaniesChanged;
  final VoidCallback? onSortPrefsChanged;

  String get _title {
    final monthLabel = '${month.month}${AppStrings.monthSuffix}';
    if (month.year == DateTime.now().year) return monthLabel;
    return '${month.year}${AppStrings.yearSuffix} $monthLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: PressBounce(
                onPressed: onTitlePressed ?? () {},
                pressedScale: 0.97,
                child: Text(
                  _title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
          CalendarMonthMenuButton(
            showTodos: showTodos,
            showCompanies: showCompanies,
            onShowTodosChanged: onShowTodosChanged,
            onShowCompaniesChanged: onShowCompaniesChanged,
            onSortPrefsChanged: onSortPrefsChanged,
          ),
        ],
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
    this.onShowTodosChanged,
    this.onShowCompaniesChanged,
    this.onSortPrefsChanged,
  });

  final bool showTodos;
  final bool showCompanies;
  final ValueChanged<bool>? onShowTodosChanged;
  final ValueChanged<bool>? onShowCompaniesChanged;
  final VoidCallback? onSortPrefsChanged;

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
    await showCategoryPickerSheet(context, startModifying: true);
  }

  Widget _menuPage() {
    final prefs = AppScope.of(context).dayEventsViewPreference;
    return switch (_page) {
      _MenuPage.filter => CalendarFilterMenu(
          key: const ValueKey('filter'),
          showTodos: widget.showTodos,
          showCompanies: widget.showCompanies,
          onShowTodosChanged: (value) {
            widget.onShowTodosChanged?.call(value);
          },
          onShowCompaniesChanged: (value) {
            widget.onShowCompaniesChanged?.call(value);
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
          onBack: () => setState(() => _page = _MenuPage.root),
        ),
      _MenuPage.root => CalendarOverflowMenu(
          key: const ValueKey('root'),
          onVisibleItems: () => setState(() => _page = _MenuPage.filter),
          onSortMode: () => setState(() => _page = _MenuPage.sort),
          onEditCategories: _openCategories,
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
                            final submenu =
                                child.key != const ValueKey('root');
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
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: PressBounce(
            onPressed: _toggle,
            color: _portal.isShowing ? const Color(0xFFF1F5F9) : Colors.white,
            pressedColor: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(999),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  Icons.more_horiz,
                  size: 22,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
