import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/calendar/calendar_years.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/device_calendar_import.dart';
import 'package:job_planner/data/datasources/device_calendar_mapper.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:job_planner/presentation/screens/settings/widgets/backup_dialogs.dart';
import 'package:job_planner/presentation/widgets/app_calendar/app_calendar.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

class CalendarImportWizardResult {
  const CalendarImportWizardResult({
    required this.events,
    this.truncated = false,
  });

  final List<CalendarEvent> events;
  final bool truncated;
}

Future<CalendarImportWizardResult?> showCalendarImportWizard(
  BuildContext context, {
  required List<DeviceCalendarInfo> calendars,
  required List<CalendarEvent> existing,
}) {
  return showModalBottomSheet<CalendarImportWizardResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      return SizedBox(
        width: size.width,
        height: size.height * 0.68,
        child: CalendarImportWizard(
          calendars: calendars,
          existing: existing,
        ),
      );
    },
  );
}

enum _ImportStep { calendars, range, confirm, categoryMode, category }

enum _CategoryMode { allInOne, perEvent }

class CalendarImportWizard extends StatefulWidget {
  const CalendarImportWizard({
    super.key,
    required this.calendars,
    required this.existing,
  });

  final List<DeviceCalendarInfo> calendars;
  final List<CalendarEvent> existing;

  @override
  State<CalendarImportWizard> createState() => _CalendarImportWizardState();
}

class _CalendarImportWizardState extends State<CalendarImportWizard> {
  static const _total = 5;
  static const _pageDuration = Duration(milliseconds: 420);
  static const _pageCurve = Curves.easeOutCubic;

  final _pages = PageController();
  var _step = _ImportStep.calendars;
  var _busy = false;
  late final Set<String> _selected = {
    for (final calendar in widget.calendars) calendar.id,
  };
  late DateTime _from = CalendarYears.start();
  late DateTime _to = DateTime(CalendarYears.max(), 12, 31);
  var _loading = false;
  DeviceCalendarImportResult? _preview;
  final _skipped = <String>{};
  var _mode = _CategoryMode.allInOne;
  EventCategory? _allCategory;
  final _eachCategory = <String, EventCategory>{};

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  double get _pageNumber {
    if (!_pages.hasClients) return _step.index.toDouble();
    return _pages.page ?? _step.index.toDouble();
  }

  List<DeviceCalendarInfo> get _pickedCalendars => [
    for (final calendar in widget.calendars)
      if (_selected.contains(calendar.id)) calendar,
  ];

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

  List<CalendarEvent> get _importEvents => [
    for (final event in _preview?.events ?? const <CalendarEvent>[])
      if (!_skipped.contains(event.id)) event,
  ];

  bool get _canContinue {
    return switch (_step) {
      _ImportStep.calendars => _selected.isNotEmpty,
      _ImportStep.range => true,
      _ImportStep.confirm => _importEvents.isNotEmpty,
      _ImportStep.categoryMode => true,
      _ImportStep.category => _mode == _CategoryMode.allInOne
          ? _allCategory != null
          : _importEvents.isNotEmpty &&
                _importEvents.every(
                  (event) => _eachCategory.containsKey(event.id),
                ),
    };
  }

  String _titleOf(_ImportStep step) {
    return switch (step) {
      _ImportStep.calendars => AppStrings.importCalendarsTitle,
      _ImportStep.range => AppStrings.importRangeTitle,
      _ImportStep.confirm => AppStrings.importConfirmTitle,
      _ImportStep.categoryMode => AppStrings.importCategoryModeTitle,
      _ImportStep.category => _mode == _CategoryMode.allInOne
          ? AppStrings.importCategoryAll
          : AppStrings.importCategoryEachTitle,
    };
  }

