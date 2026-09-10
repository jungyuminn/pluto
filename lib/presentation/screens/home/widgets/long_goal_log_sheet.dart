import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/long_goal_local_datasource.dart';
import 'package:pluto/domain/entities/long_goal.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/home/widgets/long_goal_edit_sheet.dart';

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

    return AccentSelectionTheme(
      color: accent,
      child: Padding(
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
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _AnimatedProgress(
                      value: progress.percent.toDouble(),
                      builder: (context, value) {
                        return Text(
                          AppStrings.longGoalPercent(value.round()),
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _GoalProgressBar(
                  value: progress.barValue,
                  ticks: progress.barSegments,
                  color: accent,
                  background: colors.border,
                  gapColor: colors.tint(accent),
                ),
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
                  child: progress.summary.isEmpty
                      ? const SizedBox(
                          key: ValueKey('range-gone'),
                          width: double.infinity,
                        )
                      : Padding(
                          key: const ValueKey('range'),
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
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
                        ),
                ),
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
    ),
    );
  }
}

class _AnimatedProgress extends StatefulWidget {
  const _AnimatedProgress({
    required this.value,
    required this.builder,
  });

  static const duration = Duration(milliseconds: 800);
  static const curve = Curves.easeOutCubic;

  final double value;
  final Widget Function(BuildContext context, double value) builder;

  @override
  State<_AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<_AnimatedProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _AnimatedProgress.duration,
    )..addListener(() => setState(() {}));
    _animation = const AlwaysStoppedAnimation(0);
    _move(from: 0, to: widget.value);
  }

  @override
  void didUpdateWidget(covariant _AnimatedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _move(from: _animation.value, to: widget.value);
    }
  }

  void _move({required double from, required double to}) {
    _animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: _AnimatedProgress.curve),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animation.value);
  }
}

class _GoalProgressBar extends StatelessWidget {
  const _GoalProgressBar({
    required this.value,
    required this.ticks,
    required this.color,
    required this.background,
    required this.gapColor,
  });

  static const _height = 12.0;
  static const _gap = 2.0;

  final double value;
  final int ticks;
  final Color color;
  final Color background;
  final Color gapColor;

  @override
  Widget build(BuildContext context) {
    final markCount = ticks.clamp(2, 12);
    return _AnimatedProgress(
      value: value.clamp(0.0, 1.0),
      builder: (context, filled) {
        return SizedBox(
          height: _height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * filled.clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: background),
                    if (width > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: width,
                          height: _height,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color,
                                  Color.lerp(color, Colors.white, 0.28)!,
                                ],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        for (var i = 1; i < markCount; i++) ...[
                          const Expanded(child: SizedBox.expand()),
                          ColoredBox(
                            color: gapColor,
                            child: const SizedBox(width: _gap, height: _height),
                          ),
                        ],
                        const Expanded(child: SizedBox.expand()),
                      ],
                    ),
                  ],
                );
              },
            ),
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
      color: selected
          ? widget.color.withValues(alpha: 0.16)
          : Colors.transparent,
      pressedColor: widget.color.withValues(alpha: selected ? 0.28 : 0.18),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: inset,
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
                    ? _CheckInMark(
                        checked: checked,
                        missed: missed,
                        isToday: isToday,
                        color: widget.color,
                        muted: colors.muted,
                        border: colors.border,
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
    );
  }

  Widget _valueMark(
    AppColors colors,
    String? font, {
    required String? label,
    required bool isToday,
    required bool isFuture,
  }) {
    final unit = widget.unit.trim();
    final empty = label == null || label.isEmpty;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ...previous,
              if (current != null) current,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final leaving = animation.status == AnimationStatus.reverse ||
              animation.status == AnimationStatus.dismissed;
          final slide = Tween<Offset>(
            begin: Offset(0, leaving ? -0.55 : 0.55),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: empty
            ? Text(
                key: ValueKey(isFuture ? 'future' : 'empty'),
                isFuture ? '' : '—',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: isToday ? widget.color : colors.muted,
                ),
              )
            : Column(
                key: ValueKey('v:$label:$unit'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
              ),
      ),
    );
  }
}

class _CheckInMark extends StatefulWidget {
  const _CheckInMark({
    required this.checked,
    required this.missed,
    required this.isToday,
    required this.color,
    required this.muted,
    required this.border,
  });

  final bool checked;
  final bool missed;
  final bool isToday;
  final Color color;
  final Color muted;
  final Color border;

  @override
  State<_CheckInMark> createState() => _CheckInMarkState();
}

class _CheckInMarkState extends State<_CheckInMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    );
    if (widget.checked) _draw.value = 1;
  }

  @override
  void didUpdateWidget(_CheckInMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.checked && widget.checked) {
      _draw.forward();
    } else if (oldWidget.checked && !widget.checked) {
      _draw.reverse();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: widget.missed
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.border, width: 1.5),
                ),
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: widget.muted,
                  ),
                ),
              )
            : AnimatedBuilder(
                animation: _draw,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CheckInPainter(
                      t: _draw.value,
                      color: widget.color,
                      border: widget.border,
                      isToday: widget.isToday,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CheckInPainter extends CustomPainter {
  const _CheckInPainter({
    required this.t,
    required this.color,
    required this.border,
    required this.isToday,
  });

  final double t;
  final Color color;
  final Color border;
  final bool isToday;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Curves.easeOutCubic.transform((t / 0.5).clamp(0.0, 1.0));
    final check = Curves.easeInOutCubic.transform(
      ((t - 0.4) / 0.6).clamp(0.0, 1.0),
    );
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final idleWidth = isToday ? 2.0 : 1.5;
    final strokeWidth = idleWidth + (1.5 - idleWidth) * fill;
    final strokeColor = Color.lerp(isToday ? color : border, color, fill)!;

    canvas.drawCircle(
      center,
      radius - strokeWidth / 2,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (fill > 0) {
      canvas.drawCircle(
        center,
        (radius - 0.5) * fill,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    if (check <= 0) return;
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.27, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.68)
      ..lineTo(size.width * 0.73, size.height * 0.32);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * check),
      checkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckInPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color != color ||
        oldDelegate.border != border ||
        oldDelegate.isToday != isToday;
  }
}
