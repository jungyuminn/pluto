import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

Future<DateTime?> showCalendarTimeMachineSheet(
  BuildContext context, {
  required DateTime month,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => CalendarTimeMachineSheet(month: month),
  );
}

class CalendarTimeMachineSheet extends StatefulWidget {
  const CalendarTimeMachineSheet({
    super.key,
    required this.month,
  });

  final DateTime month;

  @override
  State<CalendarTimeMachineSheet> createState() =>
      _CalendarTimeMachineSheetState();
}

class _CalendarTimeMachineSheetState extends State<CalendarTimeMachineSheet> {
  static const _minYear = 2010;
  static const _maxExtraYears = 5;

  late int _year;
  late int _month;

  int get _maxYear => DateTime.now().year + _maxExtraYears;

  int get _yearCount => _maxYear - _minYear + 1;

  @override
  void initState() {
    super.initState();
    _year = widget.month.year.clamp(_minYear, _maxYear);
    _month = widget.month.month.clamp(1, 12);
  }

  void _confirm([DateTime? value]) {
    final picked = value ?? DateTime(_year, _month);
    Navigator.of(context).pop(DateTime(picked.year, picked.month));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    PressBounce(
                      onPressed: () => _confirm(thisMonth),
                      pressedColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Text(
                          AppStrings.timeMachineNow,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.danger,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    PressBounce(
                      onPressed: _confirm,
                      pressedColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Text(
                          AppStrings.done,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.accentBright,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: _MonthWheel.extent * 5,
                  child: Row(
                    children: [
                      Expanded(
                        child: _MonthWheel(
                          itemCount: _yearCount,
                          initialIndex: _year - _minYear,
                          labelAt: (index) =>
                              '${_minYear + index}${AppStrings.yearSuffix}',
                          selectedColor: colors.accentBright,
                          onChanged: (index) => _year = _minYear + index,
                        ),
                      ),
                      Expanded(
                        child: _MonthWheel(
                          itemCount: 12,
                          initialIndex: _month - 1,
                          labelAt: (index) =>
                              '${index + 1}${AppStrings.monthSuffix}',
                          selectedColor: colors.accentBright,
                          onChanged: (index) => _month = index + 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthWheel extends StatefulWidget {
  const _MonthWheel({
    required this.itemCount,
    required this.initialIndex,
    required this.labelAt,
    required this.onChanged,
    required this.selectedColor,
  });

  static const extent = 40.0;

  final int itemCount;
  final int initialIndex;
  final String Function(int index) labelAt;
  final ValueChanged<int> onChanged;
  final Color selectedColor;

  @override
  State<_MonthWheel> createState() => _MonthWheelState();
}

class _MonthWheelState extends State<_MonthWheel> {
  late final FixedExtentScrollController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.itemCount - 1);
    _controller = FixedExtentScrollController(initialItem: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).muted;
    return Stack(
      children: [
        Center(
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.selectedColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  height: _MonthWheel.extent,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
        ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: _MonthWheel.extent,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 8,
          perspective: 0.0001,
          overAndUnderCenterOpacity: 1,
          onSelectedItemChanged: (index) {
            setState(() => _index = index);
            widget.onChanged(index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.itemCount,
            builder: (context, index) {
              final selected = index == _index;
              return Center(
                child: Text(
                  widget.labelAt(index),
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    color: selected ? widget.selectedColor : muted,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
