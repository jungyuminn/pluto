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
  });

  final VoidCallback onVisibleItems;
  final VoidCallback onSortMode;
  final VoidCallback onEditCategories;

  @override
  Widget build(BuildContext context) {
    return _MenuCard(
      children: [
        _MenuItem(
          label: AppStrings.calendarVisibleItems,
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
          trailingAsset: AppIcons.categoryEdit,
          onPressed: onEditCategories,
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
    this.onBack,
  });

  final bool showTodos;
  final bool showCompanies;
  final ValueChanged<bool> onShowTodosChanged;
  final ValueChanged<bool> onShowCompaniesChanged;
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
        _FilterItem(
          label: AppStrings.calendarShowTodos,
          checked: showTodos,
          onChanged: onShowTodosChanged,
        ),
        _FilterItem(
          label: AppStrings.calendarShowCompanies,
          checked: showCompanies,
          onChanged: onShowCompaniesChanged,
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
    this.onBack,
  });

  final bool sortByTime;
  final bool showTime;
  final ValueChanged<bool> onSortByTimeChanged;
  final ValueChanged<bool> onShowTimeChanged;
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
        _FilterItem(
          label: AppStrings.timeSortView,
          checked: sortByTime,
          onChanged: onSortByTimeChanged,
        ),
        _FilterItem(
          label: AppStrings.timeDisplay,
          checked: showTime,
          onChanged: onShowTimeChanged,
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).card,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
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
                    fontFamily: AppFonts.pretendard,
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
                      AppColors.of(context).icon,
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
                    fontFamily: AppFonts.pretendard,
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
