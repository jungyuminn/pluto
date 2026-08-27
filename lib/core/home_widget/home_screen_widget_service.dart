import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/home_widget/today_widget_card.dart';
import 'package:job_planner/core/home_widget/week_timetable_card.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/theme/app_theme.dart';
import 'package:job_planner/data/datasources/calendar_event_local_datasource.dart';
import 'package:job_planner/data/datasources/calendar_preference.dart';
import 'package:job_planner/data/datasources/day_events_view_preference.dart';
import 'package:job_planner/data/datasources/event_category_local_datasource.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:job_planner/data/datasources/home_view_preference.dart';
import 'package:job_planner/data/datasources/job_application_local_datasource.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_day_events.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> homeWidgetInteractiveCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  ui.DartPluginRegistrant.ensureInitialized();
  if (uri?.host == HomeScreenWidgetService.completeHost) {
    await HomeScreenWidgetService.handleInteractiveUri(uri);
    return;
  }
  await HomeScreenWidgetService.handleBackgroundRefresh();
}

class HomeScreenWidgetService {
  HomeScreenWidgetService._();

  static final instance = HomeScreenWidgetService._();

  static const _kinds = <_WidgetKind>[
    _WidgetKind.today,
    _WidgetKind.tomorrow,
    _WidgetKind.todayTomorrow,
  ];
  static const completeHost = 'complete';
  static const refreshHost = 'refresh';
  static const appGroupId = 'group.com.jobplanner.jobPlanner';
  static const skinBackgroundKey = 'widget_skin_bg';
  static const skinBackgroundSize = Size(412, 300);
  static const _iosSmallSize = Size(170, 170);
  static const _iosMediumSize = Size(364, 170);
  static const _iosLargeSize = Size(364, 382);

  CalendarEventLocalDataSource? _events;
  JobApplicationLocalDataSource? _jobs;
  EventCategoryLocalDataSource? _categories;
  ThemePreference? _theme;
  HomeViewPreference? _homeView;
  DayEventsViewPreference? _dayEventsView;
  FontPreference? _font;
  CalendarPreference? _calendar;
  var _syncing = false;
  var _queued = false;

  Future<void> init({
    required CalendarEventLocalDataSource events,
    required JobApplicationLocalDataSource jobs,
    required EventCategoryLocalDataSource categories,
    required ThemePreference theme,
    required HomeViewPreference homeView,
    required DayEventsViewPreference dayEventsView,
    FontPreference? font,
    CalendarPreference? calendar,
  }) async {
    _events = events;
    _jobs = jobs;
    _categories = categories;
    _theme = theme;
    _homeView = homeView;
    _dayEventsView = dayEventsView;
    _font = font;
    _calendar = calendar;
    await _ensureAppGroup();
  }

  static Future<void> handleInteractiveUri(Uri? uri) async {
    if (uri?.host != completeHost) return;
    final id = uri?.queryParameters['id'];
    if (id == null || id.isEmpty) return;
    try {
      await _prepareFromPrefs();
      await HomeScreenWidgetService.instance._toggleCompleted(id);
    } catch (error, stack) {
      debugPrint('Widget complete failed: $error\n$stack');
    }
  }

  static Future<void> handleBackgroundRefresh() async {
    try {
      await _prepareFromPrefs();
      await HomeScreenWidgetService.instance.sync();
    } catch (error, stack) {
      debugPrint('Widget refresh failed: $error\n$stack');
    }
  }

