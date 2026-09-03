import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/home_widget/compact_day_card.dart';
import 'package:pluto/core/home_widget/month_calendar_card.dart';
import 'package:pluto/core/home_widget/today_widget_card.dart';
import 'package:pluto/core/home_widget/week_timetable_card.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/data/datasources/font_preference.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/presentation/screens/calendar/calendar_day_events.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'export Android widget preview images',
    (tester) async {
    await _loadFonts();
    final out = Directory('android/app/src/main/res/drawable-nodpi');
    out.createSync(recursive: true);

    final today = DateTime(2026, 8, 31);
    final tomorrow = DateTime(2026, 9, 1);
    final todayEvents = [
      _event('자소서', today, 0xFFA78BFA, '취업'),
      _event('면접 준비', today, 0xFF60A5FA, '취업'),
      _event('포트폴리오', today, 0xFFF9A8D4, '할 일'),
    ];
    final tomorrowEvents = [
      _event('면접', tomorrow, 0xFF60A5FA, '취업'),
      _event('스터디', tomorrow, 0xFFA78BFA, '할 일'),
      _event('자소서 첨삭', tomorrow, 0xFFF9A8D4, '할 일'),
    ];
    final monthEvents = _monthEvents();

    await _capture(
      tester,
      out: out,
      name: 'widget_preview_compact_today',
      size: const Size(200, 200),
      child: CompactDayCard(
        title: AppStrings.todayTitle,
        dateLabel: CompactDayCard.monthDayLabel(today),
        events: todayEvents,
        emptyText: AppStrings.summaryNotificationEmpty,
      ),
    );
    await _capture(
      tester,
      out: out,
      name: 'widget_preview_compact_tomorrow',
      size: const Size(200, 200),
      child: CompactDayCard(
        title: AppStrings.tomorrowTitle,
        dateLabel: CompactDayCard.monthDayLabel(tomorrow),
        events: tomorrowEvents,
        emptyText: AppStrings.tomorrowNotificationEmpty,
      ),
    );
    await _capture(
      tester,
      out: out,
      name: 'widget_preview_today',
      size: const Size(280, 280),
      child: _ListPreview(
        title: AppStrings.todayTitle,
        dateLabel: '8. 31. (월)',
        events: todayEvents,
      ),
    );
    await _capture(
      tester,
      out: out,
      name: 'widget_preview_tomorrow',
      size: const Size(280, 280),
      child: _ListPreview(
        title: AppStrings.tomorrowTitle,
        dateLabel: '9. 1. (화)',
        events: tomorrowEvents,
      ),
    );
    await _capture(
      tester,
      out: out,
      name: 'widget_preview_today_tomorrow',
      size: const Size(280, 280),
      child: _CombinedPreview(
        todayEvents: todayEvents.take(1).toList(),
        tomorrowEvents: tomorrowEvents.take(1).toList(),
      ),
    );

    final weekDays = WeekTimetableCard.weekDaysOn(today);
    await _capture(
      tester,
      out: out,
      name: 'widget_preview_week',
      size: const Size(400, 300),
      child: WeekTimetableCard(
        days: weekDays,
        today: today,
        columns: [
          for (final day in weekDays)
            calendarEventsOn(date: day, events: monthEvents, applications: const []),
        ],
        showTime: false,
      ),
    );
    await _capture(
      tester,
      out: out,
      name: 'widget_preview_month',
      size: MonthCalendarCard.logicalSize,
      pixelRatio: 4,
      child: MonthCalendarCard(
        month: DateTime(2026, 8),
        eventsOf: (date) => calendarEventsOn(
          date: date,
          events: monthEvents,
          applications: const [],
        ),
      ),
    );
  });
}

CalendarEvent _event(
  String title,
  DateTime date,
  int color,
  String category, {
  String? groupId,
  String? id,
}) {
  return CalendarEvent(
    id: id ?? '$title-${date.month}-${date.day}',
    title: title,
    date: date,
    categoryName: category,
    categoryColor: color,
    groupId: groupId,
  );
}

