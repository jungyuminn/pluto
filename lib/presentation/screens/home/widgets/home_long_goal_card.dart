import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/swipe_to_delete.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/long_goal.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:job_planner/presentation/screens/home/widgets/long_goal_edit_sheet.dart';
import 'package:job_planner/presentation/screens/home/widgets/long_goal_log_sheet.dart';

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
  String? _draggingId;

  static const _slotAnim = Duration(milliseconds: 240);

  double get _extent => widget.compact ? 60.0 : 62.0;

  @override
  void didUpdateWidget(HomeLongGoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggingId != null) return;
    _goals = List.of(widget.goals);
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
    setState(() {
      _goals = List.of(AppScope.of(context).longGoalStore.goals);
    });
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

  Future<void> _onDragEnded() async {
    final shouldSave = _draggingId != null;
    setState(() => _draggingId = null);
    if (!shouldSave || !mounted) return;
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
            if (_goals.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildList(),
            ],
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
    final height = _goals.length * _extent;
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
              top: i * _extent,
              left: 0,
              right: 0,
              height: _extent,
              child: _tile(_goals[i]),
            ),
        ],
      ),
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
          onDragEnd: (_) => _onDragEnded(),
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
              child: const SizedBox(height: 52, width: double.infinity),
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