  static Future<void> _prepareFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await HomeScreenWidgetService.instance.init(
      events: CalendarEventLocalDataSource(prefs),
      jobs: JobApplicationLocalDataSource(prefs),
      categories: EventCategoryLocalDataSource(prefs),
      theme: ThemePreference(prefs: prefs),
      homeView: HomeViewPreference(prefs: prefs),
      dayEventsView: DayEventsViewPreference(prefs: prefs),
      font: FontPreference(prefs: prefs),
      calendar: CalendarPreference(prefs: prefs),
    );
  }

  Future<void> _toggleCompleted(String id) async {
    final events = _events;
    if (events == null) return;
    final current = events.fetchAll();
    CalendarEvent? match;
    for (final event in current) {
      if (event.id == id) {
        match = event;
        break;
      }
    }
    if (match == null || match.isJob) return;
    final next = !match.completed;
    final groupId = match.isRepeat ? null : match.groupId;
    await events.saveAll([
      for (final event in current)
        if (event.id == id || (groupId != null && event.groupId == groupId))
          event.copyWith(completed: next)
        else
          event,
    ]);
  }

  Future<void> _ensureAppGroup() async {
    if (kIsWeb || !Platform.isIOS) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  bool get _supported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> sync() async {
    if (!_supported) return;
    if (_syncing) {
      _queued = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _queued = false;
        await _syncOnce();
      } while (_queued);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce() async {
    if (!_supported) return;
    await _ensureAppGroup();
    final events = _events;
    final jobs = _jobs;
    final categories = _categories;
    final theme = _theme;
    final homeView = _homeView;
    final dayEventsView = _dayEventsView;
    if (events == null ||
        jobs == null ||
        categories == null ||
        theme == null ||
        homeView == null ||
        dayEventsView == null) {
      return;
    }

    ui.Image? officeIcon;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final allEvents = events.fetchAll();
      final applications = jobs.fetchAll();
      final categoryList = categories.fetchAll();
      final liveRatio =
          PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 0;
      final pixelRatio = (liveRatio < 2 ? 3.0 : liveRatio).clamp(3.0, 4.0);
      officeIcon = await _loadOfficeIcon();
      await HomeWidget.saveWidgetData<bool>('is_dark', theme.isDark);
      if (Platform.isAndroid) {
        await _renderSkinBackground(
          skin: theme.skin,
          isDark: theme.isDark,
          pixelRatio: pixelRatio,
        );
      }

      for (final kind in _kinds) {
        await _syncKind(
          kind: kind,
          today: today,
          tomorrow: tomorrow,
          allEvents: allEvents,
          applications: applications,
          categories: categoryList,
          compact: homeView.isCompact,
          sortByTime: dayEventsView.sortByTime,
          showTime: dayEventsView.showTime,
          isDark: theme.isDark,
          skin: theme.skin,
          pixelRatio: pixelRatio,
          officeIcon: officeIcon,
        );
      }
      await _syncWeekTimetable(
        today: today,
        allEvents: allEvents,
        applications: applications,
        showTime: dayEventsView.showTime,
        isDark: theme.isDark,
        skin: theme.skin,
        pixelRatio: pixelRatio,
      );
      if (Platform.isIOS) {
        await _syncLockGlance(
          events: calendarEventsOn(
            date: today,
            events: allEvents,
            applications: applications,
          ),
          sortByTime: dayEventsView.sortByTime,
        );
        await HomeWidget.updateWidget(iOSName: 'TodayWidget');
      }
    } catch (error, stack) {
      debugPrint('HomeScreenWidgetService.sync failed: $error\n$stack');
    } finally {
      officeIcon?.dispose();
    }
  }

  Future<void> _syncKind({
    required _WidgetKind kind,
    required DateTime today,
    required DateTime tomorrow,
    required List<CalendarEvent> allEvents,
    required List<JobApplication> applications,
    required List<EventCategory> categories,
    required bool compact,
    required bool sortByTime,
    required bool showTime,
    required bool isDark,
    required AppSkin skin,
    required double pixelRatio,
    required ui.Image? officeIcon,
  }) async {
    final snapshot = switch (kind) {
      _WidgetKind.today => TodayWidgetCard.snapshotFor(
          events: calendarEventsOn(
            date: today,
            events: allEvents,
            applications: applications,
          ),
          categories: categories,
          compact: compact,
          sortByTime: sortByTime,
        ),
      _WidgetKind.tomorrow => TodayWidgetCard.snapshotFor(
          events: calendarEventsOn(
            date: tomorrow,
            events: allEvents,
            applications: applications,
          ),
          categories: categories,
          compact: compact,
          sortByTime: sortByTime,
        ),
      _WidgetKind.todayTomorrow => _combinedSnapshot(
          todayEvents: calendarEventsOn(
            date: today,
            events: allEvents,
            applications: applications,
          ),
          tomorrowEvents: calendarEventsOn(
            date: tomorrow,
            events: allEvents,
            applications: applications,
          ),
          categories: categories,
          compact: compact,
          sortByTime: sortByTime,
        ),
    };
    if (Platform.isIOS) {
      await _syncKindIos(
        kind: kind,
        snapshot: snapshot,
        dateLabel: kind.dateLabel(today, tomorrow),
        showTime: showTime,
        isDark: isDark,
        skin: skin,
        pixelRatio: pixelRatio,
        officeIcon: officeIcon,
      );
    } else {
      final previousCount =
          (await HomeWidget.getWidgetData<int>(kind.rowCountKey)) ?? 0;

      for (var i = 0; i < snapshot.items.length; i++) {
        final item = snapshot.items[i];
        final event = item.event;
        final completable = event != null && !event.isJob;
        await HomeWidget.saveWidgetData<String>(
          kind.rowIdKey(i),
          completable ? event.id : '',
        );
        final size = Size(TodayWidgetCard.cardWidth, item.extent);
        await HomeWidget.renderFlutterWidget(
          _wrapTheme(
            isDark: isDark,
            size: size,
            pixelRatio: pixelRatio,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: TodayWidgetCard.row(
                item: item,
                showTime: showTime,
                officeIcon: officeIcon,
              ),
            ),
          ),
          key: kind.rowKey(i),
          logicalSize: size,
          pixelRatio: pixelRatio,
        );
      }
      for (var i = snapshot.items.length; i < previousCount; i++) {
        await HomeWidget.saveWidgetData(kind.rowKey(i), null);
        await HomeWidget.saveWidgetData(kind.rowIdKey(i), null);
      }
    }

    await HomeWidget.saveWidgetData<String>(kind.titleKey, kind.title);
    await HomeWidget.saveWidgetData<String>(
      kind.dateKey,
      kind.dateLabel(today, tomorrow),
    );
    await HomeWidget.saveWidgetData<String>(kind.emptyKey, kind.emptyText);
    await HomeWidget.saveWidgetData<int>(
      kind.rowCountKey,
      snapshot.items.length,
    );
    await HomeWidget.updateWidget(
      name: kind.androidName,
      androidName: kind.androidName,
      iOSName: kind.iOSName,
      qualifiedAndroidName: kind.qualifiedAndroidName,
    );
  }

  Future<void> _syncKindIos({
    required _WidgetKind kind,
    required TodayWidgetSnapshot snapshot,
    required String dateLabel,
    required bool showTime,
    required bool isDark,
    required AppSkin skin,
    required double pixelRatio,
    required ui.Image? officeIcon,
  }) async {
    const sizes = <String, Size>{
      'small': _iosSmallSize,
      'medium': _iosMediumSize,
      'large': _iosLargeSize,
    };
    for (final entry in sizes.entries) {
      final size = entry.value;
      await HomeWidget.renderFlutterWidget(
        _wrapTheme(
          isDark: isDark,
          size: size,
          pixelRatio: pixelRatio,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: _iosFillCard(
              skin: skin,
              title: kind.title,
              dateLabel: dateLabel,
              emptyText: kind.emptyText,
              snapshot: snapshot,
              showTime: showTime,
              officeIcon: officeIcon,
            ),
          ),
        ),
        key: kind.imageKey(entry.key),
        logicalSize: size,
        pixelRatio: pixelRatio,
      );
    }
  }

  Future<void> _syncLockGlance({
    required List<CalendarEvent> events,
    required bool sortByTime,
  }) async {
    final ordered = sortByTime
        ? CalendarEvent.withLockedThenStartTime(events)
        : events;
    final open = [for (final event in ordered) if (!event.completed) event];
    final total = events.length;
    final remaining = open.length;
    CalendarEvent? at(int index) =>
        index < open.length ? open[index] : null;
    String timeOf(CalendarEvent event) => event.timeLabel ?? '';
    final first = at(0);
    final inline = remaining == 0
        ? (total == 0 ? AppStrings.summaryNotificationEmpty : '오늘 일정 끝')
        : (first != null && timeOf(first).isNotEmpty
            ? '${timeOf(first)} ${first.title}'
            : '오늘 할 일 $remaining개');
    await HomeWidget.saveWidgetData<int>('lock_total', total);
    await HomeWidget.saveWidgetData<int>('lock_remaining', remaining);
    for (var i = 0; i < 3; i++) {
      final event = at(i);
      await HomeWidget.saveWidgetData<String>(
        'lock_item_${i}_title',
        event?.title ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'lock_item_${i}_time',
        event == null ? '' : timeOf(event),
      );
      await HomeWidget.saveWidgetData<int>(
        'lock_item_${i}_color',
        event?.categoryColor ?? 0,
      );
    }
    await HomeWidget.saveWidgetData<String>('lock_inline', inline);
  }

  Future<void> _syncWeekTimetable({
    required DateTime today,
    required List<CalendarEvent> allEvents,
    required List<JobApplication> applications,
    required bool showTime,
    required bool isDark,
    required AppSkin skin,
    required double pixelRatio,
  }) async {
    final days = WeekTimetableCard.weekDaysOn(
      today,
      startMonday: _calendar?.startMonday ?? false,
    );
    final columns = [
      for (final day in days)
        calendarEventsOn(
          date: day,
          events: allEvents,
          applications: applications,
        ),
    ];
    Future<void> render(Size size, String key) {
      return HomeWidget.renderFlutterWidget(
        _wrapTheme(
          isDark: isDark,
          size: size,
          pixelRatio: pixelRatio,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: _skinCard(
              skin: skin,
              clip: !Platform.isIOS,
              child: WeekTimetableCard(
                days: days,
                today: today,
                columns: columns,
                showTime: showTime,
              ),
            ),
          ),
        ),
        key: key,
        logicalSize: size,
        pixelRatio: pixelRatio,
      );
    }

    if (Platform.isIOS) {
      await render(_iosMediumSize, 'week_timetable_image_medium');
      await render(_iosLargeSize, 'week_timetable_image_large');
    }
    await render(WeekTimetableCard.logicalSize, WeekTimetableCard.imageKey);
    await HomeWidget.saveWidgetData<String>(
      WeekTimetableCard.emptyKey,
      AppStrings.weekNotificationEmpty,
    );
    await HomeWidget.updateWidget(
      name: WeekTimetableCard.androidName,
      androidName: WeekTimetableCard.androidName,
      iOSName: WeekTimetableCard.iOSName,
      qualifiedAndroidName: WeekTimetableCard.qualifiedAndroidName,
    );
  }

  TodayWidgetSnapshot _combinedSnapshot({
    required List<CalendarEvent> todayEvents,
    required List<CalendarEvent> tomorrowEvents,
    required List<EventCategory> categories,
    required bool compact,
    required bool sortByTime,
  }) {
    const dayColor = Color(0xFF3B82F6);
    final todayItems = TodayWidgetCard.snapshotFor(
      events: todayEvents,
      categories: categories,
      compact: compact,
      sortByTime: sortByTime,
    ).items;
    final tomorrowItems = TodayWidgetCard.snapshotFor(
      events: tomorrowEvents,
      categories: categories,
      compact: compact,
      sortByTime: sortByTime,
    ).items;
    final items = <TodayWidgetItem>[];
    if (todayItems.isNotEmpty) {
      items.add(
        const TodayWidgetItem.header(
          name: AppStrings.todayTitle,
          color: dayColor,
          showDot: false,
        ),
      );
      items.addAll(todayItems);
    }
    if (tomorrowItems.isNotEmpty) {
      items.add(
        TodayWidgetItem.header(
          name: AppStrings.tomorrowTitle,
          color: dayColor,
          showTopGap: items.isNotEmpty,
          showDot: false,
        ),
      );
      items.addAll(tomorrowItems);
    }
    while (items.length > TodayWidgetCard.maxEvents) {
      items.removeLast();
    }
    while (items.isNotEmpty && items.last.event == null) {
      items.removeLast();
    }
    return TodayWidgetSnapshot(items: items, moreCount: 0);
  }

  Future<void> _renderSkinBackground({
    required AppSkin skin,
    required bool isDark,
    required double pixelRatio,
  }) async {
    const size = skinBackgroundSize;
    await HomeWidget.renderFlutterWidget(
      _wrapTheme(
        isDark: isDark,
        size: size,
        pixelRatio: pixelRatio,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: _skinCard(skin: skin),
        ),
      ),
      key: skinBackgroundKey,
      logicalSize: size,
      pixelRatio: pixelRatio,
    );
  }

  Widget _skinCard({
    required AppSkin skin,
    Widget child = const SizedBox.expand(),
    bool clip = true,
  }) {
    Widget painted = Builder(
      builder: (context) {
        return AppSkinBackground(
          skin: skin,
          customTheme: _theme?.customTheme,
          color: AppColors.of(context).card,
          liftForNav: false,
          scaleByWidth: true,
          simple: true,
          child: child,
        );
      },
    );
    if (clip) {
      painted = ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: painted,
      );
    }
    return ColoredBox(
      color: const Color(0x00000000),
      child: painted,
    );
  }

  Widget _iosFillCard({
    required AppSkin skin,
    required String title,
    required String dateLabel,
    required String emptyText,
    required TodayWidgetSnapshot snapshot,
    required bool showTime,
    required ui.Image? officeIcon,
  }) {
    return _skinCard(
      skin: skin,
      clip: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Builder(
          builder: (context) {
            final colors = AppColors.of(context);
            final font = AppFonts.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: TodayWidgetCard.listGap),
                Expanded(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (snapshot.items.isEmpty)
                            Text(
                              emptyText,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                                color: colors.muted,
                              ),
                            )
                          else
                            for (final item in snapshot.items)
                              TodayWidgetCard.row(
                                item: item,
                                showTime: showTime,
                                officeIcon: officeIcon,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _wrapTheme({
    required bool isDark,
    required Size size,
    required double pixelRatio,
    required Widget child,
  }) {
    final font = _font;
    final typeface = font?.typeface ?? AppTypeface.pretendard;
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: pixelRatio,
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: AppTheme.themed(
            dark: isDark,
            typeface: typeface,
            skin: _theme?.skin ?? AppSkin.classic,
            customAccent: _theme?.customTheme?.accentColor,
          ),
          child: FontScope(
            typeface: typeface,
            todoScale: font?.todoScale ?? 1,
            labelScale: font?.labelScale ?? 1,
            calendarScale: font?.calendarScale ?? 1,
            calendarLabelScale: font?.calendarLabelScale ?? 1,
            child: TickerMode(
              enabled: false,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Future<ui.Image?> _loadOfficeIcon() async {
    try {
      final data = await rootBundle.load(AppIcons.officeOutlined);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 40,
        targetHeight: 40,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (error) {
      debugPrint('HomeScreenWidgetService office icon failed: $error');
      return null;
    }
  }
}

enum _WidgetKind { today, tomorrow, todayTomorrow }

extension on _WidgetKind {
  String get id => switch (this) {
        _WidgetKind.today => 'today',
        _WidgetKind.tomorrow => 'tomorrow',
        _WidgetKind.todayTomorrow => 'today_tomorrow',
      };

  String get androidName => switch (this) {
        _WidgetKind.today => 'TodayWidgetProvider',
        _WidgetKind.tomorrow => 'TomorrowWidgetProvider',
        _WidgetKind.todayTomorrow => 'TodayTomorrowWidgetProvider',
      };

  String get qualifiedAndroidName =>
      'com.jobplanner.job_planner.$androidName';

  String get iOSName => switch (this) {
        _WidgetKind.today => 'TodayWidget',
        _WidgetKind.tomorrow => 'TomorrowWidget',
        _WidgetKind.todayTomorrow => 'TodayTomorrowWidget',
      };

  String get title => switch (this) {
        _WidgetKind.today => AppStrings.todayTitle,
        _WidgetKind.tomorrow => AppStrings.tomorrowTitle,
        _WidgetKind.todayTomorrow => AppStrings.todayTomorrowTitle,
      };

  String get emptyText => switch (this) {
        _WidgetKind.today => AppStrings.summaryNotificationEmpty,
        _WidgetKind.tomorrow => AppStrings.tomorrowNotificationEmpty,
        _WidgetKind.todayTomorrow => AppStrings.todayTomorrowNotificationEmpty,
      };

  String get titleKey => '${id}_title';
  String get dateKey => '${id}_date';
  String get emptyKey => '${id}_empty';
  String get rowCountKey => '${id}_row_count';
  String rowKey(int index) => '${id}_row_$index';
  String rowIdKey(int index) => '${id}_row_${index}_id';
  String imageKey(String family) => '${id}_image_$family';

  String dateLabel(DateTime todayDate, DateTime tomorrowDate) {
    String labeled(DateTime day) {
      final weekday = AppStrings.weekdays[day.weekday % 7];
      return '${day.month}. ${day.day}. ($weekday)';
    }

    return switch (this) {
      _WidgetKind.today => labeled(todayDate),
      _WidgetKind.tomorrow => labeled(tomorrowDate),
      _WidgetKind.todayTomorrow =>
        '${labeled(todayDate)} – ${labeled(tomorrowDate)}',
    };
  }
}