List<CalendarEvent> _monthEvents() {
  const europe = 'europe';
  const picnic = 'picnic';
  return [
    for (var day = 3; day <= 8; day++)
      _event(
        '유럽 여행',
        DateTime(2026, 8, day),
        0xFFF9A8D4,
        '여행',
        groupId: europe,
        id: 'europe-$day',
      ),
    for (var day = 19; day <= 20; day++)
      _event(
        '피크닉',
        DateTime(2026, 8, day),
        0xFFF59E0B,
        '약속',
        groupId: picnic,
        id: 'picnic-$day',
      ),
    _event('점심', DateTime(2026, 8, 2), 0xFF60A5FA, '할 일'),
    _event('카페', DateTime(2026, 8, 2), 0xFFF9A8D4, '약속'),
    _event('은행', DateTime(2026, 8, 11), 0xFF94A3B8, '할 일'),
    _event('넷플릭스', DateTime(2026, 8, 12), 0xFFA78BFA, '여가'),
    _event('미팅', DateTime(2026, 8, 16), 0xFFF59E0B, '약속'),
    _event('박물관', DateTime(2026, 8, 21), 0xFF94A3B8, '여행'),
    _event('엠티', DateTime(2026, 8, 22), 0xFFA78BFA, '약속'),
    _event('면접', DateTime(2026, 8, 25), 0xFF60A5FA, '취업'),
    _event('영화', DateTime(2026, 8, 28), 0xFFF9A8D4, '여가'),
    _event('제주 여행', DateTime(2026, 8, 30), 0xFF60A5FA, '여행'),
    _event('스터디', DateTime(2026, 8, 31), 0xFFA78BFA, '할 일'),
    _event('카페', DateTime(2026, 9, 1), 0xFFF9A8D4, '약속'),
    _event('점심', DateTime(2026, 9, 2), 0xFF60A5FA, '할 일'),
    _event('영화', DateTime(2026, 9, 4), 0xFFA78BFA, '여가'),
  ];
}

Future<void> _loadFonts() async {
  final loader = FontLoader('Pretendard');
  for (final asset in [
    'assets/fonts/Pretendard-Regular.otf',
    'assets/fonts/Pretendard-Medium.otf',
    'assets/fonts/Pretendard-SemiBold.otf',
    'assets/fonts/Pretendard-Bold.otf',
    'assets/fonts/Pretendard-ExtraBold.otf',
  ]) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

Future<void> _capture(
  WidgetTester tester, {
  required Directory out,
  required String name,
  required Size size,
  required Widget child,
  double pixelRatio = 3,
}) async {
  tester.view.physicalSize = Size(size.width * pixelRatio, size.height * pixelRatio);
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final key = UniqueKey();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: pixelRatio,
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: AppTheme.themed(dark: false),
          child: FontScope(
            typeface: AppTypeface.pretendard,
            todoScale: 1,
            labelScale: 1,
            calendarScale: 1,
            calendarLabelScale: 1,
            child: TickerMode(
              enabled: false,
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: Colors.white,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

class _ListPreview extends StatelessWidget {
  const _ListPreview({
    required this.title,
    required this.dateLabel,
    required this.events,
  });

  final String title;
  final String dateLabel;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: font,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: TextStyle(
              fontFamily: font,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                for (final event in events.take(3))
                  TodayWidgetCard.row(
                    item: TodayWidgetItem.event(event),
                    showTime: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CombinedPreview extends StatelessWidget {
  const _CombinedPreview({
    required this.todayEvents,
    required this.tomorrowEvents,
  });

  final List<CalendarEvent> todayEvents;
  final List<CalendarEvent> tomorrowEvents;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.todayTomorrowTitle,
            style: TextStyle(
              fontFamily: font,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '8. 31. (월) – 9. 1. (화)',
            style: TextStyle(
              fontFamily: font,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.todayTitle,
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          for (final event in todayEvents)
            TodayWidgetCard.row(
              item: TodayWidgetItem.event(event),
              showTime: false,
            ),
          Text(
            AppStrings.tomorrowTitle,
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          for (final event in tomorrowEvents)
            TodayWidgetCard.row(
              item: TodayWidgetItem.event(event),
              showTime: false,
            ),
        ],
      ),
    );
  }
}
