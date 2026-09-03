import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/constants/release_notes.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/theme/app_theme.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/domain/entities/apply_status.dart';
import 'package:job_planner/domain/entities/calendar_event.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/data/datasources/app_backup_service.dart';
import 'package:job_planner/data/datasources/backup_preference.dart';
import 'package:job_planner/data/datasources/device_calendar_import.dart';
import 'package:job_planner/data/datasources/device_calendar_mapper.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:job_planner/data/datasources/notification_preference.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_month_header.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_weekday_header.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:job_planner/presentation/screens/home/widgets/home_day_card.dart';
import 'package:job_planner/presentation/screens/job/widgets/add_company_button.dart';
import 'package:job_planner/presentation/screens/job/widgets/company_card.dart';
import 'package:job_planner/presentation/screens/job/widgets/job_overflow_menu_button.dart';
import 'package:job_planner/presentation/screens/settings/widgets/backup_dialogs.dart';
import 'package:job_planner/presentation/screens/settings/widgets/calendar_import_dialogs.dart';
import 'package:job_planner/presentation/screens/settings/widgets/calendar_import_wizard.dart';
import 'package:job_planner/presentation/screens/settings/widgets/release_notes_page.dart';
import 'package:job_planner/presentation/screens/settings/widgets/settings_section_help.dart';
import 'package:job_planner/presentation/tutorial/tutorial_controller.dart';
import 'package:job_planner/presentation/widgets/app_back_button.dart';
import 'package:job_planner/presentation/widgets/app_bar_icon_group.dart';
import 'package:job_planner/presentation/widgets/app_bar_wordmark.dart';
import 'package:job_planner/presentation/widgets/overlay_app_bar.dart';
import 'package:job_planner/presentation/widgets/sliding_kind_bar.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _sortByTime = false;
  var _showTime = false;
  var _todoReminderLead = TodoReminderLead.off;
  var _summaryEnabled = true;
  var _summaryHour = NotificationPreference.defaultSummaryMinutes;
  var _leftoverEnabled = true;
  var _leftoverMinutes = NotificationPreference.defaultLeftoverMinutes;
  var _showLeftover = true;
  var _showToday = true;
  var _showTomorrow = true;
  var _showWeek = false;
  var _showMonth = false;
  var _showSomeday = false;
  var _showLongGoal = false;
  var _showMonthlyStats = true;
  var _showWeeklyStats = false;
  var _startMonday = false;
  var _showLunar = false;
  var _dark = false;
  var _skin = AppSkin.classic;
  var _typeface = AppTypeface.pretendard;
  var _followWidgetTheme = true;
  var _followWidgetFont = true;
  var _widgetFontScale = 1.0;
  var _widgetFontSliderOpen = false;
  var _dailyMode = false;
  var _todoSize = FontSizeLevel.medium;
  var _calendarSize = FontSizeLevel.medium;
  var _calendarLabelSize = FontSizeLevel.medium;
  var _autoBackupInterval = AutoBackupInterval.daily;
  var _ready = false;
  var _contactHintVisible = false;
  Timer? _contactHintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final scope = AppScope.of(context);
    _sortByTime = scope.dayEventsViewPreference.sortByTime;
    _showTime = scope.dayEventsViewPreference.showTime;
    _todoReminderLead = scope.notificationPreference.todoReminderLead;
    _summaryEnabled = scope.notificationPreference.summaryEnabled;
    _summaryHour = scope.notificationPreference.summaryMinutes;
    _leftoverEnabled = scope.notificationPreference.leftoverEnabled;
    _leftoverMinutes = scope.notificationPreference.leftoverMinutes;
    _showLeftover = scope.homeViewPreference.showLeftover;
    _showToday = scope.homeViewPreference.showToday;
    _showTomorrow = scope.homeViewPreference.showTomorrow;
    _showWeek = scope.homeViewPreference.showWeek;
    _showMonth = scope.homeViewPreference.showMonth;
    _showSomeday = scope.homeViewPreference.showSomeday;
    _showLongGoal = scope.homeViewPreference.showLongGoal;
    _showMonthlyStats = scope.homeViewPreference.showMonthlyStats;
    _showWeeklyStats = scope.homeViewPreference.showWeeklyStats;
    _startMonday = scope.calendarPreference.startMonday;
    _showLunar = scope.calendarPreference.showLunar;
    _dark = scope.themePreference.isDark;
    _skin = scope.themePreference.skin;
    _typeface = scope.fontPreference.typeface;
    _followWidgetTheme = scope.widgetPreference.followTheme;
    _followWidgetFont = scope.widgetPreference.followFont;
    _widgetFontScale = scope.widgetPreference.fontScale;
    _dailyMode = scope.navPreference.dailyMode;
    _todoSize = scope.fontPreference.todoSize;
    _calendarSize = scope.fontPreference.calendarSize;
    _calendarLabelSize = scope.fontPreference.calendarLabelSize;
    _autoBackupInterval = scope.backupPreference.interval;
  }

  @override
  void dispose() {
    _contactHintTimer?.cancel();
    super.dispose();
  }

  void _syncFromScope() {
    final scope = AppScope.of(context);
    setState(() {
      _sortByTime = scope.dayEventsViewPreference.sortByTime;
      _showTime = scope.dayEventsViewPreference.showTime;
      _todoReminderLead = scope.notificationPreference.todoReminderLead;
      _summaryEnabled = scope.notificationPreference.summaryEnabled;
      _summaryHour = scope.notificationPreference.summaryMinutes;
      _showLeftover = scope.homeViewPreference.showLeftover;
      _showToday = scope.homeViewPreference.showToday;
      _showTomorrow = scope.homeViewPreference.showTomorrow;
      _showWeek = scope.homeViewPreference.showWeek;
      _showMonth = scope.homeViewPreference.showMonth;
      _showSomeday = scope.homeViewPreference.showSomeday;
      _showLongGoal = scope.homeViewPreference.showLongGoal;
      _showMonthlyStats = scope.homeViewPreference.showMonthlyStats;
      _showWeeklyStats = scope.homeViewPreference.showWeeklyStats;
      _startMonday = scope.calendarPreference.startMonday;
      _showLunar = scope.calendarPreference.showLunar;
      _dark = scope.themePreference.isDark;
      _skin = scope.themePreference.skin;
      _typeface = scope.fontPreference.typeface;
      _followWidgetTheme = scope.widgetPreference.followTheme;
      _followWidgetFont = scope.widgetPreference.followFont;
      _widgetFontScale = scope.widgetPreference.fontScale;
      _dailyMode = scope.navPreference.dailyMode;
      _todoSize = scope.fontPreference.todoSize;
      _calendarSize = scope.fontPreference.calendarSize;
      _calendarLabelSize = scope.fontPreference.calendarLabelSize;
      _autoBackupInterval = scope.backupPreference.interval;
    });
  }

  Future<void> _backup() async {
    try {
      final saved = await AppBackupService.backup();
      if (!mounted || !saved) return;
      await AppScope.of(context).backupPreference.markBackedUp();
      if (!mounted) return;
      await showBackupMessageDialog(
        context,
        title: AppStrings.backupSavedTitle,
        body: !kIsWeb && Platform.isIOS
            ? AppStrings.backupSavedBodyIos
            : AppStrings.backupSavedBody,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final iCloud = error.code == 'signed_out' || error.code == 'unavailable';
      await showBackupMessageDialog(
        context,
        title: AppStrings.backupFailedTitle,
        body: iCloud
            ? AppStrings.backupIcloudUnavailableBody
            : AppStrings.backupFailedBody,
      );
    } catch (_) {
      if (!mounted) return;
      await showBackupMessageDialog(
        context,
        title: AppStrings.backupFailedTitle,
        body: AppStrings.backupFailedBody,
      );
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var items = await AppBackupService.listRestoreItems();
      if (AppBackupService.isStarterOnly(prefs)) {
        items = items.where((item) => item.file == null).toList();
      }
      if (!mounted) return;
      if (items.isEmpty) {
        final confirmed = await showRestoreConfirmDialog(context);
        if (!confirmed || !mounted) return;
        final picked = await AppBackupService.restoreFromPicker();
        if (!picked || !mounted) return;
      } else {
        final choice = await showRestoreSourceDialog(context, items);
        if (choice == null || !mounted) return;
        if (choice.pickOther) {
          final picked = await AppBackupService.restoreFromPicker();
          if (!picked || !mounted) return;
        } else {
          await AppBackupService.restoreFromItem(choice.item!);
        }
      }
      if (!mounted) return;
      await AppBackupService.applyToApp(AppScope.of(context));
      if (!mounted) return;
      _syncFromScope();
      await showBackupMessageDialog(
        context,
        title: AppStrings.restoreDoneTitle,
        body: AppStrings.restoreDoneBody,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final iCloud = error.code == 'signed_out' || error.code == 'unavailable';
      await showBackupMessageDialog(
        context,
        title: AppStrings.restoreFailedTitle,
        body: iCloud
            ? AppStrings.backupIcloudUnavailableBody
            : error.code == 'not_icloud'
                ? AppStrings.restoreNotIcloudBody
                : AppStrings.restoreFailedBody,
      );
    } catch (_) {
      if (!mounted) return;
      await showBackupMessageDialog(
        context,
        title: AppStrings.restoreFailedTitle,
        body: AppStrings.restoreFailedBody,
      );
    }
  }

  Future<void> _importSamsungCalendar() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      await showBackupMessageDialog(
        context,
        title: AppStrings.importAndroidOnlyTitle,
        body: AppStrings.importAndroidOnlyBody,
      );
      return;
    }
    await _importDeviceCalendar();
  }

  Future<void> _importIosCalendar() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      await showBackupMessageDialog(
        context,
        title: AppStrings.importIosOnlyTitle,
        body: AppStrings.importIosOnlyBody,
      );
      return;
    }
    await _importDeviceCalendar();
  }

  Future<void> _importDeviceCalendar() async {
    try {
      final permission = await DeviceCalendarImport.requestPermission();
      if (!mounted) return;
      if (permission == DeviceCalendarPermission.unavailable) {
        await showBackupMessageDialog(
          context,
          title: AppStrings.importFailedTitle,
          body: AppStrings.importFailedBody,
        );
        return;
      }
      if (permission == DeviceCalendarPermission.denied) {
        await showBackupMessageDialog(
          context,
          title: AppStrings.importPermissionTitle,
          body: AppStrings.importPermissionBody,
        );
        return;
      }
      if (permission == DeviceCalendarPermission.permanentlyDenied) {
        final open = await showCalendarPermissionDialog(
          context,
          openSettings: true,
        );
        if (open) await DeviceCalendarImport.openSettings();
        return;
      }

      final calendars = await showCalendarImportLoading(
        context,
        DeviceCalendarImport.calendars,
      );
      if (!mounted) return;
      if (calendars.isEmpty) {
        await showBackupMessageDialog(
          context,
          title: AppStrings.importNoCalendarsTitle,
          body: AppStrings.importNoCalendarsBody,
        );
        return;
      }

      final existing = await AppScope.of(context).getCalendarEvents();
      if (!mounted) return;
      final junk = DeviceCalendarMapper.importedObservanceIds(existing);
      if (junk.isNotEmpty) {
        await AppScope.of(context).deleteCalendarEvent.many(junk);
        AppBackupService.revision.value++;
      }
      if (!mounted) return;
      final kept = [
        for (final event in existing)
          if (!junk.contains(event.id)) event,
      ];

      final result = await showCalendarImportWizard(
        context,
        calendars: calendars,
        existing: kept,
      );
      if (result == null || !mounted) return;
      if (result.events.isEmpty) {
        await showBackupMessageDialog(
          context,
          title: junk.isNotEmpty
              ? AppStrings.importDoneTitle
              : AppStrings.importNoEventsTitle,
          body: junk.isNotEmpty
              ? AppStrings.importObservanceSkippedBody
              : AppStrings.importNoEventsBody,
        );
        return;
      }

      await AppScope.of(context).addCalendarEvent.many(result.events);
      AppBackupService.revision.value++;
      if (!mounted) return;
      await showBackupMessageDialog(
        context,
        title: AppStrings.importDoneTitle,
        body: result.truncated
            ? AppStrings.importDonePartialBody(result.events.length)
            : AppStrings.importDoneBody(result.events.length),
      );
    } catch (_) {
      if (!mounted) return;
      await showBackupMessageDialog(
        context,
        title: AppStrings.importFailedTitle,
        body: AppStrings.importFailedBody,
      );
    }
  }

  Future<void> _toggleSortByTime() async {
    final next = !_sortByTime;
    setState(() => _sortByTime = next);
    await AppScope.of(context).dayEventsViewPreference.setSortByTime(next);
  }

  Future<void> _toggleShowTime() async {
    final next = !_showTime;
    setState(() => _showTime = next);
    await AppScope.of(context).dayEventsViewPreference.setShowTime(next);
  }

  Future<void> _setFollowWidgetTheme(bool value) async {
    setState(() => _followWidgetTheme = value);
    await AppScope.of(context).widgetPreference.setFollowTheme(value);
  }

  Future<void> _setFollowWidgetFont(bool value) async {
    setState(() => _followWidgetFont = value);
    await AppScope.of(context).widgetPreference.setFollowFont(value);
  }

  Future<void> _setWidgetFontScale(double value) async {
    setState(() => _widgetFontScale = value);
    await AppScope.of(context).widgetPreference.setFontScale(value);
  }

  Future<void> _setDailyMode(bool value) async {
    setState(() => _dailyMode = value);
    await AppScope.of(context).navPreference.setDailyMode(value);
  }

  Future<void> _setShowLeftover(bool value) async {
    setState(() => _showLeftover = value);
    await AppScope.of(context).homeViewPreference.setShowLeftover(value);
  }

  Future<void> _setShowToday(bool value) async {
    setState(() => _showToday = value);
    await AppScope.of(context).homeViewPreference.setShowToday(value);
  }

  Future<void> _setShowTomorrow(bool value) async {
    setState(() => _showTomorrow = value);
    await AppScope.of(context).homeViewPreference.setShowTomorrow(value);
  }

  Future<void> _setShowWeek(bool value) async {
    setState(() => _showWeek = value);
    await AppScope.of(context).homeViewPreference.setShowWeek(value);
  }

  Future<void> _setShowMonth(bool value) async {
    setState(() => _showMonth = value);
    await AppScope.of(context).homeViewPreference.setShowMonth(value);
  }

  Future<void> _setShowSomeday(bool value) async {
    setState(() => _showSomeday = value);
    await AppScope.of(context).homeViewPreference.setShowSomeday(value);
  }

  Future<void> _setShowLongGoal(bool value) async {
    setState(() => _showLongGoal = value);
    await AppScope.of(context).homeViewPreference.setShowLongGoal(value);
  }

  Future<void> _setShowMonthlyStats(bool value) async {
    setState(() => _showMonthlyStats = value);
    await AppScope.of(context).homeViewPreference.setShowMonthlyStats(value);
  }

  Future<void> _setShowWeeklyStats(bool value) async {
    setState(() => _showWeeklyStats = value);
    await AppScope.of(context).homeViewPreference.setShowWeeklyStats(value);
  }

  Future<void> _setShowLunar(bool value) async {
    setState(() => _showLunar = value);
    await AppScope.of(context).calendarPreference.setShowLunar(value);
  }

  Future<void> _setStartMonday(bool value) async {
    setState(() => _startMonday = value);
    await AppScope.of(context).calendarPreference.setStartMonday(value);
    await HomeScreenWidgetService.instance.sync();
  }

  Future<void> _openThemeSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const _ThemeSettingsPage()),
    );
    if (!mounted) return;
    setState(() {
      _skin = AppScope.of(context).themePreference.skin;
    });
  }

  void _openAppTutorial() {
    final tutorial = TutorialController.of(context);
    Navigator.of(context).pop();
    tutorial.start();
  }

  Future<void> _openAppContact() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppStrings.appContactEmail,
      queryParameters: {
        'subject': AppStrings.appContactSubject,
      },
    );
    try {
      final launched = await launchUrl(uri);
      if (launched || !mounted) return;
    } catch (_) {}
    if (!mounted) return;
    await Clipboard.setData(
      const ClipboardData(text: AppStrings.appContactEmail),
    );
    _contactHintTimer?.cancel();
    setState(() => _contactHintVisible = true);
    _contactHintTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() => _contactHintVisible = false);
    });
  }

  Future<void> _openReleaseNotes() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ReleaseNotesPage()),
    );
  }

  Future<void> _setDark(bool value) async {
    if (_dark == value) return;
    setState(() => _dark = value);
    await AppScope.of(context).themePreference.setDark(value);
    await HomeScreenWidgetService.instance.sync();
  }

  Future<void> _openFontSettings([
    _FontSettingsFocus focus = _FontSettingsFocus.family,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FontSettingsPage(focus: focus),
      ),
    );
    if (!mounted) return;
    setState(() {
      _typeface = AppScope.of(context).fontPreference.typeface;
    });
  }

  Future<void> _openFontSizeSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _FontSizeSettingsPage(),
      ),
    );
    if (!mounted) return;
    final font = AppScope.of(context).fontPreference;
    setState(() {
      _todoSize = font.todoSize;
      _calendarSize = font.calendarSize;
      _calendarLabelSize = font.calendarLabelSize;
    });
  }

  Future<void> _openTodoNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _TodoNotificationSettingsPage(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _todoReminderLead = AppScope.of(
        context,
      ).notificationPreference.todoReminderLead;
    });
  }

  Future<void> _openSummaryNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _SummaryNotificationSettingsPage(),
      ),
    );
    if (!mounted) return;
    final preference = AppScope.of(context).notificationPreference;
    setState(() {
      _summaryEnabled = preference.summaryEnabled;
      _summaryHour = preference.summaryMinutes;
    });
  }

  Future<void> _openLeftoverNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _LeftoverNotificationSettingsPage(),
      ),
    );
    if (!mounted) return;
    final preference = AppScope.of(context).notificationPreference;
    setState(() {
      _leftoverEnabled = preference.leftoverEnabled;
      _leftoverMinutes = preference.leftoverMinutes;
    });
  }

  Future<void> _openAutoBackupSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _AutoBackupSettingsPage(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _autoBackupInterval = AppScope.of(context).backupPreference.interval;
    });
  }

  static String _typefaceLabel(AppTypeface typeface) {
    switch (typeface) {
      case AppTypeface.pretendard:
        return AppStrings.fontPretendard;
      case AppTypeface.paperlogy:
        return AppStrings.fontPaperlogy;
      case AppTypeface.suit:
        return AppStrings.fontSuit;
      case AppTypeface.theJamsil:
        return AppStrings.fontTheJamsil;
      case AppTypeface.system:
        return AppStrings.fontSystem;
      case AppTypeface.gothic:
        return AppStrings.fontGothic;
      case AppTypeface.serif:
        return AppStrings.fontSerif;
      case AppTypeface.ownglyph:
        return AppStrings.fontOwnglyph;
      case AppTypeface.meetme:
        return AppStrings.fontMeetme;
      case AppTypeface.leeSeoyoon:
        return AppStrings.fontLeeSeoyoon;
      case AppTypeface.bandal:
        return AppStrings.fontBandal;
      case AppTypeface.mona:
        return AppStrings.fontMona;
      case AppTypeface.omyu:
        return AppStrings.fontOmyu;
      case AppTypeface.bazzi:
        return AppStrings.fontBazzi;
      case AppTypeface.mabinogi:
        return AppStrings.fontMabinogi;
      case AppTypeface.babyShark:
        return AppStrings.fontBabyShark;
      case AppTypeface.cookieRun:
        return AppStrings.fontCookieRun;
    }
  }

  static String _skinLabel(AppSkin skin) {
    switch (skin) {
      case AppSkin.classic:
        return AppStrings.themeClassic;
      case AppSkin.blossom:
        return AppStrings.themeBlossom;
      case AppSkin.clover:
        return AppStrings.themeClover;
      case AppSkin.fluffyBear:
        return AppStrings.themeFluffyBear;
      case AppSkin.fluffyRabbit:
        return AppStrings.themeFluffyRabbit;
      case AppSkin.pinkHeart:
        return AppStrings.themePinkHeart;
      case AppSkin.summerBeach:
        return AppStrings.themeSummerBeach;
      case AppSkin.snowyWinter:
        return AppStrings.themeSnowyWinter;
      case AppSkin.squishyBear:
        return AppStrings.themeSquishyBear;
      case AppSkin.strawberryMilk:
        return AppStrings.themeStrawberryMilk;
      case AppSkin.lovelyBear:
        return AppStrings.themeLovelyBear;
      case AppSkin.rainyDay:
        return AppStrings.themeRainyDay;
      case AppSkin.concertDay:
        return AppStrings.themeConcertDay;
      case AppSkin.fluffyCloud:
        return AppStrings.themeFluffyCloud;
      case AppSkin.catVillage:
        return AppStrings.themeCatVillage;
      case AppSkin.hamsterBakery:
        return AppStrings.themeHamsterBakery;
      case AppSkin.otterBathhouse:
        return AppStrings.themeOtterBathhouse;
      case AppSkin.rabbitFlowerMarket:
        return AppStrings.themeRabbitFlowerMarket;
      case AppSkin.bearPancakeCafe:
        return AppStrings.themeBearPancakeCafe;
    }
  }

  static String _sizeLabel(FontSizeLevel size) {
    switch (size) {
      case FontSizeLevel.small:
        return AppStrings.fontSizeSmall;
      case FontSizeLevel.medium:
        return AppStrings.fontSizeMedium;
      case FontSizeLevel.large:
        return AppStrings.fontSizeLarge;
      case FontSizeLevel.extraLarge:
        return AppStrings.fontSizeExtraLarge;
    }
  }

  static String _leadLabel(TodoReminderLead lead) {
    switch (lead) {
      case TodoReminderLead.off:
        return AppStrings.notifyOff;
      case TodoReminderLead.minutes5:
        return AppStrings.notifyMinutes5;
      case TodoReminderLead.minutes10:
        return AppStrings.notifyMinutes10;
      case TodoReminderLead.minutes30:
        return AppStrings.notifyMinutes30;
      case TodoReminderLead.hours1:
        return AppStrings.notifyHours1;
    }
  }

  static String _autoBackupLabel(AutoBackupInterval interval) {
    switch (interval) {
      case AutoBackupInterval.off:
        return AppStrings.notifyOff;
      case AutoBackupInterval.daily:
        return AppStrings.autoBackupDaily;
      case AutoBackupInterval.every3Days:
        return AppStrings.autoBackupEvery3Days;
      case AutoBackupInterval.weekly:
        return AppStrings.autoBackupWeekly;
      case AutoBackupInterval.monthly:
        return AppStrings.autoBackupMonthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final contactHint = _contactHintVisible;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.settingsTitle,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
        padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
        children: [
          _SectionLabel(
            AppStrings.settingsThemeSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.theme),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.themeKind,
                value: AppScope.of(context).themePreference.customTheme?.name ??
                    _skinLabel(_skin),
                chevron: true,
                onPressed: _openThemeSettings,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsFontSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.font),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.fontFamily,
                value: _typefaceLabel(_typeface),
                chevron: true,
                onPressed: () => _openFontSettings(),
              ),
              _SettingsTile(
                label: AppStrings.fontLabelScale,
                chevron: true,
                onPressed: () =>
                    _openFontSettings(_FontSettingsFocus.labelScale),
              ),
              _SettingsTile(
                label: AppStrings.fontCalendarChipScale,
                chevron: true,
                onPressed: () =>
                    _openFontSettings(_FontSettingsFocus.calendarChip),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsHomeLayoutSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.homeLayout,
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsSwitchTile(
                label: AppStrings.homeShowLeftover,
                value: _showLeftover,
                onChanged: _setShowLeftover,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowToday,
                value: _showToday,
                onChanged: _setShowToday,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowTomorrow,
                value: _showTomorrow,
                onChanged: _setShowTomorrow,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowWeek,
                value: _showWeek,
                onChanged: _setShowWeek,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowMonth,
                value: _showMonth,
                onChanged: _setShowMonth,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowSomeday,
                value: _showSomeday,
                onChanged: _setShowSomeday,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowLongGoal,
                value: _showLongGoal,
                onChanged: _setShowLongGoal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsCalendarSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.calendar),
          ),
          _SettingsCard(
            children: [
              if (showFontSizeSettings) ...[
                _SettingsTile(
                  label: AppStrings.fontTodoSize,
                  value: _sizeLabel(_todoSize),
                  chevron: true,
                  onPressed: _openFontSizeSettings,
                ),
                _SettingsTile(
                  label: AppStrings.fontCalendarSize,
                  value: _sizeLabel(_calendarSize),
                  chevron: true,
                  onPressed: _openFontSizeSettings,
                ),
                _SettingsTile(
                  label: AppStrings.fontCalendarLabelSize,
                  value: _sizeLabel(_calendarLabelSize),
                  chevron: true,
                  onPressed: _openFontSizeSettings,
                ),
              ],
              _SettingsSwitchTile(
                label: AppStrings.calendarStartMonday,
                value: _startMonday,
                onChanged: _setStartMonday,
              ),
              _SettingsSwitchTile(
                label: AppStrings.calendarShowLunar,
                value: _showLunar,
                onChanged: _setShowLunar,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsNavSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.nav),
          ),
          _SettingsCard(
            children: [
              _SettingsSwitchTile(
                label: AppStrings.dailyMode,
                value: _dailyMode,
                onChanged: _setDailyMode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsTodoSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.todo),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.timeSortView,
                checked: _sortByTime,
                onPressed: _toggleSortByTime,
              ),
              _SettingsTile(
                label: AppStrings.timeDisplay,
                checked: _showTime,
                onPressed: _toggleShowTime,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsNotificationSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.notification,
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.todoNotificationSetting,
                value: _leadLabel(_todoReminderLead),
                chevron: true,
                onPressed: _openTodoNotificationSettings,
              ),
              _SettingsTile(
                label: AppStrings.summaryNotificationSetting,
                value: _summaryEnabled
                    ? AppStrings.summaryTimeLabel(_summaryHour)
                    : AppStrings.notifyOff,
                chevron: true,
                onPressed: _openSummaryNotificationSettings,
              ),
              _SettingsTile(
                label: AppStrings.leftoverNotificationSetting,
                value: _leftoverEnabled
                    ? AppStrings.summaryTimeLabel(_leftoverMinutes)
                    : AppStrings.notifyOff,
                chevron: true,
                onPressed: _openLeftoverNotificationSettings,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsMonthlyStatsSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.monthlyStats,
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsSwitchTile(
                label: AppStrings.homeShowWeeklyStats,
                value: _showWeeklyStats,
                onChanged: _setShowWeeklyStats,
              ),
              _SettingsSwitchTile(
                label: AppStrings.homeShowMonthlyStats,
                value: _showMonthlyStats,
                onChanged: _setShowMonthlyStats,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsAppearanceSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.appearance,
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.lightMode,
                checked: !_dark,
                onPressed: () => _setDark(false),
              ),
              _SettingsTile(
                label: AppStrings.darkMode,
                checked: _dark,
                onPressed: () => _setDark(true),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsBackupSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.backup),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.backupData,
                chevron: true,
                onPressed: _backup,
              ),
              _SettingsTile(
                label: AppStrings.restoreData,
                chevron: true,
                onPressed: _restore,
              ),
              _SettingsTile(
                label: AppStrings.autoBackupSetting,
                value: _autoBackupLabel(_autoBackupInterval),
                chevron: true,
                onPressed: _openAutoBackupSettings,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsCalendarSyncSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.calendarSync,
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.importSamsungCalendar,
                chevron: true,
                onPressed: _importSamsungCalendar,
              ),
              _SettingsTile(
                label: AppStrings.importIosCalendar,
                chevron: true,
                onPressed: _importIosCalendar,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsWidgetSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.widget),
          ),
          _SettingsCard(
            children: [
              _SettingsSwitchTile(
                label: AppStrings.widgetFollowTheme,
                value: _followWidgetTheme,
                onChanged: _setFollowWidgetTheme,
              ),
              _SettingsSwitchTile(
                label: AppStrings.widgetFollowFont,
                value: _followWidgetFont,
                onChanged: _setFollowWidgetFont,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsTile(
                    label: AppStrings.widgetFontSize,
                    chevron: true,
                    expanded: _widgetFontSliderOpen,
                    onPressed: () => setState(
                      () => _widgetFontSliderOpen = !_widgetFontSliderOpen,
                    ),
                  ),
                  _ExpandBelow(
                    open: _widgetFontSliderOpen,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SettingsSliderTile(
                        value: _widgetFontScale,
                        onChanged: _setWidgetFontScale,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsAppSection,
            onHelp: () =>
                showSettingsSectionHelp(context, SettingsHelpSection.app),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.appTutorial,
                chevron: true,
                onPressed: _openAppTutorial,
              ),
              _SettingsTile(
                label: AppStrings.appContact,
                chevron: true,
                onPressed: _openAppContact,
              ),
              _SettingsTile(
                label: AppStrings.releaseNotesTitle,
                value: ReleaseNotes.latestVersion,
                chevron: true,
                onPressed: _openReleaseNotes,
              ),
            ],
          ),
        ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: contactHint ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: contactHint ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: contactHint ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: contactHint ? 1 : 0,
                  child: const _HintToast(text: AppStrings.appContactCopied),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontLivePreview extends StatelessWidget {
  const _FontLivePreview();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: SizedBox(
        height:
            52 * FontPreference.maxScale + 18 * FontPreference.maxScale + 74,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DayEventLabel(
                title: '자기소개서 제출',
                categoryName: '서류',
                color: Color(0xFF3B82F6),
                timeText: '14:00',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final label in AppStrings.weekdays)
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const CalendarEventLabel(
                title: '면접 연습',
                color: Color(0xFF22C55E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _themePreviewToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

const _themePreviewCategories = EventCategory.presets;

List<CalendarEvent> _themePreviewEventsOn(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final today = _themePreviewToday();
  final travel = EventCategory.presets[0];
  final exercise = EventCategory.presets[1];
  final offset = day.difference(today).inDays;
  if (offset == 0) {
    return [
      CalendarEvent(
        id: 'preview-exercise',
        title: '헬스장',
        date: today,
        categoryId: exercise.id,
        categoryName: exercise.name,
        categoryColor: exercise.color,
        startMinutes: 7 * 60,
        endMinutes: 8 * 60,
      ),
    ];
  }
  if (offset == 2) {
    return [
      CalendarEvent(
        id: 'preview-yoga',
        title: '요가',
        date: day,
        categoryId: exercise.id,
        categoryName: exercise.name,
        categoryColor: exercise.color,
        startMinutes: 19 * 60,
        endMinutes: 20 * 60,
      ),
    ];
  }
  if (offset >= 4 && offset <= 6) {
    return [
      CalendarEvent(
        id: 'preview-jeju-$offset',
        title: '제주도',
        date: day,
        groupId: 'preview-jeju',
        categoryId: travel.id,
        categoryName: travel.name,
        categoryColor: travel.color,
      ),
    ];
  }
  return const [];
}

List<JobApplication> _themePreviewJobs() {
  final today = _themePreviewToday();
  return [
    JobApplication(
      id: 'preview-job',
      companyName: AppStrings.appName,
      applyStatus: ApplyStatus.documentSubmitted,
      position: '개발',
      deadline: today.add(const Duration(days: 3)),
      categoryId: 'company_large',
      categoryName: '대기업',
      categoryColor: 0xFF3B82F6,
      rounds: [
        ApplicationRound(name: '서류', date: today.add(const Duration(days: 3))),
        const ApplicationRound(name: '면접'),
      ],
    ),
    JobApplication(
      id: 'preview-job-pass',
      companyName: AppStrings.appName,
      applyStatus: ApplyStatus.finalPassed,
      position: '기획',
      categoryId: 'company_public',
      categoryName: '공기업',
      categoryColor: 0xFF00ACC1,
      rounds: [
        ApplicationRound(name: '입사', date: today.add(const Duration(days: 5))),
      ],
    ),
  ];
}

class _ThemeLivePreview extends StatefulWidget {
  const _ThemeLivePreview({this.customTheme});

  final UserTheme? customTheme;

  @override
  State<_ThemeLivePreview> createState() => _ThemeLivePreviewState();
}

class _ThemeLivePreviewState extends State<_ThemeLivePreview> {
  final _pages = PageController();
  var _page = 0;
  Timer? _timer;

  static const _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _goTo(_page + 1);
    });
  }

  void _goTo(int page, {bool fromUser = false}) {
    final next = page % _pageCount;
    final wrapped = next < 0 ? next + _pageCount : next;
    if (wrapped == _page && _pages.hasClients) {
      if (fromUser) _startTimer();
      return;
    }
    _pages.animateToPage(
      wrapped,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
    if (fromUser) _startTimer();
  }

  Future<void> _openFullPreview() async {
    _timer?.cancel();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppStrings.themeMineFullPreview,
      barrierColor: const Color(0x4D000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ThemeFullPreview(
          customTheme: widget.customTheme,
          initialPage: _page,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.96 + 0.04 * t,
            child: child,
          ),
        );
      },
    );
    if (mounted) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final custom = widget.customTheme;
    Widget preview = AppSkinBackground(
      liftForNav: false,
      scaleByWidth: true,
      animate: true,
      skin: custom == null ? null : AppSkin.classic,
      customTheme: custom,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (page) {
                      setState(() => _page = page);
                      _startTimer();
                    },
                    children: const [
                      _ThemeHomePreviewPage(),
                      _ThemeCalendarPreviewPage(),
                      _ThemeJobPreviewPage(),
                    ],
                  ),
                ),
                _ThemePreviewDots(
                  selected: _page,
                  onSelected: (page) => _goTo(page, fromUser: true),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  child: _ThemePreviewNav(
                    selected: _page,
                    onSelected: (page) => _goTo(page, fromUser: true),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _ThemePreviewIconButton(
              asset: AppIcons.maximizeOutlined,
              label: AppStrings.themeMineFullPreview,
              onPressed: _openFullPreview,
            ),
          ),
        ],
      ),
    );
    if (custom != null) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      preview = Theme(
        data: AppTheme.themed(
          dark: dark,
          typeface: AppScope.of(context).fontPreference.typeface,
          customAccent: custom.accentColor,
        ),
        child: preview,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 280,
          child: preview,
        ),
      ),
    );
  }
}

