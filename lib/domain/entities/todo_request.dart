import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/friend_profile.dart';

class TodoRequestItem {
  const TodoRequestItem({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    required this.fromCode,
    required this.toName,
    required this.toCode,
    required this.title,
    required this.date,
    required this.status,
    required this.createdAt,
    this.fromPhotoURL = '',
    this.toPhotoURL = '',
    this.memo = '',
    this.categoryName = CalendarEvent.defaultCategoryName,
    this.categoryColor = CalendarEvent.defaultCategoryColor,
    this.startMinutes,
    this.endMinutes,
    this.fromCompleted = false,
    this.toCompleted = false,
    this.dateMode = 'single',
    this.dates = const [],
    this.fromCompletedDates,
    this.toCompletedDates,
  });

  static const maxDays = 366;

  final String id;
  final String fromUid;
  final String toUid;
  final String fromName;
  final String fromCode;
  final String fromPhotoURL;
  final String toName;
  final String toCode;
  final String toPhotoURL;
  final String title;
  final DateTime date;
  final String memo;
  final String categoryName;
  final int categoryColor;
  final int? startMinutes;
  final int? endMinutes;
  final String status;
  final int createdAt;
  final bool fromCompleted;
  final bool toCompleted;
  final String dateMode;
  final List<DateTime> dates;
  final List<String>? fromCompletedDates;
  final List<String>? toCompletedDates;

  bool get bothCompleted => fromCompleted && toCompleted;

  bool mineCompleted(String uid) {
    if (uid == fromUid) return fromCompleted;
    if (uid == toUid) return toCompleted;
    return false;
  }

  bool peerCompleted(String uid) {
    if (uid == fromUid) return toCompleted;
    if (uid == toUid) return fromCompleted;
    return false;
  }

  bool mineCompletedOn(String uid, DateTime day) {
    return _completedOn(uid, day, mine: true);
  }

  bool peerCompletedOn(String uid, DateTime day) {
    return _completedOn(uid, day, mine: false);
  }

  bool _completedOn(String uid, DateTime day, {required bool mine}) {
    final keys = mine
        ? (uid == fromUid
            ? fromCompletedDates
            : uid == toUid
                ? toCompletedDates
                : null)
        : (uid == fromUid
            ? toCompletedDates
            : uid == toUid
                ? fromCompletedDates
                : null);
    if (keys != null) return keys.contains(dateKey(day));
    return mine ? mineCompleted(uid) : peerCompleted(uid);
  }

  List<String> completedKeys(String uid, {required bool mine}) {
    final stored = mine
        ? (uid == fromUid
            ? fromCompletedDates
            : uid == toUid
                ? toCompletedDates
                : null)
        : (uid == fromUid
            ? toCompletedDates
            : uid == toUid
                ? fromCompletedDates
                : null);
    if (stored != null) return [...stored];
    final done = mine ? mineCompleted(uid) : peerCompleted(uid);
    if (!done) return [];
    return [for (final day in days) dateKey(day)];
  }

  bool get isPending => status == 'pending';

  bool get isAccepted => status == 'accepted';

  bool get isGone =>
      status == 'removed' ||
      status == 'declined' ||
      status == 'cancelled';

  bool get isRangeMode => dateMode == 'range' && days.length >= 2;

  bool get isRepeatMode => dateMode == 'repeat';

  bool get isMultipleMode => dateMode == 'multiple' && days.length >= 2;

  String get fromLabel => fromName.trim().isEmpty ? fromCode : fromName;

  String get toLabel => toName.trim().isEmpty ? toCode : toName;

  FriendProfile get fromProfile => FriendProfile(
        uid: fromUid,
        displayName: fromName,
        friendCode: fromCode,
        photoURL: fromPhotoURL,
      );

  FriendProfile get toProfile => FriendProfile(
        uid: toUid,
        displayName: toName,
        friendCode: toCode,
        photoURL: toPhotoURL,
      );

  DateTime get day => DateTime(date.year, date.month, date.day);

  List<DateTime> get days {
    if (dates.isNotEmpty) return dates;
    return [day];
  }

  String get dateLabel {
    final all = days;
    if (all.length <= 1) {
      return '${date.month}월 ${date.day}일';
    }
    if (isRangeMode) {
      final start = all.first;
      final end = all.last;
      return '${start.month}월 ${start.day}일–${end.month}월 ${end.day}일';
    }
    final first = all.first;
    return '${first.month}월 ${first.day}일 외 ${all.length - 1}일';
  }

  TodoRequestItem copyWithStatus(String status) {
    return TodoRequestItem(
      id: id,
      fromUid: fromUid,
      toUid: toUid,
      fromName: fromName,
      fromCode: fromCode,
      fromPhotoURL: fromPhotoURL,
      toName: toName,
      toCode: toCode,
      toPhotoURL: toPhotoURL,
      title: title,
      date: date,
      memo: memo,
      categoryName: categoryName,
      categoryColor: categoryColor,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      status: status,
      createdAt: createdAt,
      fromCompleted: fromCompleted,
      toCompleted: toCompleted,
      dateMode: dateMode,
      dates: dates,
      fromCompletedDates: fromCompletedDates,
      toCompletedDates: toCompletedDates,
    );
  }

