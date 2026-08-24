import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/calendar/calendar_years.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/device_calendar_mapper.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_category_chip.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

class CalendarImportPick {
  const CalendarImportPick({
    required this.calendars,
    required this.from,
    required this.to,
  });

  final List<DeviceCalendarInfo> calendars;
  final DateTime from;
  final DateTime to;
}

Future<CalendarImportPick?> showCalendarPickDialog(
  BuildContext context,
  List<DeviceCalendarInfo> calendars,
) {
  return showDialog<CalendarImportPick>(
    context: context,
    builder: (context) => CalendarPickDialog(calendars: calendars),
  );
}

class CalendarPickDialog extends StatefulWidget {
  const CalendarPickDialog({super.key, required this.calendars});

  final List<DeviceCalendarInfo> calendars;

  @override
  State<CalendarPickDialog> createState() => _CalendarPickDialogState();
}

class _CalendarPickDialogState extends State<CalendarPickDialog> {
  late final Set<String> _selected = {
    for (final calendar in widget.calendars) calendar.id,
  };
  late DateTime _from = CalendarYears.start();
  late DateTime _to = DateTime(CalendarYears.max(), 12, 31);

  bool get _isFullRange {
    final start = CalendarYears.start();
    final end = DateTime(CalendarYears.max(), 12, 31);
    return _from.year == start.year &&
        _from.month == start.month &&
        _from.day == start.day &&
        _to.year == end.year &&
        _to.month == end.month &&
        _to.day == end.day;
  }