  Future<void> _goTo(_ImportStep step) async {
    if (_busy || _step == step) return;
    setState(() {
      _busy = true;
      _step = step;
    });
    try {
      if (_pages.hasClients) {
        await _pages.animateToPage(
          step.index,
          duration: _pageDuration,
          curve: _pageCurve,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      } else {
        _busy = false;
      }
    }
  }

  void _back() {
    if (_busy || _loading) return;
    if (_step == _ImportStep.calendars) {
      Navigator.of(context).pop();
      return;
    }
    _goTo(_ImportStep.values[_step.index - 1]);
  }

  Future<void> _next() async {
    if (_busy || !_canContinue || _loading) return;
    if (_step == _ImportStep.range) {
      await _loadPreview();
      return;
    }
    if (_step == _ImportStep.category) {
      _finish();
      return;
    }
    await _goTo(_ImportStep.values[_step.index + 1]);
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    try {
      final source = await DeviceCalendarImport.events(
        _pickedCalendars.map((item) => item.id),
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      final preview = DeviceCalendarMapper.mapToTodos(
        source: source,
        category: EventCategory.fallback,
        existing: widget.existing,
        from: _from,
        to: _to,
      );
      if (preview.events.isEmpty) {
        setState(() {
          _loading = false;
          _preview = null;
          _skipped.clear();
          _eachCategory.clear();
        });
        await showBackupMessageDialog(
          context,
          title: AppStrings.importNoEventsTitle,
          body: AppStrings.importNoEventsBody,
        );
        return;
      }
      setState(() {
        _loading = false;
        _preview = preview;
        _skipped.clear();
        _eachCategory.removeWhere(
          (id, _) => preview.events.every((event) => event.id != id),
        );
      });
      await _goTo(_ImportStep.confirm);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showBackupMessageDialog(
        context,
        title: AppStrings.importFailedTitle,
        body: AppStrings.importFailedBody,
      );
    }
  }

  void _finish() {
    final preview = _preview;
    final events = _importEvents;
    if (preview == null || events.isEmpty) return;
    if (_mode == _CategoryMode.allInOne) {
      final category = _allCategory;
      if (category == null) return;
      Navigator.of(context).pop(
        CalendarImportWizardResult(
          events: [
            for (final event in events)
              event.copyWith(
                categoryId: category.id,
                categoryName: category.name,
                categoryColor: category.color,
              ),
          ],
          truncated: preview.truncated,
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      CalendarImportWizardResult(
        events: [
          for (final event in events)
            event.copyWith(
              categoryId: _eachCategory[event.id]!.id,
              categoryName: _eachCategory[event.id]!.name,
              categoryColor: _eachCategory[event.id]!.color,
            ),
        ],
        truncated: preview.truncated,
      ),
    );
  }

  void _toggleEvent(String id) {
    setState(() {
      if (_skipped.remove(id)) return;
      _skipped.add(id);
      _eachCategory.remove(id);
    });
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
      _preview = null;
      _skipped.clear();
    });
  }

  Future<void> _pickAllCategory() async {
    final category = await showCategoryPickerSheet(
      context,
      selectedId: _allCategory?.id,
    );
    if (category == null || !mounted) return;
    setState(() => _allCategory = category);
  }

  Future<void> _pickEachCategory(CalendarEvent event) async {
    final category = await showCategoryPickerSheet(
      context,
      selectedId: _eachCategory[event.id]?.id,
    );
    if (category == null || !mounted) return;
    setState(() => _eachCategory[event.id] = category);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _pages,
                builder: (context, _) {
                  final page = _pageNumber;
                  final visual = _ImportStep.values[page.round().clamp(
                    0,
                    _total - 1,
                  )];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.importStepLabel(
                          page.round().clamp(0, _total - 1) + 1,
                          _total,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ProgressBar(value: (page + 1) / _total),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Align(
                          key: ValueKey(visual),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _titleOf(visual),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final step in _ImportStep.values) _bodyFor(step),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PressBounce(
                      onPressed: _loading ? null : _back,
                      color: colors.border,
                      pressedColor: Color.lerp(
                        colors.border,
                        Colors.black,
                        0.12,
                      )!,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            _step == _ImportStep.calendars
                                ? AppStrings.cancel
                                : AppStrings.importBack,
                            style: TextStyle(
                              fontSize: 16,
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
                      onPressed: !_loading && _canContinue ? _next : null,
                      color: _loading || _canContinue
                          ? colors.accentBright
                          : colors.border,
                      pressedColor: _loading || _canContinue
                          ? Color.lerp(
                              colors.accentBright,
                              Colors.black,
                              0.16,
                            )!
                          : colors.border,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: _loading
                              ? const CupertinoActivityIndicator(
                                  radius: 10,
                                  color: Colors.white,
                                )
                              : Text(
                                  _step == _ImportStep.category
                                      ? AppStrings.importAction
                                      : AppStrings.importNext,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _canContinue
                                        ? Colors.white
                                        : colors.muted,
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
      ),
    );
  }

  Widget _bodyFor(_ImportStep step) {
    final colors = AppColors.of(context);
    return switch (step) {
      _ImportStep.calendars => Column(
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
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: widget.calendars.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final calendar = widget.calendars[index];
                final selected = _selected.contains(calendar.id);
                return _ChoiceTile(
                  title: calendar.name,
                  subtitle:
                      calendar.accountName.trim().isNotEmpty &&
                          calendar.accountName.trim() != calendar.name.trim()
                      ? calendar.accountName
                      : null,
                  trailing: AppStrings.importCalendarEventCount(
                    calendar.eventCount,
                  ),
                  selected: selected,
                  onPressed: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(calendar.id);
                      } else {
                        _selected.add(calendar.id);
                      }
                      _preview = null;
                      _skipped.clear();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      _ImportStep.range => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.importRangeBody,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          _RangeTile(
            label: _isFullRange
                ? AppStrings.importRangeAll
                : AppStrings.importRangeValue(_from, _to),
            onPressed: _pickRange,
          ),
        ],
      ),
      _ImportStep.confirm => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.importConfirmBody(_importEvents.length),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.importConfirmSkipHint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _preview?.events.length ?? 0,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = _preview!.events[index];
                final selected = !_skipped.contains(event.id);
                return _EventPreviewTile(
                  event: event,
                  selected: selected,
                  onPressed: () => _toggleEvent(event.id),
                );
              },
            ),
          ),
        ],
      ),
      _ImportStep.categoryMode => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeTile(
            title: AppStrings.importCategoryAll,
            body: AppStrings.importCategoryAllBody,
            selected: _mode == _CategoryMode.allInOne,
            onPressed: () => setState(() => _mode = _CategoryMode.allInOne),
          ),
          const SizedBox(height: 8),
          _ModeTile(
            title: AppStrings.importCategoryEach,
            body: AppStrings.importCategoryEachBody,
            selected: _mode == _CategoryMode.perEvent,
            onPressed: () => setState(() => _mode = _CategoryMode.perEvent),
          ),
        ],
      ),
      _ImportStep.category => _mode == _CategoryMode.allInOne
          ? Align(
              alignment: Alignment.topCenter,
              child: _CategoryPickTile(
                category: _allCategory,
                onPressed: _pickAllCategory,
              ),
            )
          : ListView.separated(
              itemCount: _importEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = _importEvents[index];
                return _EventCategoryTile(
                  event: event,
                  category: _eachCategory[event.id],
                  onPressed: () => _pickEachCategory(event),
                );
              },
            ),
    };
  }
}

