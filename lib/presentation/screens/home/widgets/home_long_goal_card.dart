import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/drop_in.dart';
import 'package:pluto/core/utils/swipe_to_delete.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/long_goal.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:pluto/presentation/screens/home/widgets/long_goal_edit_sheet.dart';
import 'package:pluto/presentation/screens/home/widgets/long_goal_log_sheet.dart';

class HomeLongGoalCard extends StatefulWidget {
  const HomeLongGoalCard({
    super.key,
    required this.goals,
    required this.categories,
    required this.today,
    required this.compact,
    required this.onChanged,
  });

  final List<LongGoal> goals;
  final List<EventCategory> categories;
  final DateTime today;
  final bool compact;
  final VoidCallback onChanged;

  @override
  State<HomeLongGoalCard> createState() => _HomeLongGoalCardState();
}

class _HomeLongGoalCardState extends State<HomeLongGoalCard> {
  final _listBoxKey = GlobalKey();
  late var _goals = List.of(widget.goals);
  final _reveals = <String, double>{};
  final _liveIds = <String>{};
  String? _draggingId;
  String? _settlingId;
  Offset _settleFrom = Offset.zero;
  var _settleGen = 0;

  static const _slotAnim = Duration(milliseconds: 240);

  double get _labelHeight => 52 * AppFonts.labelScaleOf(context);

  double get _extent => _labelHeight + (widget.compact ? 8 : 10);

