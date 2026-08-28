import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/korean_search.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/app_backup_service.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/delete_event_dialog.dart';

class HomeAllEventsCard extends StatelessWidget {
  const HomeAllEventsCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
        pressedColor: Color.lerp(colors.card, Colors.black, 0.08)!,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.allEventsCard,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: colors.accentBright,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: colors.accentBright,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final _search = PlainTextEditingController();
  final _searchFocus = FocusNode();
  var _events = <CalendarEvent>[];
  var _categories = <EventCategory>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final categories = await scope.getEventCategories();
    if (!mounted) return;
    setState(() {
      _events = [
        for (final event in events)
          if (!event.isJob) event,
      ]..sort((a, b) {
          final byDay = a.day.compareTo(b.day);
          if (byDay != 0) return byDay;
          return (a.startMinutes ?? 24 * 60).compareTo(b.startMinutes ?? 24 * 60);
        });
      _categories = categories;
      _loading = false;
    });
  }

  List<CalendarEvent> get _filtered {
    final query = _search.text;
    if (KoreanSearch.compact(query).isEmpty) return _events;
    return [
      for (final event in _events)
        if (KoreanSearch.matchesAny(
          [
            event.title,
            event.categoryName,
            event.memo,
            _eventDateLabel(event),
          ],
          query,
        ))
          event,
    ];
  }

  String _eventDateLabel(CalendarEvent event) {
    if (event.someday) return AppStrings.somedayTitle;
    return _dateLabel(event.day);
  }

  String _dateLabel(DateTime date) {
    final weekday = AppStrings.weekdays[date.weekday % 7];
    final now = DateTime.now();
    if (date.year == now.year) {
      return '${date.month}. ${date.day}. ($weekday)';
    }
    return '${date.year}. ${date.month}. ${date.day}. ($weekday)';
  }

  List<_Section> _sections(List<CalendarEvent> events) {
    final groups = <String, List<CalendarEvent>>{};
    for (final event in events) {
      final key = event.categoryId ?? event.categoryName;
      groups.putIfAbsent(key, () => []).add(event);
    }
    final totals = <String, int>{};
    for (final event in _events) {
      final key = event.categoryId ?? event.categoryName;
      totals[key] = (totals[key] ?? 0) + 1;
    }
    final used = <String>{};
    final sections = <_Section>[];
    for (final category in _categories) {
      final grouped = groups[category.id];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(category.id);
      sections.add(
        _Section(
          key: category.id,
          name: category.name,
          color: category.tint,
          events: grouped,
          total: totals[category.id] ?? grouped.length,
        ),
      );
    }
    for (final event in events) {
      final key = event.categoryId ?? event.categoryName;
      if (used.contains(key)) continue;
      final grouped = groups[key];
      if (grouped == null || grouped.isEmpty) continue;
      used.add(key);
      sections.add(
        _Section(
          key: key,
          name: event.categoryName,
          color: event.color,
          events: grouped,
          total: totals[key] ?? grouped.length,
        ),
      );
    }
    return sections;
  }

  Future<void> _edit(CalendarEvent event) async {
    final saved = await showAddEventSheet(
      context,
      date: event.date,
      event: event,
      someday: event.someday,
    );
    if (saved && mounted) await _reload();
  }

  List<CalendarEvent> _eventsInCategory(String key) {
    return [
      for (final event in _events)
        if ((event.categoryId ?? event.categoryName) == key) event,
    ];
  }

  Future<void> _deleteCategory(String key, String name) async {
    final events = _eventsInCategory(key);
    if (events.isEmpty) return;
    final confirmed = await showDeleteEventDialog(
      context,
      title: name,
      body: AppStrings.allEventsDeleteBody(events.length),
    );
    if (!confirmed || !mounted) return;
    await AppScope.of(context).deleteCalendarEvent.many(
      events.map((event) => event.id),
    );
    AppBackupService.revision.value++;
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final filtered = _filtered;
    final sections = _sections(filtered);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 8),
            child: Row(
              children: [
                _BackButton(onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Text(
                  AppStrings.allEventsTitle,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _search,
              focusNode: _searchFocus,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.allEventsSearchHint,
                hintStyle: TextStyle(
                  fontFamily: AppFonts.of(context),
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: colors.card,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.allEventsEmpty,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.muted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 0 : 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: section.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: section.name),
                                              TextSpan(
                                                text: ' ${section.total}',
                                                style: TextStyle(
                                                  color: colors.muted,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          style: TextStyle(
                                            fontFamily: AppFonts.of(context),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.text,
                                          ),
                                        ),
                                      ),
                                      PressBounce(
                                        onPressed: () => _deleteCategory(
                                          section.key,
                                          section.name,
                                        ),
                                        pressedColor: colors.pressed,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            AppStrings.allEventsDeleteAll,
                                            style: TextStyle(
                                              fontFamily: AppFonts.of(context),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: colors.danger,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                for (final event in section.events)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: DayEventLabel(
                                      title: event.title,
                                      categoryName: _eventDateLabel(event),
                                      color: event.color,
                                      completed: event.completed,
                                      isRepeat: event.isRepeat,
                                      isRange: event.isRange,
                                      memo: event.memo,
                                      timeText:
                                          event.someday ? null : event.timeLabel,
                                      onPressed: () => _edit(event),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section({
    required this.key,
    required this.name,
    required this.color,
    required this.events,
    required this.total,
  });

  final String key;
  final String name;
  final Color color;
  final List<CalendarEvent> events;
  final int total;
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

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
          child: Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}