Color _wizardTileIdle(AppColors colors, {bool selected = false}) {
  if (!selected) return colors.groupedBackground;
  return Color.lerp(colors.groupedBackground, colors.accentBright, 0.18)!;
}

Color _wizardTilePressed(AppColors colors, {bool selected = false}) {
  final idle = _wizardTileIdle(colors, selected: selected);
  return Color.lerp(
    idle,
    colors.isDark ? Colors.white : Colors.black,
    colors.isDark ? 0.14 : 0.1,
  )!;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final t = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 4,
        child: ColoredBox(
          color: colors.border,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: t,
              heightFactor: 1,
              child: ColoredBox(color: colors.accentBright),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onPressed,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: _wizardTileIdle(colors, selected: selected),
      pressedColor: _wizardTilePressed(colors, selected: selected),
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
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
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

class _RangeTile extends StatelessWidget {
  const _RangeTile({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: _wizardTileIdle(colors),
      pressedColor: _wizardTilePressed(colors),
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

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.body,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: _wizardTileIdle(colors, selected: selected),
      pressedColor: _wizardTilePressed(colors, selected: selected),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 22,
              color: selected ? colors.accentBright : colors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}

class _CategoryPickTile extends StatelessWidget {
  const _CategoryPickTile({required this.category, required this.onPressed});

  final EventCategory? category;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: _wizardTileIdle(colors),
      pressedColor: _wizardTilePressed(colors),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category == null
                    ? AppStrings.importCategoryPick
                    : category!.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: category == null ? colors.muted : colors.text,
                ),
              ),
            ),
            if (category != null) _CategoryDot(color: category!.tint),
          ],
        ),
      ),
    );
  }
}

class _EventPreviewTile extends StatelessWidget {
  const _EventPreviewTile({
    required this.event,
    required this.selected,
    required this.onPressed,
  });

  final CalendarEvent event;
  final bool selected;
  final VoidCallback onPressed;

  String get _dateLabel {
    final date = event.day;
    final weekday = AppStrings.weekdays[date.weekday % 7];
    final dateText = '${date.year}. ${date.month}. ${date.day}. ($weekday)';
    final time = event.timeLabel;
    if (time == null) return dateText;
    return '$dateText · $time';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: _wizardTileIdle(colors, selected: selected),
      pressedColor: _wizardTilePressed(colors, selected: selected),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 10),
            _RoundCheck(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RoundCheck extends StatelessWidget {
  const _RoundCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? colors.accentBright : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: selected
            ? null
            : Border.all(color: colors.muted, width: 1.8),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _EventCategoryTile extends StatelessWidget {
  const _EventCategoryTile({
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
      color: _wizardTileIdle(colors),
      pressedColor: _wizardTilePressed(colors),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              _CategoryDot(color: category!.tint, label: category!.name),
          ],
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.color, this.label});

  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
