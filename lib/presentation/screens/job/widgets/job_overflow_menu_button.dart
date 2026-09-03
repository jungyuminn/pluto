import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_filter_menu.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:pluto/presentation/widgets/app_bar_icon_group.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class JobOverflowMenuButton extends StatefulWidget {
  const JobOverflowMenuButton({
    super.key,
    required this.compact,
    required this.onCompactChanged,
    required this.showRejected,
    required this.onShowRejectedChanged,
    required this.sortByTime,
    required this.onSortByTimeChanged,
    required this.categoryView,
    required this.onCategoryViewChanged,
    required this.showLicense,
    required this.onShowLicenseChanged,
    required this.licenseCompact,
    required this.onLicenseCompactChanged,
    required this.showExpired,
    required this.onShowExpiredChanged,
    required this.licenseSortByTime,
    required this.onLicenseSortByTimeChanged,
    required this.licenseCategoryView,
    required this.onLicenseCategoryViewChanged,
    this.onCategoriesChanged,
  });

  final bool compact;
  final ValueChanged<bool> onCompactChanged;
  final bool showRejected;
  final ValueChanged<bool> onShowRejectedChanged;
  final bool sortByTime;
  final ValueChanged<bool> onSortByTimeChanged;
  final bool categoryView;
  final ValueChanged<bool> onCategoryViewChanged;
  final bool showLicense;
  final ValueChanged<bool> onShowLicenseChanged;
  final bool licenseCompact;
  final ValueChanged<bool> onLicenseCompactChanged;
  final bool showExpired;
  final ValueChanged<bool> onShowExpiredChanged;
  final bool licenseSortByTime;
  final ValueChanged<bool> onLicenseSortByTimeChanged;
  final bool licenseCategoryView;
  final ValueChanged<bool> onLicenseCategoryViewChanged;
  final VoidCallback? onCategoriesChanged;

  @override
  State<JobOverflowMenuButton> createState() => _JobOverflowMenuButtonState();
}

enum _MenuPage { root, visible, sort }

class _JobOverflowMenuButtonState extends State<JobOverflowMenuButton>
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
      kind: widget.showLicense ? CategoryKind.license : CategoryKind.company,
    );
    if (!mounted) return;
    widget.onCategoriesChanged?.call();
  }

  Widget _menuPage() {
    return switch (_page) {
      _MenuPage.visible => widget.showLicense
          ? LicenseVisibleItemsMenu(
              key: const ValueKey('license-visible'),
              compact: widget.licenseCompact,
              onCompactChanged: widget.onLicenseCompactChanged,
              showExpired: widget.showExpired,
              onShowExpiredChanged: widget.onShowExpiredChanged,
              onBack: () => setState(() => _page = _MenuPage.root),
            )
          : JobVisibleItemsMenu(
              key: const ValueKey('visible'),
              compact: widget.compact,
              onCompactChanged: widget.onCompactChanged,
              showRejected: widget.showRejected,
              onShowRejectedChanged: widget.onShowRejectedChanged,
              onBack: () => setState(() => _page = _MenuPage.root),
            ),
      _MenuPage.sort => CalendarSortMenu(
        key: ValueKey(widget.showLicense ? 'license-sort' : 'sort'),
        sortByTime: widget.showLicense
            ? widget.licenseSortByTime
            : widget.sortByTime,
        showTime: false,
        showTimeOption: false,
        onSortByTimeChanged: widget.showLicense
            ? widget.onLicenseSortByTimeChanged
            : widget.onSortByTimeChanged,
        onShowTimeChanged: (_) {},
        showCategoryOption: true,
        categoryView: widget.showLicense
            ? widget.licenseCategoryView
            : widget.categoryView,
        onCategoryViewChanged: widget.showLicense
            ? widget.onLicenseCategoryViewChanged
            : widget.onCategoryViewChanged,
        onBack: () => setState(() => _page = _MenuPage.root),
      ),
      _MenuPage.root => JobOverflowMenu(
        key: const ValueKey('root'),
        onVisibleItems: () => setState(() => _page = _MenuPage.visible),
        onSortMode: () => setState(() => _page = _MenuPage.sort),
        onEditCategories: _openCategories,
        showLicense: widget.showLicense,
        onShowLicenseChanged: widget.onShowLicenseChanged,
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