  CalendarEvent toEvent({String? uid, EventCategory? category}) {
    return toEvents(uid: uid, category: category).first;
  }

  List<CalendarEvent> toEvents({
    String? uid,
    EventCategory? category,
    List<CalendarEvent> existing = const [],
  }) {
    final byDay = <String, CalendarEvent>{
      for (final event in existing) dateKey(event.day): event,
    };
    final sample = existing.isEmpty ? null : existing.first;
    final fallback = EventCategory(
      id: sample?.categoryId ?? category?.id ?? '',
      name: sample?.categoryName ?? category?.name ?? categoryName,
      color: sample?.categoryColor ?? category?.color ?? categoryColor,
    );
    final groupId = isRangeMode
        ? (sample?.groupId ?? 'shared_${id}_g')
        : null;
    final repeatId = isRepeatMode
        ? (sample?.repeatId ?? 'shared_${id}_r')
        : null;
    final created = <CalendarEvent>[];
    final all = days;
    for (var i = 0; i < all.length; i++) {
      final day = all[i];
      final prev = byDay[dateKey(day)];
      final mine = uid == null ? false : mineCompletedOn(uid, day);
      final peer = uid == null ? false : peerCompletedOn(uid, day);
      created.add(
        CalendarEvent(
          id: prev?.id ??
              (all.length == 1
                  ? 'shared_$id'
                  : 'shared_${id}_${dateKey(day)}'),
          title: title,
          date: day,
          memo: memo,
          categoryId: prev?.categoryId ?? fallback.id,
          categoryName: prev?.categoryName ?? fallback.name,
          categoryColor: prev?.categoryColor ?? fallback.color,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          sortOrder: prev?.sortOrder ?? createdAt + i,
          groupId: groupId,
          repeatId: repeatId,
          sharedId: id,
          sharedMine: mine,
          sharedPeer: peer,
          completed: mine && peer,
        ),
      );
    }
    return created;
  }

  factory TodoRequestItem.fromMap(String id, Map<String, dynamic> data) {
    final days = parseDates(data);
    return TodoRequestItem(
      id: id,
      fromUid: '${data['fromUid'] ?? ''}',
      toUid: '${data['toUid'] ?? ''}',
      fromName: '${data['fromName'] ?? ''}',
      fromCode: '${data['fromCode'] ?? ''}',
      fromPhotoURL: '${data['fromPhotoURL'] ?? ''}'.trim(),
      toName: '${data['toName'] ?? ''}',
      toCode: '${data['toCode'] ?? ''}',
      toPhotoURL: '${data['toPhotoURL'] ?? ''}'.trim(),
      title: '${data['title'] ?? ''}'.trim(),
      date: days.first,
      memo: '${data['memo'] ?? ''}',
      categoryName: '${data['categoryName'] ?? ''}'.trim().isEmpty
          ? CalendarEvent.defaultCategoryName
          : '${data['categoryName']}'.trim(),
      categoryColor: (data['categoryColor'] as num?)?.toInt() ??
          CalendarEvent.defaultCategoryColor,
      startMinutes: (data['startMinutes'] as num?)?.toInt(),
      endMinutes: (data['endMinutes'] as num?)?.toInt(),
      status: '${data['status'] ?? ''}',
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
      fromCompleted: data['fromCompleted'] == true,
      toCompleted: data['toCompleted'] == true,
      dateMode: parseMode('${data['dateMode'] ?? ''}', days),
      dates: days,
      fromCompletedDates: parseCompletedDates(data['fromCompletedDates']),
      toCompletedDates: parseCompletedDates(data['toCompletedDates']),
    );
  }

  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? parseDay(String raw) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static List<DateTime> parseDates(Map<String, dynamic> data) {
    final primary = parseDay('${data['date'] ?? ''}');
    final seen = <String>{};
    final days = <DateTime>[];
    final raw = data['dates'];
    if (raw is List) {
      for (final item in raw) {
        final day = parseDay('$item');
        if (day == null || !seen.add(dateKey(day))) continue;
        days.add(day);
        if (days.length >= maxDays) break;
      }
    }
    final mode = '${data['dateMode'] ?? ''}'.trim();
    if (mode == 'single' || (mode.isEmpty && days.length <= 1)) {
      final day = primary ?? (days.isEmpty ? DateTime.now() : days.first);
      return [DateTime(day.year, day.month, day.day)];
    }
    if (days.isEmpty) {
      final day = primary ?? DateTime.now();
      return [DateTime(day.year, day.month, day.day)];
    }
    days.sort((a, b) => a.compareTo(b));
    return days;
  }

  static String parseMode(String raw, List<DateTime> days) {
    switch (raw.trim()) {
      case 'range':
      case 'repeat':
      case 'multiple':
      case 'single':
        return raw.trim();
      default:
        return days.length > 1 ? 'multiple' : 'single';
    }
  }

  static List<String>? parseCompletedDates(Object? raw) {
    if (raw is! List) return null;
    final seen = <String>{};
    final keys = <String>[];
    for (final item in raw) {
      final day = parseDay('$item');
      if (day == null || !seen.add(dateKey(day))) continue;
      keys.add(dateKey(day));
    }
    return keys;
  }
}