  Future<void> _pickRange() async {
    final picked = await showAppCalendarSheet(
      context,
      date: DateTime.now(),
      dates: [_from, _to],
      mode: AppCalendarMode.range,
      showModes: false,
    );
    if (picked == null || picked.dates.isEmpty || !mounted) return;
    final first = picked.dates.first;
    final last = picked.dates.length > 1 ? picked.dates.last : first;
    final origin = DateTime.now();
    var from = DateTime(first.year, first.month, first.day);
    var to = DateTime(last.year, last.month, last.day);
    final min = CalendarYears.start();
    final max = DateTime(CalendarYears.max(origin), 12, 31);
    if (from.isBefore(min)) from = min;
    if (to.isAfter(max)) to = max;
    if (to.isBefore(from)) {
      final swap = from;
      from = to;
      to = swap;
    }
    setState(() {
      _from = from;
      _to = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final canImport = _selected.isNotEmpty;
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.importCalendarsTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.importCalendarsBody,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            _ImportRangeTile(
              label: _isFullRange
                  ? AppStrings.importRangeAll
                  : AppStrings.importRangeValue(_from, _to),
              onPressed: _pickRange,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < widget.calendars.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      _CalendarChoiceTile(
                        calendar: widget.calendars[i],
                        selected: _selected.contains(widget.calendars[i].id),
                        onPressed: () {
                          setState(() {
                            final id = widget.calendars[i].id;
                            if (_selected.contains(id)) {
                              _selected.remove(id);
                            } else {
                              _selected.add(id);
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PressBounce(
                    onPressed: () => Navigator.of(context).pop(),
                    color: colors.border,
                    pressedColor: Color.lerp(
                      colors.border,
                      Colors.black,
                      0.12,
                    )!,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressBounce(
                    onPressed: canImport
                        ? () => Navigator.of(context).pop(
                            CalendarImportPick(
                              calendars: [
                                for (final calendar in widget.calendars)
                                  if (_selected.contains(calendar.id)) calendar,
                              ],
                              from: _from,
                              to: _to,
                            ),
                          )
                        : null,
                    color: canImport ? colors.accentBright : colors.border,
                    pressedColor: canImport
                        ? Color.lerp(colors.accentBright, Colors.black, 0.16)!
                        : colors.border,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          AppStrings.importAction,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: canImport ? Colors.white : colors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportRangeTile extends StatelessWidget {
  const _ImportRangeTile({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.groupedBackground,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            ThemedAsset(
              asset: AppIcons.calendarOutlined,
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.importRangeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarChoiceTile extends StatelessWidget {
  const _CalendarChoiceTile({
    required this.calendar,
    required this.selected,
    required this.onPressed,
  });

  final DeviceCalendarInfo calendar;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: selected ? colors.selected : colors.groupedBackground,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 22,
              color: selected ? colors.accentBright : colors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    calendar.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  if (calendar.accountName.trim().isNotEmpty &&
                      calendar.accountName.trim() != calendar.name.trim())
                    Text(
                      calendar.accountName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.muted,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              AppStrings.importCalendarEventCount(calendar.eventCount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showCalendarImportConfirmDialog(
  BuildContext context, {
  required int count,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.of(context).card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.importConfirmTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.of(context).text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.importConfirmBody(count),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).secondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(false),
                  color: AppColors.of(context).border,
                  pressedColor: Color.lerp(
                    AppColors.of(context).border,
                    Colors.black,
                    0.12,
                  )!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(true),
                  color: AppColors.of(context).accentBright,
                  pressedColor: Color.lerp(
                    AppColors.of(context).accentBright,
                    Colors.black,
                    0.16,
                  )!,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.importAction,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}

enum CalendarImportCategoryMode { allInOne, perEvent }

Future<CalendarImportCategoryMode?> showCalendarImportCategoryModeDialog(
  BuildContext context,
) {
  return showDialog<CalendarImportCategoryMode>(
    context: context,
    builder: (context) {
      final colors = AppColors.of(context);
      return AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.importCategoryModeTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CategoryModeTile(
              title: AppStrings.importCategoryAll,
              body: AppStrings.importCategoryAllBody,
              onPressed: () => Navigator.of(
                context,
              ).pop(CalendarImportCategoryMode.allInOne),
            ),
            const SizedBox(height: 8),
            _CategoryModeTile(
              title: AppStrings.importCategoryEach,
              body: AppStrings.importCategoryEachBody,
              onPressed: () => Navigator.of(
                context,
              ).pop(CalendarImportCategoryMode.perEvent),
            ),
            const SizedBox(height: 16),
            PressBounce(
              onPressed: () => Navigator.of(context).pop(),
              color: colors.border,
              pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    AppStrings.cancel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CategoryModeTile extends StatelessWidget {
  const _CategoryModeTile({
    required this.title,
    required this.body,
    required this.onPressed,
  });

  final String title;
  final String body;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.groupedBackground,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<CalendarEvent>?> showCalendarImportEachCategoryDialog(
  BuildContext context,
  List<CalendarEvent> events,
) {
  return showDialog<List<CalendarEvent>>(
    context: context,
    builder: (context) => _EachCategoryDialog(events: events),
  );
}

class _EachCategoryDialog extends StatefulWidget {
  const _EachCategoryDialog({required this.events});

  final List<CalendarEvent> events;

  @override
  State<_EachCategoryDialog> createState() => _EachCategoryDialogState();
}

class _EachCategoryDialogState extends State<_EachCategoryDialog> {
  final _picked = <String, EventCategory>{};

  Future<void> _pick(CalendarEvent event) async {
    final category = await showCategoryPickerSheet(
      context,
      selectedId: _picked[event.id]?.id,
    );
    if (category == null || !mounted) return;
    setState(() => _picked[event.id] = category);
  }

  List<CalendarEvent> _assigned() {
    return [
      for (final event in widget.events)
        event.copyWith(
          categoryId: _picked[event.id]!.id,
          categoryName: _picked[event.id]!.name,
          categoryColor: _picked[event.id]!.color,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final canImport = widget.events.every(
      (event) => _picked.containsKey(event.id),
    );
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.importCategoryEachTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 360,
            child: ListView.separated(
              itemCount: widget.events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = widget.events[index];
                return _EachCategoryTile(
                  event: event,
                  category: _picked[event.id],
                  onPressed: () => _pick(event),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(),
                  color: colors.border,
                  pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: canImport
                      ? () => Navigator.of(context).pop(_assigned())
                      : null,
                  color: canImport ? colors.accentBright : colors.border,
                  pressedColor: canImport
                      ? Color.lerp(colors.accentBright, Colors.black, 0.16)!
                      : colors.border,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.importAction,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: canImport ? Colors.white : colors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EachCategoryTile extends StatelessWidget {
  const _EachCategoryTile({
    required this.event,
    required this.category,
    required this.onPressed,
  });

  final CalendarEvent event;
  final EventCategory? category;
  final VoidCallback onPressed;

  String get _dateLabel {
    final date = event.day;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    return '${date.year}. ${date.month}. ${date.day}. ($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.groupedBackground,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (category == null)
              Text(
                AppStrings.importCategoryPick,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.muted,
                ),
              )
            else
              EventCategoryChip(
                name: category!.name,
                color: category!.tint,
                onPressed: onPressed,
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showCalendarPermissionDialog(
  BuildContext context, {
  required bool openSettings,
}) async {
  final colors = AppColors.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.importPermissionTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.importPermissionBody,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(false),
                  color: colors.border,
                  pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(true),
                  color: colors.accentBright,
                  pressedColor: Color.lerp(
                    colors.accentBright,
                    Colors.black,
                    0.16,
                  )!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        openSettings
                            ? AppStrings.importPermissionSettings
                            : AppStrings.confirm,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}

Future<T> showCalendarImportLoading<T>(
  BuildContext context,
  Future<T> Function() task,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final colors = AppColors.of(context);
      return PopScope(
        canPop: false,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: CupertinoActivityIndicator(
                radius: 14,
                color: Color(0xFF8EC5FF),
              ),
            ),
          ),
        ),
      );
    },
  );
  try {
    return await task();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