class _ThemeHomePreviewPage extends StatelessWidget {
  const _ThemeHomePreviewPage({this.full = false});

  final bool full;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.todayTitle,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: full ? 17 : 15,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            Text(
              '8. 21. (금)',
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 8),
            const DayEventLabel(
              title: '헬스장',
              categoryName: '운동',
              color: Color(0xFF7CB342),
              timeText: '07:00',
            ),
            const SizedBox(height: 6),
            const CalendarEventLabel(
              title: '제주도',
              color: Color(0xFF00ACC1),
            ),
          ],
        ),
      ),
    );
    if (!full) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            card,
          ],
        ),
      );
    }
    return _fullHomePage(context);
  }

  Widget _fullHomePage(BuildContext context) {
    final scope = AppScope.of(context);
    final today = _themePreviewToday();
    final compact = scope.homeViewPreference.isCompact;
    final sortPrefs = scope.dayEventsViewPreference;
    final bottomGap = 88 + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: OverlayAppBar(
        title: const AppBarWordmark(slot: WordmarkSlot.home),
        actions: AppBarIconGroup(
          actions: [
            AppBarIconAction(
              asset: AppIcons.search,
              label: AppStrings.homeSearchHint,
              onPressed: () {},
            ),
            AppBarIconAction(
              asset: compact ? AppIcons.detailView : AppIcons.quickView,
              label: compact
                  ? AppStrings.detailedView
                  : AppStrings.compactView,
              onPressed: () {},
            ),
            AppBarIconAction(
              asset: AppIcons.setting,
              label: AppStrings.settingsTitle,
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          OverlayAppBar.overlapOf(context) + 8,
          16,
          bottomGap,
        ),
        children: [
          HomeDayCard(
            title: AppStrings.todayTitle,
            date: today,
            events: _themePreviewEventsOn(today),
            categories: _themePreviewCategories,
            compact: compact,
            sortByTime: sortPrefs.sortByTime,
            showTime: sortPrefs.showTime,
            onEventsChanged: () {},
          ),
        ],
      ),
    );
  }
}

