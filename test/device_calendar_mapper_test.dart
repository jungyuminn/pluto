import 'package:flutter_test/flutter_test.dart';
import 'package:pluto/data/datasources/device_calendar_mapper.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_category.dart';

void main() {
  final category = EventCategory.presets.first;
  final now = DateTime(2026, 8, 23, 10);

  test('오늘 이후 일정을 고른 카테고리 할 일로 바꾼다', () {
    final start = DateTime(2026, 8, 24, 14).millisecondsSinceEpoch;
    final end = DateTime(2026, 8, 24, 15).millisecondsSinceEpoch;
    final result = DeviceCalendarMapper.mapToTodos(
      source: [
        DeviceCalendarEvent(
          eventId: '1',
          title: '면접 연습',
          notes: '메모',
          startMillis: start,
          endMillis: end,
        ),
      ],
      category: category,
      existing: const [],
      now: now,
      nowMicros: 1,
    );

    expect(result.events, hasLength(1));
    final event = result.events.single;
    expect(event.title, '면접 연습');
    expect(event.memo, '메모');
    expect(event.categoryId, category.id);
    expect(event.categoryName, category.name);
    expect(event.isJob, isFalse);
    expect(event.startMinutes, 14 * 60);
    expect(event.endMinutes, 15 * 60);
  });

  test('같은 제목과 날짜의 할 일은 건너뛴다', () {
    final start = DateTime(2026, 8, 24, 9).millisecondsSinceEpoch;
    final existing = [
      CalendarEvent(id: 'old', title: '면접 연습', date: DateTime(2026, 8, 24)),
    ];
    final result = DeviceCalendarMapper.mapToTodos(
      source: [
        DeviceCalendarEvent(
          eventId: '1',
          title: '면접 연습',
          startMillis: start,
          endMillis: start + 3600000,
        ),
      ],
      category: category,
      existing: existing,
      now: now,
      nowMicros: 1,
    );
    expect(result.events, isEmpty);
  });

  test('지난 일정도 달력 기간 안이면 가져온다', () {
    final start = DateTime(2024, 3, 1, 9).millisecondsSinceEpoch;
    final result = DeviceCalendarMapper.mapToTodos(
      source: [
        DeviceCalendarEvent(
          eventId: '2',
          title: '지난 약속',
          startMillis: start,
          endMillis: start + 3600000,
        ),
      ],
      category: category,
      existing: const [],
      now: now,
      nowMicros: 1,
    );
    expect(result.events, hasLength(1));
    expect(result.events.single.date, DateTime(2024, 3, 1));
  });

  test('생일과 기념일 제목은 가져오지 않는다', () {
    final start = DateTime(2026, 4, 5).millisecondsSinceEpoch;
    final result = DeviceCalendarMapper.mapToTodos(
      source: [
        DeviceCalendarEvent(
          eventId: 'b1',
          title: '해피버스데이',
          startMillis: start,
          endMillis: start + 86400000,
          allDay: true,
        ),
        DeviceCalendarEvent(
          eventId: 'b2',
          title: '생일축하합니다',
          startMillis: start,
          endMillis: start + 86400000,
          allDay: true,
        ),
        DeviceCalendarEvent(
          eventId: 'h1',
          title: '식목일',
          startMillis: start,
          endMillis: start + 86400000,
          allDay: true,
        ),
        DeviceCalendarEvent(
          eventId: 'h2',
          title: '노동절',
          startMillis: DateTime(2026, 5, 1).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 5, 2).millisecondsSinceEpoch,
          allDay: true,
        ),
      ],
      category: category,
      existing: const [],
      now: now,
      nowMicros: 1,
    );
    expect(result.events, isEmpty);
  });

  test('설날·추석·어린이날 같은 공휴일 제목은 가져오지 않는다', () {
    final result = DeviceCalendarMapper.mapToTodos(
      source: [
        DeviceCalendarEvent(
          eventId: 'h3',
          title: '어린이날',
          startMillis: DateTime(2026, 5, 5).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 5, 6).millisecondsSinceEpoch,
          allDay: true,
        ),
        DeviceCalendarEvent(
          eventId: 'h4',
          title: '추석 연휴',
          startMillis: DateTime(2026, 9, 25).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 9, 26).millisecondsSinceEpoch,
          allDay: true,
        ),
        DeviceCalendarEvent(
          eventId: 'h5',
          title: '신정',
          startMillis: DateTime(2026, 1, 1).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 1, 2).millisecondsSinceEpoch,
          allDay: true,
        ),
      ],
      category: category,
      existing: const [],
      now: now,
      nowMicros: 1,
    );
    expect(result.events, isEmpty);
  });

  test('지정한 기간 밖 일정은 가져오지 않는다', () {
    final result = DeviceCalendarMapper.mapToTodos(
      source: [
        DeviceCalendarEvent(
          eventId: 'before',
          title: '지난달 약속',
          startMillis: DateTime(2026, 7, 31, 10).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 7, 31, 11).millisecondsSinceEpoch,
        ),
        DeviceCalendarEvent(
          eventId: 'inside',
          title: '이번 달 약속',
          startMillis: DateTime(2026, 8, 15, 10).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 8, 15, 11).millisecondsSinceEpoch,
        ),
        DeviceCalendarEvent(
          eventId: 'after',
          title: '다음달 약속',
          startMillis: DateTime(2026, 9, 1, 10).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 9, 1, 11).millisecondsSinceEpoch,
        ),
      ],
      category: category,
      existing: const [],
      now: now,
      nowMicros: 1,
      from: DateTime(2026, 8, 1),
      to: DateTime(2026, 8, 31),
    );
    expect(result.events, hasLength(1));
    expect(result.events.single.title, '이번 달 약속');
  });

  test('캘린더마다 다른 카테고리로 넣는다', () {
    final travel = EventCategory.presets[0];
    final exercise = EventCategory.presets[1];
    final result = DeviceCalendarMapper.mapToTodos(
      source: [
        DeviceCalendarEvent(
          eventId: 'a',
          calendarId: 'cal-a',
          title: '출장',
          startMillis: DateTime(2026, 8, 24, 10).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 8, 24, 11).millisecondsSinceEpoch,
        ),
        DeviceCalendarEvent(
          eventId: 'b',
          calendarId: 'cal-b',
          title: '헬스',
          startMillis: DateTime(2026, 8, 25, 10).millisecondsSinceEpoch,
          endMillis: DateTime(2026, 8, 25, 11).millisecondsSinceEpoch,
        ),
      ],
      category: category,
      categoryByCalendarId: {'cal-a': travel, 'cal-b': exercise},
      existing: const [],
      now: now,
      nowMicros: 1,
    );
    expect(result.events, hasLength(2));
    expect(result.events[0].categoryId, travel.id);
    expect(result.events[1].categoryId, exercise.id);
  });

  test('이미 가져온 공휴일 할 일 id를 골라낸다', () {
    final ids = DeviceCalendarMapper.importedObservanceIds([
      CalendarEvent(
        id: 'import_1_20260505',
        title: '어린이날',
        date: DateTime(2026, 5, 5),
      ),
      CalendarEvent(id: 'mine', title: '면접 연습', date: DateTime(2026, 5, 5)),
    ]);
    expect(ids, ['import_1_20260505']);
  });
}
