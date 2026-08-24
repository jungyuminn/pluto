import 'package:job_planner/core/calendar/calendar_years.dart';
import 'package:job_planner/core/calendar/korean_holidays.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';

class DeviceCalendarInfo {
  const DeviceCalendarInfo({
    required this.id,
    required this.name,
    this.accountName = '',
    this.eventCount = 0,
  });

  final String id;
  final String name;
  final String accountName;
  final int eventCount;

  factory DeviceCalendarInfo.fromMap(Map<dynamic, dynamic> map) {
    return DeviceCalendarInfo(
      id: '${map['id'] ?? ''}',
      name: '${map['name'] ?? ''}',
      accountName: '${map['accountName'] ?? ''}',
      eventCount: (map['eventCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeviceCalendarEvent {
  const DeviceCalendarEvent({
    required this.eventId,
    this.calendarId = '',
    required this.title,
    this.notes = '',
    required this.startMillis,
    required this.endMillis,
    this.allDay = false,
  });

  final String eventId;
  final String calendarId;
  final String title;
  final String notes;
  final int startMillis;
  final int endMillis;
  final bool allDay;

  factory DeviceCalendarEvent.fromMap(Map<dynamic, dynamic> map) {
    return DeviceCalendarEvent(
      eventId: '${map['eventId'] ?? ''}',
      calendarId: '${map['calendarId'] ?? ''}',
      title: '${map['title'] ?? ''}'.trim(),
      notes: '${map['notes'] ?? ''}',
      startMillis: (map['startMillis'] as num?)?.toInt() ?? 0,
      endMillis: (map['endMillis'] as num?)?.toInt() ?? 0,
      allDay: map['allDay'] == true,
    );
  }
}

class DeviceCalendarImportResult {
  const DeviceCalendarImportResult({
    required this.events,
    this.truncated = false,
  });

  final List<CalendarEvent> events;
  final bool truncated;
}

abstract final class DeviceCalendarMapper {
  static const idPrefix = 'import_';
  static const maxEvents = 3000;

  static String eventIdFor({required String eventId, required DateTime day}) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$idPrefix${eventId}_${day.year}$month$date';
  }

  static String titleDayKey(String title, DateTime day) {
    return '${title.trim()}|${day.year}-${day.month}-${day.day}';
  }

  static DeviceCalendarImportResult mapToTodos({
    required List<DeviceCalendarEvent> source,
    required EventCategory category,
    Map<String, EventCategory>? categoryByCalendarId,
    required Iterable<CalendarEvent> existing,
    DateTime? now,
    DateTime? from,
    DateTime? to,
    int? nowMicros,
  }) {
    final current = now ?? DateTime.now();
    final boundsStart = CalendarYears.start();
    final boundsEnd = DateTime(CalendarYears.max(current), 12, 31);
    var windowStart = _dayOnly(from) ?? boundsStart;
    var windowEnd = _dayOnly(to) ?? boundsEnd;
    if (windowStart.isBefore(boundsStart)) windowStart = boundsStart;
    if (windowEnd.isAfter(boundsEnd)) windowEnd = boundsEnd;
    if (windowEnd.isBefore(windowStart)) {
      final swap = windowStart;
      windowStart = windowEnd;
      windowEnd = swap;
    }
    final stamp = nowMicros ?? DateTime.now().microsecondsSinceEpoch;
    final existingIds = {for (final event in existing) event.id};
    final existingKeys = {
      for (final event in existing)
        if (!event.isJob) titleDayKey(event.title, event.day),
    };
    final counts = <String, int>{};
    for (final item in source) {
      counts[item.eventId] = (counts[item.eventId] ?? 0) + 1;
    }

    final events = <CalendarEvent>[];
    var truncated = false;
    var index = 0;
    for (final item in source) {
      if (item.title.isEmpty) continue;
      if (isObservanceTitle(item.title)) continue;
      final EventCategory chosen;
      if (categoryByCalendarId != null) {
        final mapped = categoryByCalendarId[item.calendarId];
        if (mapped == null) continue;
        chosen = mapped;
      } else {
        chosen = category;
      }
      final days = _daysOf(item, windowStart, windowEnd);
      if (days.isEmpty) continue;
      final repeatId = (counts[item.eventId] ?? 0) > 1
          ? '${idPrefix}r_${item.eventId}'
          : null;
      final groupId = days.length > 1
          ? '${idPrefix}g_${item.eventId}_${_dayStamp(days.first)}'
          : null;
      final timed = !item.allDay && days.length == 1;
      final startMinutes = timed ? _minutesOf(_local(item.startMillis)) : null;
      final endMinutes = timed ? _endMinutesOf(item) : null;
      for (final day in days) {
        if (events.length >= maxEvents) {
          truncated = true;
          break;
        }
        final id = eventIdFor(eventId: item.eventId, day: day);
        final key = titleDayKey(item.title, day);
        if (existingIds.contains(id) || existingKeys.contains(key)) continue;
        if (isObservanceTitle(item.title, day)) continue;
        existingIds.add(id);
        existingKeys.add(key);
        events.add(
          CalendarEvent(
            id: id,
            title: item.title,
            date: day,
            memo: item.notes.trim(),
            categoryId: chosen.id,
            categoryName: chosen.name,
            categoryColor: chosen.color,
            groupId: groupId,
            repeatId: repeatId,
            sortOrder: stamp + index,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
          ),
        );
        index++;
      }
      if (truncated) break;
    }
    return DeviceCalendarImportResult(events: events, truncated: truncated);
  }

  static List<String> importedObservanceIds(Iterable<CalendarEvent> existing) {
    return [
      for (final event in existing)
        if (!event.isJob &&
            event.id.startsWith(idPrefix) &&
            isObservanceTitle(event.title, event.day))
          event.id,
    ];
  }

  static bool isObservanceTitle(String title, [DateTime? day]) {
    final compact = _compactTitle(title).replaceAll(RegExp(r'\(.*?\)'), '');
    if (compact.isEmpty) return false;
    if (_observanceWords.any(compact.contains)) return true;
    if (day == null) return false;
    final holiday = KoreanHolidays.nameOn(day);
    if (holiday == null) return false;
    final name = _compactTitle(holiday);
    if (name.isEmpty) return false;
    return compact.contains(name) || name.contains(compact);
  }

  static const _observanceWords = [
    '생일',
    '생신',
    'birthday',
    '해피버스데이',
    'happybirthday',
    '생일축하',
    '식목일',
    '노동절',
    '근로자의날',
    '어버이날',
    '스승의날',
    '성년의날',
    '발렌타인',
    '밸런타인',
    '화이트데이',
    '빼빼로데이',
    '할로윈',
    '신정',
    '설날',
    '삼일절',
    '어린이날',
    '석가탄신일',
    '부처님오신날',
    '현충일',
    '광복절',
    '추석',
    '개천절',
    '한글날',
    '크리스마스',
    '기독탄신일',
    '대체공휴일',
    '임시공휴일',
    '공휴일',
    'holiday',
    'christmas',
    'newyear',
    'liberationday',
    'childrensday',
    'memorialday',
    'arborday',
    'laborday',
  ];

  static String _compactTitle(String title) =>
      title.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static List<DateTime> _daysOf(
    DeviceCalendarEvent item,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    if (item.allDay) {
      final start = _utcDay(item.startMillis);
      var end = _utcDay(item.endMillis);
      if (!end.isAfter(start)) end = start.add(const Duration(days: 1));
      final days = <DateTime>[];
      var current = start.isBefore(windowStart) ? windowStart : start;
      while (current.isBefore(end) && !current.isAfter(windowEnd)) {
        days.add(current);
        current = current.add(const Duration(days: 1));
      }
      return days;
    }

    final start = _local(item.startMillis);
    final day = DateTime(start.year, start.month, start.day);
    if (day.isBefore(windowStart) || day.isAfter(windowEnd)) return const [];
    return [day];
  }

  static DateTime? _dayOnly(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _local(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis);

  static DateTime _utcDay(int millis) {
    final utc = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return DateTime(utc.year, utc.month, utc.day);
  }

  static String _dayStamp(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}$month$date';
  }

  static int _minutesOf(DateTime time) =>
      (time.hour * 60 + time.minute).clamp(0, 24 * 60 - 1);

  static int _endMinutesOf(DeviceCalendarEvent item) {
    final start = _local(item.startMillis);
    final end = _local(item.endMillis);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (endDay != startDay) return 24 * 60 - 1;
    final minutes = _minutesOf(end);
    final startMinutes = _minutesOf(start);
    if (minutes <= startMinutes) {
      return (startMinutes + 30).clamp(0, 24 * 60 - 1);
    }
    return minutes;
  }
}
