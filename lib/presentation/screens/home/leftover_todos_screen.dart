import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_repeat_event_dialog.dart';
import 'package:job_planner/presentation/screens/home/widgets/leftover_todo_card.dart';

class LeftoverTodosScreen extends StatefulWidget {
  const LeftoverTodosScreen({super.key});

  @override
  State<LeftoverTodosScreen> createState() => _LeftoverTodosScreenState();
}

class _LeftoverTodosScreenState extends State<LeftoverTodosScreen> {
  final _listKey = GlobalKey<AnimatedListState>();
  var _events = <CalendarEvent>[];
  var _loading = true;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload({bool popIfEmpty = false}) async {
    final events = await AppScope.of(context).getCalendarEvents();
    if (!mounted) return;
    final next = leftoverTodosBefore(_today, events);
    if (_loading) {
      setState(() {
        _events = next;
        _loading = false;
      });
      if (popIfEmpty && next.isEmpty) Navigator.pop(context);
      return;
    }
    _sync(next);
    if (popIfEmpty && next.isEmpty && mounted) Navigator.pop(context);
  }

  void _sync(List<CalendarEvent> next) {
    final list = _listKey.currentState;
    const duration = Duration(milliseconds: 220);

    for (var i = _events.length - 1; i >= 0; i--) {
      if (next.any((event) => event.id == _events[i].id)) continue;
      final removed = _events.removeAt(i);
      list?.removeItem(
        i,
        (context, animation) => _tile(removed, animation),
        duration: duration,
      );
    }

    for (var i = 0; i < next.length; i++) {
      final event = next[i];
      if (i < _events.length && _events[i].id == event.id) {
        _events[i] = event;
        continue;
      }
      if (_events.any((existing) => existing.id == event.id)) continue;
      _events.insert(i, event);
      list?.insertItem(i, duration: duration);
    }

    setState(() {});
  }

  Future<void> _edit(CalendarEvent event) async {
    final saved = await showAddEventSheet(
      context,
      date: event.date,
      event: event,
    );
    if (saved && mounted) await _reload(popIfEmpty: true);
  }

  Future<void> _toggleComplete(CalendarEvent event) async {
    final updater = AppScope.of(context).updateCalendarEvent;
    final next = event.copyWith(completed: !event.completed);
    if (event.isRepeat) {
      await updater.instance(next);
    } else {
      await updater(next);
    }
    if (mounted) await _reload(popIfEmpty: true);
  }

  Future<void> _completeAll() async {
    final updater = AppScope.of(context).updateCalendarEvent;
    for (final event in List.of(_events)) {
      final next = event.copyWith(completed: true);
      if (event.isRepeat) {
        await updater.instance(next);
      } else {
        await updater(next);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _delete(CalendarEvent event) async {
    if (event.isRepeat) {
      final scope = await showDeleteRepeatEventDialog(context);
      if (scope == null || !mounted) return false;
      final deleter = AppScope.of(context).deleteCalendarEvent;
      switch (scope) {
        case RepeatDeleteScope.thisOnly:
          await deleter.thisOnly(event);
        case RepeatDeleteScope.thisAndAfter:
          await deleter.thisAndAfter(event);
        case RepeatDeleteScope.all:
          await deleter.allRepeats(event.repeatId!);
      }
      if (mounted) await _reload(popIfEmpty: true);
      return true;
    }
    final confirmed = await showDeleteEventDialog(
      context,
      title: event.title,
    );
    if (!confirmed || !mounted) return false;
    await AppScope.of(context).deleteCalendarEvent(event);
    if (mounted) await _reload(popIfEmpty: true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 8),
            child: Row(
              children: [
                _CircleButton(
                  onPressed: () => Navigator.pop(context),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 28,
                    color: colors.text,
                  ),
                ),
                const Spacer(),
                if (_events.isNotEmpty)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PressBounce(
                      onPressed: _completeAll,
                      color: colors.card,
                      pressedColor: colors.pressed,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          AppStrings.completeAll,
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: colors.text,
                ),
                children: [
                  const TextSpan(text: '${AppStrings.leftoverHeadline}\n'),
                  TextSpan(
                    text: AppStrings.leftoverCount(_events.length),
                    style: TextStyle(color: colors.accent),
                  ),
                  const TextSpan(text: ' ${AppStrings.leftoverExists}'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: _events.length,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemBuilder: (context, index, animation) {
                      return _tile(_events[index], animation);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(CalendarEvent event, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return ClipRect(
      child: SizeTransition(
        sizeFactor: curved,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: curved,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LeftoverTodoCard(
              event: event,
              today: _today,
              onEdit: () => _edit(event),
              onComplete: () => _toggleComplete(event),
              onDelete: () => _delete(event),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}
