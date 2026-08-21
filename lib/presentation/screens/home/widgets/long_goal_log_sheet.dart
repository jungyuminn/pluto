import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/long_goal_local_datasource.dart';
import 'package:job_planner/domain/entities/long_goal.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/screens/home/widgets/long_goal_edit_sheet.dart';

Future<bool> showLongGoalLogSheet(
  BuildContext context, {
  required LongGoal goal,
  required DateTime day,
  VoidCallback? onChanged,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => LongGoalLogSheet(
      goal: goal,
      day: day,
      onChanged: onChanged,
    ),
  );
  return saved == true;
}

class LongGoalLogSheet extends StatefulWidget {
  const LongGoalLogSheet({
    super.key,
    required this.goal,
    required this.day,
    this.onChanged,
  });

  final LongGoal goal;
  final DateTime day;
  final VoidCallback? onChanged;

  @override
  State<LongGoalLogSheet> createState() => _LongGoalLogSheetState();
}

class _LongGoalLogSheetState extends State<LongGoalLogSheet> {
  late LongGoal _goal;
  late final PlainTextEditingController _value;
  late var _selectedDay = DateTime(
    widget.day.year,
    widget.day.month,
    widget.day.day,
  );
  var _saving = false;
  var _filled = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _value = PlainTextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    _fillFrom(AppScope.of(context).longGoalStore);
  }

  void _fillFrom(LongGoalLocalDataSource store) {
    final log = store.logOn(_goal.id, _selectedDay);
    final value = log?.value;
    _value.text = value == null ? '' : LongGoal.formatNumber(value);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  double? _parse(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _save({
    required DateTime day,
    double? value,
    bool pop = true,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    await AppScope.of(context).longGoalStore.upsertLog(
      LongGoalLog(
        goalId: _goal.id,
        date: LongGoalLocalDataSource.dateStamp(day),
        value: value,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onChanged?.call();
    if (pop) Navigator.of(context).pop(true);
  }

  Future<void> _saveNumber() async {
    await _save(day: _selectedDay, value: _parse(_value.text), pop: false);
  }

  void _selectLogDay(DateTime day) {
    final today = DateTime(widget.day.year, widget.day.month, widget.day.day);
    final picked = DateTime(day.year, day.month, day.day);
    if (picked.isAfter(today)) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedDay = picked);
    _fillFrom(AppScope.of(context).longGoalStore);
  }

  Future<void> _toggleDay(DateTime day) async {
    if (_saving) return;
    final log = AppScope.of(context).longGoalStore.logOn(_goal.id, day);
    final on = log != null && (log.value ?? 0) > 0;
    HapticFeedback.selectionClick();
    await _save(day: day, value: on ? null : 1, pop: false);
  }

  bool _checkedOn(DateTime day) {
    final log = AppScope.of(context).longGoalStore.logOn(_goal.id, day);
    return log != null && (log.value ?? 0) > 0;
  }

  String? _valueLabel(DateTime day) {
    final log = AppScope.of(context).longGoalStore.logOn(_goal.id, day);
    final value = log?.value;
    if (value == null) return null;
    return LongGoal.formatNumber(value);
  }

  List<DateTime> get _trackDays {
    final today = DateTime(widget.day.year, widget.day.month, widget.day.day);
    var start = _goal.startedDay(today);
    if (start.isAfter(today)) start = today;
    var end = today.add(const Duration(days: 6));
    if (_goal.kind.isCheckIn) {
      final span = _goal.target.round().clamp(1, 3650);
      final plannedEnd = start.add(Duration(days: span - 1));
      end = plannedEnd.isAfter(today) ? plannedEnd : today;
    }
    return [
      for (var day = start;
          !day.isAfter(end);
          day = day.add(const Duration(days: 1)))
        day,
    ];
  }

  Future<void> _previewStreakFail() async {
    if (_saving || _goal.kind != LongGoalKind.streak) return;
    final today = DateTime(widget.day.year, widget.day.month, widget.day.day);
    if (_goal.startedDay(today).isBefore(today)) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final next = _goal.copyWith(
      startedAt: LongGoal.dateStamp(today.subtract(const Duration(days: 2))),
    );
    await AppScope.of(context).longGoalStore.upsertGoal(next);
    if (!mounted) return;
    setState(() {
      _goal = next;
      _saving = false;
    });
    widget.onChanged?.call();
  }

  Future<void> _restartStreak() async {
    if (_saving) return;
    HapticFeedback.selectionClick();
    final today = DateTime(widget.day.year, widget.day.month, widget.day.day);
    final next = _goal.copyWith(startedAt: LongGoal.dateStamp(today));
    setState(() {
      _saving = true;
      _goal = next;
    });
    await AppScope.of(context).longGoalStore.upsertGoal(next);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onChanged?.call();
  }

  bool get _streakBroken {
    return _goal.streakBroken(
      AppScope.of(context).longGoalStore.logs,
      widget.day,
    );
  }

  Future<void> _edit() async {
    final saved = await showLongGoalEditSheet(context, initial: _goal);
    if (!saved || !mounted) return;
    final store = AppScope.of(context).longGoalStore;
    LongGoal? next;
    for (final goal in store.goals) {
      if (goal.id == _goal.id) next = goal;
    }
    if (next == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final updated = next;
    setState(() => _goal = updated);
    _fillFrom(store);
  }

  String get _valueHint {
    final today = DateTime(widget.day.year, widget.day.month, widget.day.day);
    final forToday = _selectedDay == today;
    if (_goal.kind == LongGoalKind.measure) {
      return forToday
          ? AppStrings.longGoalTodayValueHint
          : AppStrings.longGoalValueHint;
    }
    return forToday
        ? AppStrings.longGoalTodayAmountHint
        : AppStrings.longGoalAmountHint;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = Color(_goal.color);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final font = AppFonts.of(context);
    final store = AppScope.of(context).longGoalStore;
    final progress = _goal.progress(store.logs);
    final broken = _streakBroken;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: colors.tint(accent),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _goal.title,
                        style: TextStyle(
                          fontFamily: font,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: colors.text,
                        ),
                      ),
                    ),
                    PressBounce(
                      onPressed: _edit,
                      pressedColor: Colors.transparent,
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Text(
                          AppStrings.modify,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_goal.memo.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _goal.memo.trim(),
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onLongPress: _previewStreakFail,
                      child: Text(
                        AppStrings.longGoalProgress,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress.percent.toDouble()),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          AppStrings.longGoalPercent(value.round()),
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SegmentedProgressBar(
                  value: progress.barValue,
                  segments: progress.barSegments,
                  color: accent,
                  background: colors.card.withValues(alpha: 0.55),
                ),
                if (progress.summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _goal.format(progress.start),
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.muted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _goal.format(progress.target),
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _CheckInWeek(
                  days: _trackDays,
                  today: widget.day,
                  checkedOn: _checkedOn,
                  onToggle: _goal.kind.isCheckIn && !_saving && !broken
                      ? _toggleDay
                      : null,
                  onSelect: !_goal.kind.isCheckIn && !_saving
                      ? _selectLogDay
                      : null,
                  selected: _goal.kind.isCheckIn ? null : _selectedDay,
                  color: accent,
                  failed: broken,
                  valueOf: _goal.kind.isCheckIn ? null : _valueLabel,
                  unit: _goal.unit,
                ),
                if (_goal.kind.isCheckIn)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child: broken
                        ? Padding(
                            key: const ValueKey('restart'),
                            padding: const EdgeInsets.only(top: 12),
                            child: PressBounce(
                              onPressed: _saving ? null : _restartStreak,
                              color: colors.card.withValues(alpha: 0.55),
                              pressedColor: colors.pressed,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text(
                                    AppStrings.longGoalRestart,
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: colors.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('restart-gone'),
                            width: double.infinity,
                          ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,\-]'),
                            ),
                          ],
                          style: TextStyle(
                            fontFamily: font,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: _valueHint,
                            hintStyle: TextStyle(
                              fontFamily: font,
                              color: colors.hint,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            suffixText: _goal.unit.isEmpty ? null : _goal.unit,
                            suffixStyle: TextStyle(
                              fontFamily: font,
                              color: colors.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: colors.card.withValues(alpha: 0.55),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SaveCompanyButton(
                        onPressed: _saving ? () {} : _saveNumber,
                        color: accent,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.value,
    required this.segments,
    required this.color,
    required this.background,
  });

  final double value;
  final int segments;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final count = segments.clamp(1, 24);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          height: 8,
          child: Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: ColoredBox(
                      color: background,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: ((animated * count) - i).clamp(0.0, 1.0),
                          child: ColoredBox(
                            color: color,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CheckInWeek extends StatefulWidget {
  const _CheckInWeek({
    required this.days,
    required this.today,
    required this.checkedOn,
    required this.onToggle,
    required this.color,
    this.onSelect,
    this.selected,
    this.failed = false,
    this.valueOf,
    this.unit = '',
  });

  final List<DateTime> days;
  final DateTime today;
  final bool Function(DateTime day) checkedOn;
  final ValueChanged<DateTime>? onToggle;
  final ValueChanged<DateTime>? onSelect;
  final DateTime? selected;
  final Color color;
  final bool failed;
  final String? Function(DateTime day)? valueOf;
  final String unit;

  @override
  State<_CheckInWeek> createState() => _CheckInWeekState();
}

class _CheckInWeekState extends State<_CheckInWeek>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late var _displayDays = List<DateTime>.of(widget.days);
  final _leaving = <String>{};
  List<DateTime>? _pending;
  var _foldStartOffset = 0.0;
  late final _fold = AnimationController(vsync: this, duration: _foldAnim);

  static const _sunday = Color(0xFFEF4444);
  static const _saturday = Color(0xFF60A5FA);
  static const _foldAnim = Duration(milliseconds: 420);

  double get _cellWidth => widget.valueOf == null ? 44.0 : 52.0;

  @override
  void initState() {
    super.initState();
    _fold.addListener(_syncScroll);
    _fold.addStatusListener(_onFoldStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void didUpdateWidget(_CheckInWeek oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameDays(oldWidget.days, widget.days)) return;
    _foldTo(widget.days);
  }

  bool _sameDays(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int get _leavingPrefixCount {
    var n = 0;
    for (final day in _displayDays) {
      if (!_leaving.contains(LongGoal.dateStamp(day))) break;
      n++;
    }
    return n;
  }

  void _foldTo(List<DateTime> next) {
    final keep = {for (final day in next) LongGoal.dateStamp(day)};
    final leaving = {
      for (final day in _displayDays)
        if (!keep.contains(LongGoal.dateStamp(day))) LongGoal.dateStamp(day),
    };
    if (leaving.isEmpty) {
      setState(() => _displayDays = List.of(next));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
      return;
    }
    _pending = List.of(next);
    _foldStartOffset = _scroll.hasClients ? _scroll.offset : 0;
    setState(() {
      _leaving
        ..clear()
        ..addAll(leaving);
      final existing = {
        for (final day in _displayDays) LongGoal.dateStamp(day),
      };
      for (final day in next) {
        if (!existing.contains(LongGoal.dateStamp(day))) {
          _displayDays.add(day);
        }
      }
    });
    _fold.forward(from: 0);
  }

  void _syncScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || _leaving.isEmpty) return;
      final shrink = _leavingPrefixCount * _cellWidth * _fold.value;
      final offset = (_foldStartOffset - shrink)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.jumpTo(offset);
    });
  }

  void _onFoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final pending = _pending;
    if (pending == null || _leaving.isEmpty) return;
    setState(() {
      _displayDays = pending;
      _leaving.clear();
      _pending = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fold.reset();
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(
        _scroll.offset.clamp(0.0, _scroll.position.maxScrollExtent),
      );
    });
  }

  @override
  void dispose() {
    _fold.removeListener(_syncScroll);
    _fold.removeStatusListener(_onFoldStatus);
    _fold.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scroll.hasClients) return;
    final index = _displayDays.indexWhere(_isToday);
    if (index < 0) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      return;
    }
    final viewport = _scroll.position.viewportDimension;
    final origin = 6.0 + index * _cellWidth;
    final target = origin - (viewport - _cellWidth) / 2;
    _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  bool _isToday(DateTime day) {
    final today = widget.today;
    return day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
  }

  bool _isFuture(DateTime day) {
    final today = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day,
    );
    return day.isAfter(today);
  }

  Color _weekdayColor(
    DateTime day,
    AppColors colors, {
    required bool isToday,
    required bool isFuture,
  }) {
    if (isToday) return widget.color;
    if (isFuture) return colors.hint;
    if (day.weekday == DateTime.sunday) return _sunday;
    if (day.weekday == DateTime.saturday) return _saturday;
    return colors.muted;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return AnimatedOpacity(
      duration: _foldAnim,
      curve: Curves.easeOutCubic,
      opacity: widget.failed ? 0.42 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          height: widget.valueOf == null ? 86 : 108,
          child: AnimatedBuilder(
            animation: _fold,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_fold.value);
              return ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
                itemCount: _displayDays.length,
                itemBuilder: (context, index) {
                  final day = _displayDays[index];
                  final stamp = LongGoal.dateStamp(day);
                  final leaving = _leaving.contains(stamp);
                  final width = leaving ? _cellWidth * (1 - t) : _cellWidth;
                  return ClipRect(
                    key: ValueKey(stamp),
                    child: Opacity(
                      opacity: leaving ? (1 - t) : 1,
                      child: SizedBox(
                        width: width,
                        child: OverflowBox(
                          maxWidth: _cellWidth,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: _cellWidth,
                            child: _dayCell(context, colors, font, day),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _dayCell(
    BuildContext context,
    AppColors colors,
    String? font,
    DateTime day,
  ) {
    final isToday = _isToday(day);
    final isFuture = _isFuture(day);
    final checked = widget.checkedOn(day);
    final missed =
        widget.valueOf == null && !checked && !isToday && !isFuture;
    final weekday = AppStrings.weekdays[day.weekday % 7];
    final selected = widget.selected != null &&
        day.year == widget.selected!.year &&
        day.month == widget.selected!.month &&
        day.day == widget.selected!.day;
    final canSelect = widget.onSelect != null && !isFuture;
    final inset = widget.valueOf == null
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 2, vertical: 2);
    final inner = widget.valueOf == null
        ? const EdgeInsets.symmetric(vertical: 2)
        : const EdgeInsets.fromLTRB(2, 10, 2, 2);
    return PressBounce(
      onPressed: canSelect
          ? () => widget.onSelect!(day)
          : isToday && widget.onToggle != null
              ? () => widget.onToggle!(day)
              : null,
      pressedScale: 0.92,
      pressedColor: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: inset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? widget.color.withValues(alpha: 0.16) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: inner,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekday,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: _weekdayColor(
                      day,
                      colors,
                      isToday: isToday || selected,
                      isFuture: isFuture,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: missed || isFuture
                        ? colors.muted
                        : isToday || selected
                            ? widget.color
                            : colors.text,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: _cellWidth - 12,
                  height: widget.valueOf == null ? 22 : 32,
                  child: widget.valueOf == null
                      ? _checkMark(
                          colors,
                          checked: checked,
                          missed: missed,
                          isToday: isToday,
                        )
                      : _valueMark(
                          colors,
                          font,
                          label: widget.valueOf!(day),
                          isToday: isToday || selected,
                          isFuture: isFuture,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkMark(
    AppColors colors, {
    required bool checked,
    required bool missed,
    required bool isToday,
  }) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? widget.color : Colors.transparent,
            border: Border.all(
              color: checked
                  ? widget.color
                  : isToday
                      ? widget.color
                      : colors.border,
              width: isToday && !checked ? 2 : 1.5,
            ),
          ),
          child: missed
              ? Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colors.muted,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _valueMark(
    AppColors colors,
    String? font, {
    required String? label,
    required bool isToday,
    required bool isFuture,
  }) {
    if (label == null || label.isEmpty) {
      return Center(
        child: Text(
          isFuture ? '' : '—',
          style: TextStyle(
            fontFamily: font,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1,
            color: isToday ? widget.color : colors.muted,
          ),
        ),
      );
    }
    final unit = widget.unit.trim();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontFamily: font,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
              color: widget.color,
            ),
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              unit,
              maxLines: 1,
              style: TextStyle(
                fontFamily: font,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1,
                color: widget.color.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
