import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/home_widget/home_screen_widget_service.dart';
import 'package:job_planner/core/notifications/todo_reminder_service.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:job_planner/data/datasources/notification_preference.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:job_planner/presentation/screens/settings/widgets/settings_section_help.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _compact = false;
  var _sortByTime = false;
  var _showTime = false;
  var _todoReminderLead = TodoReminderLead.off;
  var _summaryEnabled = true;
  var _summaryHour = NotificationPreference.defaultSummaryMinutes;
  var _showLeftover = true;
  var _showToday = true;
  var _showTomorrow = true;
  var _showWeek = false;
  var _showMonth = false;
  var _showMonthlyStats = true;
  var _showWeeklyStats = false;
  var _startMonday = false;
  var _dark = false;
  var _typeface = AppTypeface.pretendard;
  var _todoSize = FontSizeLevel.medium;
  var _calendarSize = FontSizeLevel.medium;
  var _calendarLabelSize = FontSizeLevel.medium;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final scope = AppScope.of(context);
    _compact = scope.homeViewPreference.isCompact;
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
    _showMonthlyStats = scope.homeViewPreference.showMonthlyStats;
    _showWeeklyStats = scope.homeViewPreference.showWeeklyStats;
    _startMonday = scope.calendarPreference.startMonday;
    _dark = scope.themePreference.isDark;
    _typeface = scope.fontPreference.typeface;
    _todoSize = scope.fontPreference.todoSize;
    _calendarSize = scope.fontPreference.calendarSize;
    _calendarLabelSize = scope.fontPreference.calendarLabelSize;
  }

  Future<void> _setCompact(bool value) async {
    if (_compact == value) return;
    setState(() => _compact = value);
    await AppScope.of(context).homeViewPreference.setCompact(value);
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

  Future<void> _setShowMonthlyStats(bool value) async {
    setState(() => _showMonthlyStats = value);
    await AppScope.of(context).homeViewPreference.setShowMonthlyStats(value);
  }

  Future<void> _setShowWeeklyStats(bool value) async {
    setState(() => _showWeeklyStats = value);
    await AppScope.of(context).homeViewPreference.setShowWeeklyStats(value);
  }

  Future<void> _setStartMonday(bool value) async {
    setState(() => _startMonday = value);
    await AppScope.of(context).calendarPreference.setStartMonday(value);
  }

  Future<void> _setDark(bool value) async {
    if (_dark == value) return;
    setState(() => _dark = value);
    await AppScope.of(context).themePreference.setDark(value);
    await HomeScreenWidgetService.instance.sync();
  }

  Future<void> _openFontSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _FontSettingsPage(),
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
      _todoReminderLead =
          AppScope.of(context).notificationPreference.todoReminderLead;
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

  static String _typefaceLabel(AppTypeface typeface) {
    switch (typeface) {
      case AppTypeface.pretendard:
        return AppStrings.fontPretendard;
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.of(context).groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FrostedAppBar(
        title: AppStrings.settingsTitle,
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
        children: [
          _SectionLabel(
            AppStrings.settingsHomeSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.home,
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.defaultView,
                checked: !_compact,
                onPressed: () => _setCompact(false),
              ),
              _SettingsTile(
                label: AppStrings.categoryView,
                checked: _compact,
                onPressed: () => _setCompact(true),
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
            AppStrings.settingsCalendarSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.calendar,
            ),
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
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsTodoSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.todo,
            ),
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
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(
            AppStrings.settingsFontSection,
            onHelp: () => showSettingsSectionHelp(
              context,
              SettingsHelpSection.font,
            ),
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                label: AppStrings.fontFamily,
                value: _typefaceLabel(_typeface),
                chevron: true,
                onPressed: _openFontSettings,
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
        ],
      ),
    );
  }
}

class _FontSettingsPage extends StatelessWidget {
  const _FontSettingsPage();

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
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 32),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: SizedBox(
                  height: 52 * FontPreference.maxScale +
                      18 * FontPreference.maxScale +
                      74,
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
              ),
              const SizedBox(height: 24),
              _SectionLabel(AppStrings.fontFamily),
              _SettingsCard(
                children: [
                  for (final typeface in AppTypeface.selectable)
                    _SettingsTile(
                      label: _SettingsScreenState._typefaceLabel(typeface),
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
              _SectionLabel(AppStrings.fontLabelScale),
              _SettingsSliderTile(
                value: font.labelScale,
                onChanged: (value) => font.setLabelScale(value, persist: true),
              ),
              const SizedBox(height: 20),
              _SectionLabel(AppStrings.fontCalendarChipScale),
              _SettingsSliderTile(
                value: font.calendarChipScale,
                onChanged: (value) =>
                    font.setCalendarChipScale(value, persist: true),
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
      _hint = AppStrings.todoReminderHint(_SettingsScreenState._leadLabel(lead));
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
    await AppScope.of(context).notificationPreference.setSummaryMinutes(minutes);
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
                  for (final minutes in NotificationPreference.summaryTimeOptions)
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
  const _FrostedAppBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
  const _SectionLabel(this.text, {this.onHelp});

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
  const _SettingsSliderTile({
    required this.value,
    required this.onChanged,
  });

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
    _controller = AnimationController(
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
    _snap = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
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
    final radius =
        thumbRadius + (pressedThumbRadius - thumbRadius) * press;
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
    this.checked = false,
    this.value,
    this.chevron = false,
    this.labelFontFamily,
    this.previewLabelFont = false,
  });

  final String label;
  final bool checked;
  final String? value;
  final bool chevron;
  final String? labelFontFamily;
  final bool previewLabelFont;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.98,
      color: colors.card,
      pressedColor: colors.pressed,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: previewLabelFont
                        ? labelFontFamily
                        : AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(
                  value!,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              if (checked)
                Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: colors.text,
                ),
              if (chevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