  @override
  void didUpdateWidget(HomeLongGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggingId != null) return;
    _syncGoals(List.of(widget.goals));
  }

  void _syncGoals(List<LongGoal> next) {
    final prev = _goals;
    final prevById = {for (final goal in prev) goal.id: goal};
    final nextIds = {for (final goal in next) goal.id};
    _liveIds
      ..clear()
      ..addAll(nextIds);

    final outgoingIndex = {
      for (var i = 0; i < prev.length; i++)
        if (!nextIds.contains(prev[i].id)) prev[i].id: i,
    };

    final merged = [...next];
    final inserted = outgoingIndex.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in inserted) {
      final goal = prevById[entry.key];
      if (goal == null) continue;
      merged.insert(entry.value.clamp(0, merged.length), goal);
      _reveals[goal.id] = 0;
    }

    final appearing = <String>[];
    for (final goal in next) {
      if (prevById.containsKey(goal.id)) {
        _reveals[goal.id] = 1;
        continue;
      }
      _reveals[goal.id] = 0;
      appearing.add(goal.id);
    }

    _goals = merged;
    setState(() {});

    if (appearing.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        var changed = false;
        for (final id in appearing) {
          if (!_liveIds.contains(id)) continue;
          if (_reveals[id] == 1) continue;
          _reveals[id] = 1;
          changed = true;
        }
        if (changed) setState(() {});
      });
    }

    if (outgoingIndex.isEmpty) return;
    Future<void>.delayed(_slotAnim, () {
      if (!mounted) return;
      final before = _goals.length;
      _goals.removeWhere((goal) {
        return !_liveIds.contains(goal.id) && (_reveals[goal.id] ?? 1) == 0;
      });
      if (_goals.length == before) return;
      setState(() {});
    });
  }

  double _layoutExtent(LongGoal goal) {
    return _extent * (_reveals[goal.id] ?? 1);
  }

  Future<void> _add() async {
    final saved = await showLongGoalEditSheet(context);
    if (saved) widget.onChanged();
  }

  Future<void> _open(LongGoal goal) async {
    await showLongGoalLogSheet(
      context,
      goal: goal,
      day: widget.today,
      onChanged: _syncFromStore,
    );
    widget.onChanged();
  }

  void _syncFromStore() {
    if (!mounted) return;
    _syncGoals(List.of(AppScope.of(context).longGoalStore.goals));
  }

  Future<bool> _delete(LongGoal goal) async {
    final confirmed = await showDeleteEventDialog(
      context,
      title: goal.title,
      body: AppStrings.longGoalDeleteBody,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).longGoalStore.deleteGoal(goal.id);
    widget.onChanged();
    return true;
  }

  LongGoal? get _dragged {
    final id = _draggingId;
    if (id == null) return null;
    for (final goal in _goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  void _onDragStarted(LongGoal goal) {
    setState(() => _draggingId = goal.id);
  }

  void _onDragUpdate(Offset global) {
    if (_dragged == null) return;
    final box = _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _moveTo(_indexAt(box.globalToLocal(global).dy));
  }

  Offset? _slotOrigin(String id) {
    final box = _listBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    var y = 0.0;
    for (final goal in _goals) {
      if (goal.id == id) {
        return box.localToGlobal(Offset(0, y));
      }
      y += _layoutExtent(goal);
    }
    return box.localToGlobal(Offset.zero);
  }

  Future<void> _onDragEnded(DraggableDetails details) async {
    final id = _draggingId;
    final origin = id == null ? null : _slotOrigin(id);
    final delta = origin == null ? Offset.zero : details.offset - origin;
    setState(() {
      if (id != null && delta.distance > 2) {
        _settlingId = id;
        _settleFrom = delta;
        _settleGen++;
      } else {
        _settlingId = null;
      }
      _draggingId = null;
    });
    if (id == null || !mounted) return;
    await AppScope.of(context).longGoalStore.reorderGoals(_goals);
    widget.onChanged();
  }

  int _indexAt(double y) {
    if (_goals.isEmpty) return 0;
    final from = _goals.indexWhere((goal) => goal.id == _draggingId);
    var closest = 0;
    var best = double.infinity;
    for (var i = 0; i < _goals.length; i++) {
      final dist = (y - (i * _extent + _extent / 2)).abs();
      if (dist < best) {
        best = dist;
        closest = i;
      }
    }
    if (from >= 0 && closest != from) {
      final top = from * _extent;
      if (y >= top - _extent * 0.18 && y < top + _extent * 1.18) {
        return from;
      }
    }
    return closest;
  }

  void _moveTo(int to) {
    final from = _goals.indexWhere((goal) => goal.id == _draggingId);
    if (from < 0) return;
    final nextTo = to.clamp(0, _goals.length - 1);
    if (from == nextTo) return;
    final next = List<LongGoal>.of(_goals);
    final moved = next.removeAt(from);
    next.insert(nextTo, moved);
    setState(() => _goals = next);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.longGoalTitle,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 16),
            _buildList(),
            AddEventButton(
              onPressed: _add,
              label: AppStrings.longGoalAdd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    var height = 0.0;
    final tops = <double>[];
    for (final goal in _goals) {
      tops.add(height);
      height += _layoutExtent(goal);
    }
    return AnimatedContainer(
      key: _listBoxKey,
      duration: _slotAnim,
      curve: Curves.easeOutCubic,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < _goals.length; i++)
            AnimatedPositioned(
              key: ValueKey(_goals[i].id),
              duration: _slotAnim,
              curve: Curves.easeOutCubic,
              top: tops[i],
              left: 0,
              right: 0,
              height: _layoutExtent(_goals[i]),
              child: _slotBody(_goals[i]),
            ),
        ],
      ),
    );
  }

  Widget _slotBody(LongGoal goal) {
    final settling = goal.id == _settlingId;
    final body = AnimatedOpacity(
      duration: _slotAnim,
      curve: Curves.easeOutCubic,
      opacity: _reveals[goal.id] ?? 1,
      child: IgnorePointer(
        ignoring: settling || (_reveals[goal.id] ?? 1) < 1,
        child: _tile(goal),
      ),
    );
    final clipped = settling ? body : ClipRect(child: body);
    if (!settling) return clipped;
    return DropIn(
      key: ValueKey(_settleGen),
      from: _settleFrom,
      onDone: () {
        if (!mounted || _settlingId != goal.id) return;
        setState(() => _settlingId = null);
      },
      child: clipped,
    );
  }

  Widget _tile(LongGoal goal) {
    final label = _label(goal, onPressed: () => _open(goal));
    final body = Padding(
      padding: EdgeInsets.only(bottom: widget.compact ? 8 : 10),
      child: SwipeToDelete(
        onSwipeLeft: () => _delete(goal),
        child: label,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return LongPressDraggable<String>(
          data: goal.id,
          delay: const Duration(milliseconds: 400),
          hapticFeedbackOnStart: true,
          rootOverlay: true,
          maxSimultaneousDrags: 1,
          onDragStarted: () => _onDragStarted(goal),
          onDragUpdate: (details) => _onDragUpdate(details.globalPosition),
          onDragEnd: (details) => unawaited(_onDragEnded(details)),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Transform.scale(
                scale: 1.03,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _label(goal),
                ),
              ),
            ),
          ),
          childWhenDragging: Padding(
            padding: EdgeInsets.only(bottom: widget.compact ? 8 : 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.of(context).pressed,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: SizedBox(
                height: _labelHeight,
                width: double.infinity,
              ),
            ),
          ),
          child: body,
        );
      },
    );
  }

  Widget _label(LongGoal goal, {VoidCallback? onPressed}) {
    final store = AppScope.of(context).longGoalStore;
    for (final item in store.goals) {
      if (item.id == goal.id) {
        goal = item;
        break;
      }
    }
    final progress = goal.progress(store.logs);
    final summary = progress.summary.isNotEmpty
        ? progress.summary
        : AppStrings.longGoalNotLogged;
    EventCategory? category;
    for (final item in widget.categories) {
      if (item.id == goal.categoryId) {
        category = item;
        break;
      }
    }
    final userMemo = goal.memo.trim().replaceAll(RegExp(r'\s+'), ' ');
    final memoParts = [
      if (category != null) summary,
      if (userMemo.isNotEmpty) userMemo,
    ];
    return DayEventLabel(
      title: goal.title,
      categoryName: category?.name ?? summary,
      memo: memoParts.join('  ·  '),
      color: Color(category?.color ?? goal.color),
      completed: store.logOn(goal.id, widget.today)?.value != null,
      trailingText: AppStrings.longGoalPercent(progress.percent),
      disabled: goal.streakBroken(store.logs, widget.today),
      onPressed: onPressed,
    );
  }
}