class _ThemeCalendarPreviewPage extends StatelessWidget {
  const _ThemeCalendarPreviewPage({this.full = false});

  final bool full;

  static const _weeks = [
    [2, 3, 4, 5, 6, 7, 8],
    [9, 10, 11, 12, 13, 14, 15],
    [16, 17, 18, 19, 20, 21, 22],
    [23, 24, 25, 26, 27, 28, 29],
  ];

  @override
  Widget build(BuildContext context) {
    if (full) return _fullCalendarPage(context);
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '8${AppStrings.monthSuffix}',
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final label in AppStrings.weekdays)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Column(
              children: [
                for (final week in _weeks)
                  Expanded(
                    child: Row(
                      children: [
                        for (final day in week)
                          Expanded(
                            child: _ThemePreviewDayCell(
                              day: day,
                              today: day == 21,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullCalendarPage(BuildContext context) {
    final scope = AppScope.of(context);
    final today = _themePreviewToday();
    final month = DateTime(today.year, today.month);
    final startMonday = scope.calendarPreference.startMonday;
    final showLunar = scope.calendarPreference.showLunar;
    final calendar = scope.calendarPreference;
    final bottomGap = 72 + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalendarMonthHeader(
                month: month,
                showTodos: calendar.showTodos,
                showCompanies: calendar.showCompanies,
                onSearchPressed: () {},
                tutorial: false,
              ),
              CalendarWeekdayHeader(startMonday: startMonday),
              Expanded(
                child: CalendarMonthGrid(
                  month: month,
                  startMonday: startMonday,
                  showLunar: showLunar,
                  eventsOf: _themePreviewEventsOn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewDayCell extends StatelessWidget {
  const _ThemePreviewDayCell({
    required this.day,
    required this.today,
  });

  final int day;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 11,
            height: 1,
            fontWeight: today ? FontWeight.w800 : FontWeight.w500,
            color: today ? colors.text : colors.muted,
          ),
        ),
      ),
    );
  }
}

class _ThemeJobPreviewPage extends StatelessWidget {
  const _ThemeJobPreviewPage({this.full = false});

  final bool full;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ThemePreviewCompanyCard(
        name: AppStrings.appName,
        dDay: 'D-3',
        status: '서류제출',
        color: const Color(0xFF3B82F6),
      ),
      const SizedBox(height: 8),
      _ThemePreviewCompanyCard(
        name: AppStrings.appName,
        dDay: 'D-5',
        status: '최종합격',
        color: const Color(0xFF00ACC1),
      ),
    ];
    if (!full) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: Column(
          children: [
            const Spacer(),
            ...cards,
          ],
        ),
      );
    }
    return _fullJobPage(context);
  }

  Widget _fullJobPage(BuildContext context) {
    final compact = AppScope.of(context).jobViewPreference.isCompact;
    final jobs = _themePreviewJobs();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: OverlayAppBar(
        title: const AppBarWordmark(slot: WordmarkSlot.job),
        actions: AppBarIconGroup(
          actions: [
            AppBarIconAction(
              asset: AppIcons.search,
              label: AppStrings.searchHint,
              onPressed: () {},
            ),
          ],
          trailing: [
            JobOverflowMenuButton(
              compact: compact,
              onCompactChanged: (_) {},
              showRejected: true,
              onShowRejectedChanged: (_) {},
              sortByTime: false,
              onSortByTimeChanged: (_) {},
              categoryView: false,
              onCategoryViewChanged: (_) {},
              showLicense: false,
              onShowLicenseChanged: (_) {},
              licenseCompact: false,
              onLicenseCompactChanged: (_) {},
              showExpired: true,
              onShowExpiredChanged: (_) {},
              licenseSortByTime: false,
              onLicenseSortByTimeChanged: (_) {},
              licenseCategoryView: false,
              onLicenseCategoryViewChanged: (_) {},
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          OverlayAppBar.overlapOf(context),
          20,
          100,
        ),
        children: [
          CompanyCard(application: jobs[0], compact: compact),
          SizedBox(height: compact ? 8 : 12),
          CompanyCard(application: jobs[1], compact: compact),
          const SizedBox(height: 12),
          const AddCompanyButton(),
        ],
      ),
    );
  }
}

class _ThemePreviewCompanyCard extends StatelessWidget {
  const _ThemePreviewCompanyCard({
    required this.name,
    this.dDay,
    required this.status,
    required this.color,
  });

  final String name;
  final String? dDay;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dDay != null)
              Text(
                dDay!,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.danger,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewDots extends StatelessWidget {
  const _ThemePreviewDots({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          PressBounce(
            onPressed: () => onSelected(i),
            pressedScale: 0.9,
            pressedColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == selected ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == selected ? colors.accentBright : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemePreviewNav extends StatelessWidget {
  const _ThemePreviewNav({
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = AppScope.of(context).themePreference;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final items = AppSkinAssets.navIcons(theme.skin);
        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.navBar,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: 168,
              height: 40,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: PressBounce(
                        onPressed: () => onSelected(i),
                        pressedScale: 0.88,
                        pressedColor: Colors.transparent,
                        child: Center(
                          child: ThemedAsset(
                            asset: i == selected
                                ? items[i].filled
                                : items[i].outlined,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemePreviewIconButton extends StatelessWidget {
  const _ThemePreviewIconButton({
    required this.asset,
    required this.label,
    required this.onPressed,
  });

  final String asset;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(8));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: radius,
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
        borderRadius: radius,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: ThemedAsset(
              asset: asset,
              width: 15,
              height: 15,
              semanticLabel: label,
              forceTint: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeFullPreview extends StatefulWidget {
  const _ThemeFullPreview({
    required this.initialPage,
    this.customTheme,
  });

  final UserTheme? customTheme;
  final int initialPage;

  @override
  State<_ThemeFullPreview> createState() => _ThemeFullPreviewState();
}

class _ThemeFullPreviewState extends State<_ThemeFullPreview> {
  late final PageController _pages;
  late var _page = widget.initialPage;

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final next = page.clamp(0, 2);
    if (next == _page) return;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.customTheme;
    final top = MediaQuery.paddingOf(context).top;
    Widget preview = AppSkinBackground(
      liftForNav: true,
      skin: custom == null ? null : AppSkin.classic,
      customTheme: custom,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            PageView(
              controller: _pages,
              onPageChanged: (page) => setState(() => _page = page),
              children: const [
                IgnorePointer(child: _ThemeHomePreviewPage(full: true)),
                IgnorePointer(child: _ThemeCalendarPreviewPage(full: true)),
                IgnorePointer(child: _ThemeJobPreviewPage(full: true)),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: PillBottomNav(
                currentIndex: _page,
                onChanged: _goTo,
                tutorial: false,
              ),
            ),
            Positioned(
              top: top + 8,
              left: 16,
              child: AppBackButton(
                onPressed: () => Navigator.pop(context),
                size: 36,
                iconSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
    if (custom != null) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      preview = Theme(
        data: AppTheme.themed(
          dark: dark,
          typeface: AppScope.of(context).fontPreference.typeface,
          customAccent: custom.accentColor,
        ),
        child: preview,
      );
    }
    return preview;
  }
}

class _ThemeSettingsPage extends StatefulWidget {
  const _ThemeSettingsPage();

  @override
  State<_ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<_ThemeSettingsPage> {
  AppSkinGroup? _group;
  var _groupDir = 1.0;
  final _scroll = ScrollController();
  final _selectedKey = GlobalKey();
  var _scrolledToSelected = false;
  var _precached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      await _scrollToSelected();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    precacheImage(const AssetImage(AppIcons.editOutlined), context);
    precacheImage(const AssetImage(AppIcons.trashCan), context);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _scrollToSelected({int attempt = 0}) async {
    if (!mounted || _scrolledToSelected) return;
    final target = _selectedKey.currentContext?.findRenderObject();
    if (target == null || !_scroll.hasClients) {
      if (attempt >= 12) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected(attempt: attempt + 1);
      });
      return;
    }
    _scrolledToSelected = true;
    await _scroll.position.ensureVisible(
      target,
      alignment: 0.28,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).themePreference;
    final top = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final colors = AppColors.of(context);
        final group = _group ??
            AppSkin.groupOf(theme.skin, custom: theme.usesCustom);

        return Scaffold(
          backgroundColor: colors.groupedBackground,
          extendBodyBehindAppBar: true,
          appBar: _FrostedAppBar(
            title: AppStrings.settingsThemeSection,
            onBack: () => Navigator.pop(context),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: top + 56),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ThemeLivePreview(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SlidingKindBar(
                  values: AppSkinGroup.values,
                  selected: group,
                  labelOf: _groupLabel,
                  barColor: colors.card,
                  height: 46,
                  accent: theme.usesCustom || theme.skin != AppSkin.classic
                      ? colors.accent
                      : Color.lerp(colors.pressed, Colors.black, 0.06)!,
                  onChanged: (value) {
                    final from = AppSkinGroup.values.indexOf(group);
                    final to = AppSkinGroup.values.indexOf(value);
                    setState(() {
                      _groupDir = to >= from ? 1.0 : -1.0;
                      _group = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        layoutBuilder: (current, _) {
                          return current ?? const SizedBox.shrink();
                        },
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: Offset(_groupDir * 0.12, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(group),
                          child: group == AppSkinGroup.mine
                              ? _MineThemesPanel(
                                  selectedKey: _selectedKey,
                                  onCreate: () => _openEditor(context),
                                  onEdit: (item) =>
                                      _openEditor(context, initial: item),
                                )
                              : _SettingsCard(
                      children: [
                                    for (final skin in group.skins)
                                      KeyedSubtree(
                                        key: theme.skin == skin &&
                                                !theme.usesCustom
                                            ? _selectedKey
                                            : ValueKey(skin),
                                        child: _SettingsTile(
                                          label:
                                              _SettingsScreenState._skinLabel(
                                            skin,
                                          ),
                                          checked: !theme.usesCustom &&
                                              theme.skin == skin,
                            onPressed: () async {
                              await theme.setSkin(skin);
                                            await HomeScreenWidgetService
                                                .instance
                                                .sync();
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _groupLabel(AppSkinGroup group) {
    return switch (group) {
      AppSkinGroup.pattern => AppStrings.themeGroupPattern,
      AppSkinGroup.scene => AppStrings.themeGroupScene,
      AppSkinGroup.mine => AppStrings.themeGroupMine,
    };
  }

  Future<void> _openEditor(
    BuildContext context, {
    UserTheme? initial,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _CustomThemeEditorPage(initial: initial),
      ),
    );
  }
}

class _MineThemesPanel extends StatefulWidget {
  const _MineThemesPanel({
    required this.selectedKey,
    required this.onCreate,
    required this.onEdit,
  });

  final GlobalKey selectedKey;
  final VoidCallback onCreate;
  final ValueChanged<UserTheme> onEdit;

  @override
  State<_MineThemesPanel> createState() => _MineThemesPanelState();
}

class _MineThemesPanelState extends State<_MineThemesPanel> {
  final _openId = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _openId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.of(context).themePreference;
    final colors = AppColors.of(context);
    final items = theme.customThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                _SettingsTile(
                  label: AppStrings.themeMineCreate,
                  chevron: true,
                  onPressed: widget.onCreate,
                ),
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: colors.border,
                    ),
                  ),
                if (items.isNotEmpty)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    itemCount: items.length,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final t = Curves.easeOutBack.transform(
                            animation.value,
                          );
                          return Transform.translate(
                            offset: Offset(0, -4 * t),
                            child: Transform.scale(
                              scale: 1 + 0.02 * t,
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    onReorderStart: (_) {
                      _openId.value = null;
                      HapticFeedback.mediumImpact();
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final next = [...items];
                      final moved = next.removeAt(oldIndex);
                      next.insert(newIndex, moved);
                      theme.reorderCustomThemes(next);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = theme.customTheme?.id == item.id;
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(item.id),
                        index: index,
                        child: Column(
                          children: [
                            if (index > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: colors.border,
                                ),
                              ),
                            Stack(
                              children: [
                                _ThemeSwipeRow(
                                  key: ValueKey('swipe-${item.id}'),
                                  id: item.id,
                                  openId: _openId,
                                  onEdit: () => widget.onEdit(item),
                                  onDelete: () => _confirmDelete(context, item),
                                  child: _SettingsTile(
                                    label: item.name,
                                    checked: selected,
                                    onPressed: () async {
                                      _openId.value = null;
                                      if (selected) {
                                        widget.onEdit(item);
                                        return;
                                      }
                                      await theme.setCustomTheme(item.id);
                                      await HomeScreenWidgetService.instance
                                          .sync();
                                    },
                                  ),
                                ),
                                if (selected)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: KeyedSubtree(
                                        key: widget.selectedKey,
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserTheme item) async {
    _openId.value = null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteCustomThemeDialog(name: item.name),
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.of(context).themePreference.deleteCustomTheme(item.id);
                              await HomeScreenWidgetService.instance.sync();
  }
}

class _ThemeSwipeRow extends StatefulWidget {
  const _ThemeSwipeRow({
    super.key,
    required this.id,
    required this.openId,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  final String id;
  final ValueNotifier<String?> openId;
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _reveal = 120.0;

  @override
  State<_ThemeSwipeRow> createState() => _ThemeSwipeRowState();
}

class _ThemeSwipeRowState extends State<_ThemeSwipeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offset;
  var _swiping = false;
  var _velocity = 0.0;
  Duration _lastMove = Duration.zero;

  @override
  void initState() {
    super.initState();
    _offset = AnimationController(
      vsync: this,
      value: 0,
      lowerBound: -_ThemeSwipeRow._reveal,
      upperBound: 0,
    );
    widget.openId.addListener(_onOpenId);
  }

  @override
  void didUpdateWidget(covariant _ThemeSwipeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openId != widget.openId) {
      oldWidget.openId.removeListener(_onOpenId);
      widget.openId.addListener(_onOpenId);
    }
  }

  @override
  void dispose() {
    widget.openId.removeListener(_onOpenId);
    _offset.dispose();
    super.dispose();
  }

  void _onOpenId() {
    if (widget.openId.value == widget.id) return;
    if (_offset.value == 0) return;
    _offset.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _snapTo(double target) {
    return _offset.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _endSwipe() {
    if (!_swiping) return;
    final open =
        _offset.value < -_ThemeSwipeRow._reveal * 0.36 || _velocity < -500;
    if (open) {
      widget.openId.value = widget.id;
    } else if (widget.openId.value == widget.id) {
      widget.openId.value = null;
    }
    _snapTo(open ? -_ThemeSwipeRow._reveal : 0);
    _swiping = false;
    _velocity = 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRect(
      child: AnimatedBuilder(
        animation: _offset,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: colors.card,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: _ThemeSwipeRow._reveal,
                      child: Row(
                        children: [
                          Expanded(
                            child: _ThemeSwipeAction(
                              asset: AppIcons.editOutlined,
                              color: colors.muted,
                              onPressed: () {
                                widget.openId.value = null;
                                widget.onEdit();
                              },
                            ),
                          ),
                          Expanded(
                            child: _ThemeSwipeAction(
                              asset: AppIcons.trashCan,
                              color: colors.danger,
                              onPressed: () {
                                widget.openId.value = null;
                                widget.onDelete();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Listener(
                onPointerDown: (_) {
                  _swiping = false;
                  _velocity = 0;
                },
                onPointerMove: (event) {
                  final dx = event.delta.dx;
                  final dy = event.delta.dy;
                  if (!_swiping) {
                    if (dx.abs() < 1.2 && dy.abs() < 1.2) return;
                    if (dx.abs() <= dy.abs()) return;
                    _swiping = true;
                    _lastMove = event.timeStamp;
                    widget.openId.value = widget.id;
                  }
                  final dt = (event.timeStamp - _lastMove).inMilliseconds;
                  if (dt > 0) _velocity = dx / dt * 1000;
                  _lastMove = event.timeStamp;
                  _offset.value = (_offset.value + dx).clamp(
                    -_ThemeSwipeRow._reveal,
                    0,
                  );
                },
                onPointerUp: (_) => _endSwipe(),
                onPointerCancel: (_) => _endSwipe(),
                child: Transform.translate(
                  offset: Offset(_offset.value, 0),
                  child: child,
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _ThemeSwipeAction extends StatelessWidget {
  const _ThemeSwipeAction({
    required this.asset,
    required this.color,
    required this.onPressed,
  });

  final String asset;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.9,
      color: Colors.transparent,
      pressedColor: Colors.transparent,
      child: Center(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: Image.asset(
            asset,
            width: 22,
            height: 22,
            cacheWidth: (22 * MediaQuery.devicePixelRatioOf(context)).round(),
            cacheHeight: (22 * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
        ),
      ),
    );
  }
}

class _CustomThemeEditorPage extends StatefulWidget {
  const _CustomThemeEditorPage({this.initial});

  final UserTheme? initial;

  @override
  State<_CustomThemeEditorPage> createState() => _CustomThemeEditorPageState();
}

class _CustomThemeEditorPageState extends State<_CustomThemeEditorPage> {
  late final PlainTextEditingController _name;
  late UserThemeKind _kind;
  var _kindDir = 1.0;
  late int _accent;
  late double _photoWash;
  String? _photoPath;
  String? _photoName;
  String? _decorationPath;
  String? _decorationName;
  String? _bottomPath;
  String? _bottomName;
  var _saving = false;
  var _hintVisible = false;
  Timer? _hintTimer;

  String? get _photoPreview => _photoPath ?? widget.initial?.photoPath;
  String? get _decorationPreview =>
      _decorationPath ?? widget.initial?.decorationPath;
  String? get _bottomPreview => _bottomPath ?? widget.initial?.bottomPath;

  UserTheme get _draft {
    return UserTheme(
      id: widget.initial?.id ?? 'draft',
      name: _name.text,
      kind: _kind,
      accent: _accent,
      photoPath: _photoPreview ?? '',
      decorationPath: _decorationPreview ?? '',
      bottomPath: _bottomPreview ?? '',
      photoWash: _photoWash,
    );
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = PlainTextEditingController(text: initial?.name ?? '');
    _kind = initial?.kind ?? UserThemeKind.pattern;
    _accent = initial?.accent ?? ThemePreference.defaultAccent;
    _photoWash = initial?.photoWash ?? UserTheme.defaultPhotoWash;
    if (initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPatternHint();
      });
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    final path = file?.path;
    if (file == null || path == null) return;
    setState(() {
      _photoPath = path;
      _photoName = file.name;
    });
  }

  Future<void> _pick({required bool decoration}) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    final path = file?.path;
    if (file == null || path == null) return;
    setState(() {
      if (decoration) {
        _decorationPath = path;
        _decorationName = file.name;
      } else {
        _bottomPath = path;
        _bottomName = file.name;
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.themeMineMissingName,
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).themePreference.saveCustomTheme(
        name: name,
        kind: _kind,
        accent: _accent,
        photoWash: _photoWash,
        photoSource: _photoPreview,
        photoName: _photoName ?? _photoPreview,
        decorationSource: _decorationPreview,
        decorationName: _decorationName ?? _decorationPreview,
        bottomSource: _bottomPreview,
        bottomName: _bottomName ?? _bottomPreview,
        editing: widget.initial,
      );
      await HomeScreenWidgetService.instance.sync();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (initial == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteCustomThemeDialog(name: initial.name),
    );
    if (confirmed != true || !mounted) return;
    await AppScope.of(context).themePreference.deleteCustomTheme(initial.id);
    await HomeScreenWidgetService.instance.sync();
    if (mounted) Navigator.pop(context);
  }

  void _showPatternHint() {
    _hintTimer?.cancel();
    setState(() => _hintVisible = true);
    _hintTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = Color(_accent);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: widget.initial == null
            ? AppStrings.themeMineCreate
            : AppStrings.themeMineEdit,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: top + 56),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ThemeLivePreview(customTheme: _draft),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SlidingKindBar(
                  values: const [
                    UserThemeKind.pattern,
                    UserThemeKind.photo,
                  ],
                  selected: _kind,
                  labelOf: (kind) => switch (kind) {
                    UserThemeKind.photo => AppStrings.themeMineKindPhoto,
                    UserThemeKind.pattern => AppStrings.themeMineKindPattern,
                  },
                  barColor: colors.card,
                  height: 46,
                  accent: Color.lerp(colors.pressed, Colors.black, 0.06)!,
                  onChanged: (value) {
                    setState(() {
                      final from = _kind == UserThemeKind.pattern ? 0 : 1;
                      final to = value == UserThemeKind.pattern ? 0 : 1;
                      _kindDir = to >= from ? 1.0 : -1.0;
                      _kind = value;
                    });
                    if (value == UserThemeKind.pattern) {
                      _showPatternHint();
                    } else {
                      _hintTimer?.cancel();
                      setState(() => _hintVisible = false);
                    }
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24 + bottom + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  children: [
              TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            tween: ColorTween(end: accent),
            builder: (context, color, _) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _name,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: colors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.themeMineNameHint,
                        hintStyle: TextStyle(
                          fontFamily: AppFonts.of(context),
                          color: colors.hint,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        layoutBuilder: (current, _) {
                          return current ?? const SizedBox.shrink();
                        },
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: Offset(_kindDir * 0.12, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_kind),
                          child: _kind == UserThemeKind.photo
                              ? Column(
                                  children: [
                                    _ThemeImageWell(
                                      label: AppStrings.themeMinePhoto,
                                      path: _photoPreview,
                                      height: 168,
                                      onPressed: _pickPhoto,
                                    ),
                                    const SizedBox(height: 12),
                                    _WashSlider(
                                      label: AppStrings.themeMinePhotoWash,
                                      value: _photoWash,
                                      color: color ?? accent,
                                      onChanged: (value) =>
                                          setState(() => _photoWash = value),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _ThemeImageWell(
                                      label: AppStrings.themeMineDecoration,
                                      path: _decorationPreview,
                                      height: 120,
                                      onPressed: () =>
                                          _pick(decoration: true),
                                    ),
                                    const SizedBox(height: 8),
                                    _ThemeImageWell(
                                      label: AppStrings.themeMineBottom,
                                      path: _bottomPreview,
                                      height: 72,
                                      alignBottom: true,
                                      onPressed: () =>
                                          _pick(decoration: false),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _ColorDots(
                            values: EventCategory.palette,
                            selected: _accent,
                            onSelected: (value) =>
                                setState(() => _accent = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SaveCompanyButton(
                          onPressed: _saving ? () {} : _save,
                          color: color ?? accent,
                        ),
                      ],
                    ),
            ],
          ),
        ),
        );
      },
          ),
          if (widget.initial != null) ...[
            const SizedBox(height: 8),
            PressBounce(
              onPressed: _delete,
              pressedScale: 0.96,
              color: Colors.transparent,
              pressedColor: Colors.transparent,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    AppStrings.delete,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.danger,
                    ),
                  ),
                ),
              ),
            ),
          ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: _hintVisible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: _hintVisible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: _hintVisible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: _hintVisible ? 1 : 0,
                  child: _HintToast(text: AppStrings.themeMinePatternToast),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WashSlider extends StatefulWidget {
  const _WashSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  State<_WashSlider> createState() => _WashSliderState();
}

class _WashSliderState extends State<_WashSlider>
    with SingleTickerProviderStateMixin {
  static const _thumbRadius = 9.5;
  static const _pressedThumbRadius = 11.5;
  static const _trackHeight = 8.0;

  late final AnimationController _press;
  late double _t;
  var _dragging = false;

  @override
  void initState() {
    super.initState();
    _t = widget.value.clamp(0.0, 1.0);
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 180),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _WashSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging) return;
    _t = widget.value.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  double _tFromDx(double dx, double width) {
    final inner = (width - _thumbRadius * 2).clamp(1.0, width);
    return ((dx - _thumbRadius) / inner).clamp(0.0, 1.0);
  }

  void _start(double dx, double width) {
    _dragging = true;
    _press.forward();
    HapticFeedback.selectionClick();
    _emit(_tFromDx(dx, width));
  }

  void _move(double dx, double width) {
    if (!_dragging) {
      _dragging = true;
      _press.forward();
    }
    _emit(_tFromDx(dx, width));
  }

  void _end() {
    if (!_dragging) return;
    _dragging = false;
    _press.reverse();
  }

  void _emit(double t) {
    setState(() => _t = t);
    widget.onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _start(details.localPosition.dx, width),
                onTapUp: (_) => _end(),
                onTapCancel: _end,
                onHorizontalDragStart: (details) =>
                    _start(details.localPosition.dx, width),
                onHorizontalDragUpdate: (details) =>
                    _move(details.localPosition.dx, width),
                onHorizontalDragEnd: (_) => _end(),
                onHorizontalDragCancel: _end,
                child: SizedBox(
                  width: width,
                  height: 36,
                  child: CustomPaint(
                    painter: _SteppedSliderPainter(
                      progress: _t,
                      count: 0,
                      press: Curves.easeOut.transform(_press.value),
                      thumbRadius: _thumbRadius,
                      pressedThumbRadius: _pressedThumbRadius,
                      trackHeight: _trackHeight,
                      dotRadius: 0,
                      active: widget.color,
                      inactive: colors.card,
                      activeDot: Colors.transparent,
                      inactiveDot: Colors.transparent,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColorDots extends StatelessWidget {
  const _ColorDots({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<int> values;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final value in values)
          PressBounce(
            onPressed: () => onSelected(value),
            pressedScale: 0.9,
            color: Colors.transparent,
            pressedColor: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == value ? colors.card : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selected == value
                    ? const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                        ),
                      ]
                    : const [],
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeImageWell extends StatelessWidget {
  const _ThemeImageWell({
    required this.label,
    required this.path,
    required this.onPressed,
    this.height = 132,
    this.alignBottom = false,
  });

  final String label;
  final String? path;
  final VoidCallback onPressed;
  final double height;
  final bool alignBottom;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final imagePath = path;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.99,
      color: Colors.transparent,
      pressedColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.groupedBackground),
              if (hasImage)
                Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  alignment: alignBottom
                      ? Alignment.bottomCenter
                      : Alignment.center,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              if (!hasImage)
                Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.muted,
                    ),
                  ),
                )
              else
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.text.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteCustomThemeDialog extends StatelessWidget {
  const _DeleteCustomThemeDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.deleteTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.danger,
                  ),
                ),
                const TextSpan(text: ' ${AppStrings.themeMineDeleteBody}'),
              ],
            ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(false),
                  color: colors.border,
                  pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(true),
                  color: colors.danger,
                  pressedColor: Color.lerp(colors.danger, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.delete,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _FontSettingsFocus { family, labelScale, calendarChip }

class _FontSettingsPage extends StatefulWidget {
  const _FontSettingsPage({this.focus = _FontSettingsFocus.family});

  final _FontSettingsFocus focus;

  @override
  State<_FontSettingsPage> createState() => _FontSettingsPageState();
}

class _FontSettingsPageState extends State<_FontSettingsPage> {
  final _scroll = ScrollController();
  final _labelKey = GlobalKey();
  final _calendarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focus == _FontSettingsFocus.family) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      await _scrollToFocus();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _scrollToFocus({int attempt = 0}) async {
    if (!mounted) return;
    final key = switch (widget.focus) {
      _FontSettingsFocus.family => null,
      _FontSettingsFocus.labelScale => _labelKey,
      _FontSettingsFocus.calendarChip => _calendarKey,
    };
    final target = key?.currentContext?.findRenderObject();
    if (target == null || !_scroll.hasClients) {
      if (attempt >= 12) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFocus(attempt: attempt + 1);
      });
      return;
    }
    await _scroll.position.ensureVisible(
      target,
      alignment: 0.12,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final font = AppScope.of(context).fontPreference;
    final top = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: font,
      builder: (context, _) {
        final colors = AppColors.of(context);
        return Scaffold(
          backgroundColor: colors.groupedBackground,
          extendBodyBehindAppBar: true,
          appBar: _FrostedAppBar(
            title: AppStrings.settingsFontSection,
            onBack: () => Navigator.pop(context),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: top + 56),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _FontLivePreview(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel(AppStrings.fontFamily),
                      _SettingsCard(
                        children: [
                          for (final typeface in AppTypeface.selectable)
                            _SettingsTile(
                              label: _SettingsScreenState._typefaceLabel(
                                typeface,
                              ),
                              labelFontFamily: typeface.fontFamily,
                              previewLabelFont: true,
                              checked: font.typeface == typeface,
                              onPressed: () async {
                                await font.setTypeface(typeface);
                                await HomeScreenWidgetService.instance.sync();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      KeyedSubtree(
                        key: _labelKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel(AppStrings.fontLabelScale),
                            _SettingsSliderTile(
                              value: font.labelScale,
                              onChanged: (value) =>
                                  font.setLabelScale(value, persist: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      KeyedSubtree(
                        key: _calendarKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel(
                              AppStrings.fontCalendarChipScale,
                            ),
                            _SettingsSliderTile(
                              value: font.calendarChipScale,
                              onChanged: (value) => font.setCalendarChipScale(
                                value,
                                persist: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FontSizeSettingsPage extends StatelessWidget {
  const _FontSizeSettingsPage();

  @override
  Widget build(BuildContext context) {
    final font = AppScope.of(context).fontPreference;
    final top = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: font,
      builder: (context, _) {
        final colors = AppColors.of(context);
        return Scaffold(
          backgroundColor: colors.groupedBackground,
          extendBodyBehindAppBar: true,
          appBar: _FrostedAppBar(
            title: AppStrings.settingsCalendarSection,
            onBack: () => Navigator.pop(context),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '삼성전자',
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 18 * font.todoScale,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DayEventLabel(
                        title: '자기소개서 제출',
                        categoryName: '서류',
                        color: const Color(0xFF3B82F6),
                        timeText: '14:00',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final label in AppStrings.weekdays)
                            Expanded(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppFonts.of(context),
                                  fontSize: 13 * font.calendarScale,
                                  fontWeight: FontWeight.w500,
                                  color: colors.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CalendarEventLabel(
                        title: '면접 연습',
                        color: const Color(0xFF22C55E),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(AppStrings.fontTodoSize),
              _SettingsCard(
                children: [
                  for (final size in FontSizeLevel.values)
                    _SettingsTile(
                      label: _SettingsScreenState._sizeLabel(size),
                      checked: font.todoSize == size,
                      onPressed: () => font.setTodoSize(size),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(AppStrings.fontCalendarSize),
              _SettingsCard(
                children: [
                  for (final size in FontSizeLevel.values)
                    _SettingsTile(
                      label: _SettingsScreenState._sizeLabel(size),
                      checked: font.calendarSize == size,
                      onPressed: () => font.setCalendarSize(size),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(AppStrings.fontCalendarLabelSize),
              _SettingsCard(
                children: [
                  for (final size in FontSizeLevel.values)
                    _SettingsTile(
                      label: _SettingsScreenState._sizeLabel(size),
                      checked: font.calendarLabelSize == size,
                      onPressed: () => font.setCalendarLabelSize(size),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodoNotificationSettingsPage extends StatefulWidget {
  const _TodoNotificationSettingsPage();

  @override
  State<_TodoNotificationSettingsPage> createState() =>
      _TodoNotificationSettingsPageState();
}

class _TodoNotificationSettingsPageState
    extends State<_TodoNotificationSettingsPage> {
  late TodoReminderLead _lead;
  var _ready = false;
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _lead = AppScope.of(context).notificationPreference.todoReminderLead;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _showHint(TodoReminderLead lead) {
    _hintTimer?.cancel();
    setState(() {
      _hint = AppStrings.todoReminderHint(
        _SettingsScreenState._leadLabel(lead),
      );
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  Future<void> _select(TodoReminderLead lead) async {
    if (lead.isEnabled) _showHint(lead);
    if (_lead == lead) return;
    if (lead.isEnabled) {
      await TodoReminderService.instance.requestPermission();
    }
    if (!mounted) return;
    setState(() => _lead = lead);
    await AppScope.of(context).notificationPreference.setTodoReminderLead(lead);
    await TodoReminderService.instance.sync();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final visible = _hintVisible;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.todoNotificationSetting,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              _SettingsCard(
                children: [
                  for (final lead in TodoReminderLead.values)
                    _SettingsTile(
                      label: _SettingsScreenState._leadLabel(lead),
                      checked: _lead == lead,
                      onPressed: () => _select(lead),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: visible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: visible ? 1 : 0,
                  child: _HintToast(text: _hint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryNotificationSettingsPage extends StatefulWidget {
  const _SummaryNotificationSettingsPage();

  @override
  State<_SummaryNotificationSettingsPage> createState() =>
      _SummaryNotificationSettingsPageState();
}

class _SummaryNotificationSettingsPageState
    extends State<_SummaryNotificationSettingsPage> {
  var _enabled = true;
  var _minutes = NotificationPreference.defaultSummaryMinutes;
  var _ready = false;
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final preference = AppScope.of(context).notificationPreference;
    _enabled = preference.summaryEnabled;
    _minutes = preference.summaryMinutes;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _showHint(int minutes) {
    _hintTimer?.cancel();
    setState(() {
      _hint = AppStrings.summaryReminderHint(minutes);
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  Future<void> _selectOff() async {
    if (!_enabled) return;
    setState(() => _enabled = false);
    await AppScope.of(context).notificationPreference.setSummaryEnabled(false);
    await TodoReminderService.instance.sync();
  }

  Future<void> _selectTime(int minutes) async {
    _showHint(minutes);
    if (_enabled && _minutes == minutes) return;
    await TodoReminderService.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _enabled = true;
      _minutes = minutes;
    });
    await AppScope.of(
      context,
    ).notificationPreference.setSummaryMinutes(minutes);
    await TodoReminderService.instance.sync();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final visible = _hintVisible;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.summaryNotificationSetting,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              _SettingsCard(
                children: [
                  _SettingsTile(
                    label: AppStrings.notifyOff,
                    checked: !_enabled,
                    onPressed: _selectOff,
                  ),
                  for (final minutes
                      in NotificationPreference.summaryTimeOptions)
                    _SettingsTile(
                      label: AppStrings.summaryTimeLabel(minutes),
                      checked: _enabled && _minutes == minutes,
                      onPressed: () => _selectTime(minutes),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: visible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: visible ? 1 : 0,
                  child: _HintToast(text: _hint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftoverNotificationSettingsPage extends StatefulWidget {
  const _LeftoverNotificationSettingsPage();

  @override
  State<_LeftoverNotificationSettingsPage> createState() =>
      _LeftoverNotificationSettingsPageState();
}

class _LeftoverNotificationSettingsPageState
    extends State<_LeftoverNotificationSettingsPage> {
  var _enabled = true;
  var _minutes = NotificationPreference.defaultLeftoverMinutes;
  var _ready = false;
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final preference = AppScope.of(context).notificationPreference;
    _enabled = preference.leftoverEnabled;
    _minutes = preference.leftoverMinutes;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _showHint(int minutes) {
    _hintTimer?.cancel();
    setState(() {
      _hint = AppStrings.leftoverReminderHint(minutes);
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  Future<void> _selectOff() async {
    if (!_enabled) return;
    setState(() => _enabled = false);
    await AppScope.of(context).notificationPreference.setLeftoverEnabled(false);
    await TodoReminderService.instance.sync();
  }

  Future<void> _selectTime(int minutes) async {
    _showHint(minutes);
    if (_enabled && _minutes == minutes) return;
    await TodoReminderService.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _enabled = true;
      _minutes = minutes;
    });
    await AppScope.of(
      context,
    ).notificationPreference.setLeftoverMinutes(minutes);
    await TodoReminderService.instance.sync();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final visible = _hintVisible;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.leftoverNotificationSetting,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              _SettingsCard(
                children: [
                  _SettingsTile(
                    label: AppStrings.notifyOff,
                    checked: !_enabled,
                    onPressed: _selectOff,
                  ),
                  for (final minutes
                      in NotificationPreference.leftoverTimeOptions)
                    _SettingsTile(
                      label: AppStrings.summaryTimeLabel(minutes),
                      checked: _enabled && _minutes == minutes,
                      onPressed: () => _selectTime(minutes),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: visible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: visible ? 1 : 0,
                  child: _HintToast(text: _hint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoBackupSettingsPage extends StatefulWidget {
  const _AutoBackupSettingsPage();

  @override
  State<_AutoBackupSettingsPage> createState() =>
      _AutoBackupSettingsPageState();
}

class _AutoBackupSettingsPageState extends State<_AutoBackupSettingsPage> {
  late AutoBackupInterval _interval;
  var _ready = false;
  var _hint = '';
  var _hintVisible = false;
  Timer? _hintTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _interval = AppScope.of(context).backupPreference.interval;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _showHint(AutoBackupInterval interval) {
    if (!interval.isEnabled) return;
    _hintTimer?.cancel();
    setState(() {
      _hint = AppStrings.autoBackupHint(
        _SettingsScreenState._autoBackupLabel(interval),
      );
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  Future<void> _select(AutoBackupInterval interval) async {
    if (_interval == interval) return;
    setState(() => _interval = interval);
    _showHint(interval);
    final preference = AppScope.of(context).backupPreference;
    await preference.setInterval(interval);
    if (!interval.isEnabled) return;
    try {
      await AppBackupService.saveLocal();
      await preference.markBackedUp();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final visible = _hintVisible;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.autoBackupSetting,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              _SettingsCard(
                children: [
                  for (final interval in AutoBackupInterval.values)
                    _SettingsTile(
                      label: _SettingsScreenState._autoBackupLabel(interval),
                      checked: _interval == interval,
                      onPressed: () => _select(interval),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20 + bottom,
            child: IgnorePointer(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                offset: visible ? Offset.zero : const Offset(0, 0.18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                  opacity: visible ? 1 : 0,
                  child: _HintToast(text: _hint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintToast extends StatelessWidget {
  const _HintToast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class _FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FrostedAppBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  static const _toolbarHeight = 48.0;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ColoredBox(
          color: colors.groupedBackground.withValues(alpha: 0.08),
          child: AppBar(
            forceMaterialTransparency: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            toolbarHeight: _toolbarHeight,
            centerTitle: true,
            leading: PressBounce(
              onPressed: onBack,
              pressedColor: Colors.transparent,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                  color: colors.text,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {super.key, this.onHelp});

  final String text;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 2, 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          if (onHelp != null) ...[
            const SizedBox(width: 2),
            PressBounce(
              onPressed: onHelp,
              pressedScale: 0.88,
              pressedColor: Colors.transparent,
              child: Semantics(
                button: true,
                label: AppStrings.settingsHelpPreview,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    CupertinoIcons.question_circle,
                    size: 18,
                    color: colors.muted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandBelow extends StatefulWidget {
  const _ExpandBelow({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  State<_ExpandBelow> createState() => _ExpandBelowState();
}

class _ExpandBelowState extends State<_ExpandBelow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
      value: widget.open ? 1 : 0,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _ExpandBelow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) return;
    if (widget.open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _fade,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: _fade,
          child: IgnorePointer(
            ignoring: !widget.open,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.of(context).border,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsSliderTile extends StatefulWidget {
  const _SettingsSliderTile({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<_SettingsSliderTile>
    with TickerProviderStateMixin {
  static const _thumbRadius = 9.5;
  static const _pressedThumbRadius = 11.5;
  static const _trackHeight = 8.0;
  static const _dotRadius = 2.2;

  late final AnimationController _controller;
  late final AnimationController _press;
  late Animation<double> _snap;
  late double _t;
  var _dragging = false;

  int get _stepCount => FontPreference.scaleSteps.length;

  double get _targetT {
    if (_stepCount <= 1) return 0;
    return FontPreference.stepIndexOf(widget.value) / (_stepCount - 1);
  }

  @override
  void initState() {
    super.initState();
    _t = _targetT;
    _snap = const AlwaysStoppedAnimation(0);
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          if (_dragging) return;
          setState(() => _t = _snap.value);
        });
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 180),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _SettingsSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging || _controller.isAnimating) return;
    _t = _targetT;
  }

  @override
  void dispose() {
    _controller.dispose();
    _press.dispose();
    super.dispose();
  }

  double _tFromDx(double dx, double width) {
    final inner = (width - _thumbRadius * 2).clamp(1.0, width);
    return ((dx - _thumbRadius) / inner).clamp(0.0, 1.0);
  }

  void _emitNearest(double t) {
    final steps = FontPreference.scaleSteps;
    final index = (t * (steps.length - 1)).round();
    final next = steps[index];
    if ((next - widget.value).abs() < 0.0001) return;
    HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  void _start(double dx, double width) {
    _controller.stop();
    _dragging = true;
    _press.forward();
    setState(() => _t = _tFromDx(dx, width));
    _emitNearest(_t);
  }

  void _move(double dx, double width) {
    if (!_dragging) {
      _dragging = true;
      _press.forward();
    }
    setState(() => _t = _tFromDx(dx, width));
    _emitNearest(_t);
  }

  void _end() {
    if (!_dragging) return;
    _dragging = false;
    _press.reverse();
    final begin = _t;
    final end = _targetT;
    _snap = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _start(details.localPosition.dx, width),
            onTapUp: (_) => _end(),
            onHorizontalDragStart: (details) =>
                _start(details.localPosition.dx, width),
            onHorizontalDragUpdate: (details) =>
                _move(details.localPosition.dx, width),
            onHorizontalDragEnd: (_) => _end(),
            onHorizontalDragCancel: _end,
            child: SizedBox(
              width: width,
              height: 36,
              child: CustomPaint(
                painter: _SteppedSliderPainter(
                  progress: _t,
                  count: _stepCount,
                  press: Curves.easeOut.transform(_press.value),
                  thumbRadius: _thumbRadius,
                  pressedThumbRadius: _pressedThumbRadius,
                  trackHeight: _trackHeight,
                  dotRadius: _dotRadius,
                  active: colors.accentBright,
                  inactive: colors.card,
                  activeDot: Colors.white.withValues(alpha: 0.9),
                  inactiveDot: colors.accentBright,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SteppedSliderPainter extends CustomPainter {
  const _SteppedSliderPainter({
    required this.progress,
    required this.count,
    required this.press,
    required this.thumbRadius,
    required this.pressedThumbRadius,
    required this.trackHeight,
    required this.dotRadius,
    required this.active,
    required this.inactive,
    required this.activeDot,
    required this.inactiveDot,
  });

  final double progress;
  final int count;
  final double press;
  final double thumbRadius;
  final double pressedThumbRadius;
  final double trackHeight;
  final double dotRadius;
  final Color active;
  final Color inactive;
  final Color activeDot;
  final Color inactiveDot;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final start = thumbRadius;
    final end = size.width - thumbRadius;
    final trackWidth = end - start;
    final track = RRect.fromLTRBR(
      start - trackHeight / 2,
      cy - trackHeight / 2,
      end + trackHeight / 2,
      cy + trackHeight / 2,
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(track, Paint()..color = inactive);

    final thumbX = start + trackWidth * progress.clamp(0.0, 1.0);
    final activeTrack = RRect.fromLTRBR(
      start - trackHeight / 2,
      cy - trackHeight / 2,
      thumbX + trackHeight / 2,
      cy + trackHeight / 2,
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(activeTrack, Paint()..color = active);

    for (var i = 0; i < count; i++) {
      final x = start + trackWidth * (count <= 1 ? 0 : i / (count - 1));
      final passed = count <= 1 || i / (count - 1) <= progress + 0.001;
      canvas.drawCircle(
        Offset(x, cy),
        dotRadius,
        Paint()..color = passed ? activeDot : inactiveDot,
      );
    }

    final center = Offset(thumbX, cy);
    if (press > 0) {
      canvas.drawCircle(
        center,
        thumbRadius + 10 * press,
        Paint()..color = active.withValues(alpha: 0.18 * press),
      );
      canvas.drawCircle(
        center,
        thumbRadius + 5 * press,
        Paint()..color = active.withValues(alpha: 0.28 * press),
      );
    }
    final radius = thumbRadius + (pressedThumbRadius - thumbRadius) * press;
    canvas.drawCircle(center, radius, Paint()..color = active);
  }

  @override
  bool shouldRepaint(covariant _SteppedSliderPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        press != oldDelegate.press ||
        count != oldDelegate.count ||
        active != oldDelegate.active ||
        inactive != oldDelegate.inactive;
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(!value),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: CupertinoSwitch(
                  value: value,
                  activeTrackColor: colors.accentBright,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.onPressed,
    this.onLongPressed,
    this.checked = false,
    this.value,
    this.chevron = false,
    this.expanded,
    this.labelFontFamily,
    this.previewLabelFont = false,
  });

  final String label;
  final bool checked;
  final String? value;
  final bool chevron;
  final bool? expanded;
  final String? labelFontFamily;
  final bool previewLabelFont;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      onLongPressed: onLongPressed,
      pressedScale: 0.98,
      color: colors.card,
      pressedColor: colors.pressed,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            children: [
              if (value == null)
              Expanded(
                child: Text(
                  label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: previewLabelFont
                        ? labelFontFamily
                        : AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
                )
              else ...[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: previewLabelFont
                        ? labelFontFamily
                        : AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                  value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
              ],
              if (checked)
                Icon(Icons.check_rounded, size: 22, color: colors.text),
              if (chevron)
                AnimatedRotation(
                  turns: expanded == true ? 0.25 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: colors.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
