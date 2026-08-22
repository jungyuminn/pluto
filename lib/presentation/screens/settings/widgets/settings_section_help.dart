import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/constants/release_notes.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/theme/app_skin_background.dart';
import 'package:job_planner/core/theme/app_theme.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/data/datasources/font_preference.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';

enum SettingsHelpSection {
  homeLayout,
  monthlyStats,
  calendar,
  todo,
  notification,
  font,
  appearance,
  theme,
  backup,
  app,
}

Future<void> showSettingsSectionHelp(
  BuildContext context,
  SettingsHelpSection section,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => SettingsSectionHelpSheet(section: section),
  );
}

class SettingsSectionHelpSheet extends StatelessWidget {
  const SettingsSectionHelpSheet({super.key, required this.section});

  final SettingsHelpSection section;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.settingsHelpPreview,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    section.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.groupedBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      child: section.preview,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on SettingsHelpSection {
  String get title {
    switch (this) {
      case SettingsHelpSection.homeLayout:
        return AppStrings.settingsHomeLayoutSection;
      case SettingsHelpSection.monthlyStats:
        return AppStrings.settingsMonthlyStatsSection;
      case SettingsHelpSection.calendar:
        return AppStrings.settingsCalendarSection;
      case SettingsHelpSection.todo:
        return AppStrings.settingsTodoSection;
      case SettingsHelpSection.notification:
        return AppStrings.settingsNotificationSection;
      case SettingsHelpSection.font:
        return AppStrings.settingsFontSection;
      case SettingsHelpSection.appearance:
        return AppStrings.settingsAppearanceSection;
      case SettingsHelpSection.theme:
        return AppStrings.settingsThemeSection;
      case SettingsHelpSection.backup:
        return AppStrings.settingsBackupSection;
      case SettingsHelpSection.app:
        return AppStrings.settingsAppSection;
    }
  }

  String get body {
    switch (this) {
      case SettingsHelpSection.homeLayout:
        return AppStrings.settingsHomeLayoutHelp;
      case SettingsHelpSection.monthlyStats:
        return AppStrings.settingsMonthlyStatsHelp;
      case SettingsHelpSection.calendar:
        return showFontSizeSettings
            ? AppStrings.settingsCalendarHelpWithFontSize
            : AppStrings.settingsCalendarHelp;
      case SettingsHelpSection.todo:
        return AppStrings.settingsTodoHelp;
      case SettingsHelpSection.notification:
        return AppStrings.settingsNotificationHelp;
      case SettingsHelpSection.font:
        return AppStrings.settingsFontHelp;
      case SettingsHelpSection.appearance:
        return AppStrings.settingsAppearanceHelp;
      case SettingsHelpSection.theme:
        return AppStrings.settingsThemeHelp;
      case SettingsHelpSection.backup:
        return AppStrings.settingsBackupHelp;
      case SettingsHelpSection.app:
        return AppStrings.settingsAppHelp;
    }
  }

  Widget get preview {
    switch (this) {
      case SettingsHelpSection.homeLayout:
        return const _HomeLayoutPreview();
      case SettingsHelpSection.monthlyStats:
        return const _MonthlyStatsPreview();
      case SettingsHelpSection.calendar:
        return const _CalendarPreview();
      case SettingsHelpSection.todo:
        return const _TodoPreview();
      case SettingsHelpSection.notification:
        return const _NotificationPreview();
      case SettingsHelpSection.font:
        return const _FontPreview();
      case SettingsHelpSection.appearance:
        return const _AppearancePreview();
      case SettingsHelpSection.theme:
        return const _ThemePreview();
      case SettingsHelpSection.backup:
        return const _BackupPreview();
      case SettingsHelpSection.app:
        return const _AppPreview();
    }
  }
}

class _HomeLayoutPreview extends StatelessWidget {
  const _HomeLayoutPreview();

  @override
  Widget build(BuildContext context) {
    return _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.homeShowLeftover,
          child: Column(
            children: [
              _FakeBannerCard(AppStrings.leftoverTodos(3)),
              const SizedBox(height: 10),
              const _FakeLeftoverPeek(),
            ],
          ),
        ),
        const _PreviewFrame(
          caption: AppStrings.homeShowToday,
          child: _FakeHomeCard(
            title: AppStrings.todayTitle,
            dateLabel: '8. 19. (수)',
            children: [
              _FakeTodo(
                title: '자기소개서 제출',
                category: '서류',
                color: Color(0xFF3B82F6),
              ),
              _FakeTodo(
                title: '코딩테스트 준비',
                category: '코딩테스트',
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
        const _PreviewFrame(
          caption: AppStrings.homeShowTomorrow,
          child: _FakeHomeCard(
            title: AppStrings.tomorrowTitle,
            dateLabel: '8. 20. (목)',
            children: [
              _FakeTodo(
                title: '면접 연습',
                category: '면접',
                color: Color(0xFF22C55E),
              ),
            ],
          ),
        ),
        const _PreviewFrame(
          caption: AppStrings.homeShowWeek,
          child: _FakeHomeCard(
            title: AppStrings.weekTitle,
            dateLabel: '8. 19. (수) - 8. 23. (일)',
            children: [
              _FakeDayHeader(AppStrings.todayTitle),
              _FakeTodo(
                title: '자기소개서 제출',
                category: '서류',
                color: Color(0xFF3B82F6),
              ),
              _FakeDayHeader(AppStrings.tomorrowTitle, showTopGap: true),
              _FakeTodo(
                title: '면접 연습',
                category: '면접',
                color: Color(0xFF22C55E),
              ),
              _FakeDayHeader('8. 22. (토)', showTopGap: true),
              _FakeTodo(
                title: '코딩테스트 준비',
                category: '코딩테스트',
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
        const _PreviewFrame(
          caption: AppStrings.homeShowMonth,
          child: _FakeHomeCard(
            title: AppStrings.monthTitle,
            dateLabel: '8. 19. (수) - 8. 31. (월)',
            children: [
              _FakeDayHeader(AppStrings.todayTitle),
              _FakeTodo(
                title: '자기소개서 제출',
                category: '서류',
                color: Color(0xFF3B82F6),
              ),
              _FakeDayHeader('8. 25. (화)', showTopGap: true),
              _FakeTodo(
                title: '면접 연습',
                category: '면접',
                color: Color(0xFF22C55E),
              ),
              _FakeDayHeader('8. 28. (금)', showTopGap: true),
              _FakeTodo(
                title: '코딩테스트 준비',
                category: '코딩테스트',
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
        const _PreviewFrame(
          caption: AppStrings.homeShowLongGoal,
          child: _FakeHomeCard(
            title: AppStrings.longGoalTitle,
            children: [
              _FakeTodo(
                title: '다이어트',
                category: '75kg / 70kg',
                color: Color(0xFF22C55E),
                trailingText: '50%',
                showComplete: false,
              ),
              _FakeTodo(
                title: '매일 독서',
                category: '12 / 30일',
                color: Color(0xFF8B5CF6),
                trailingText: '40%',
                showComplete: false,
              ),
              _FakeTodo(
                title: '무지출챌린지',
                category: '8 / 21일',
                color: Color(0xFFF97316),
                trailingText: '38%',
                showComplete: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyStatsPreview extends StatelessWidget {
  const _MonthlyStatsPreview();

  @override
  Widget build(BuildContext context) {
    return _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.homeShowWeeklyStats,
          child: _FakeBannerCard(AppStrings.weeklyStatsCardTitle),
        ),
        _PreviewFrame(
          caption: AppStrings.settingsHomeSection,
          child: _FakeBannerCard(AppStrings.monthlyStatsCardTitle(7)),
        ),
        _PreviewFrame(
          caption: AppStrings.monthlyStatsPreviewSummary,
          child: const _FakeMonthlySummary(),
        ),
        _PreviewFrame(
          caption: AppStrings.monthlyStatsTodoSection,
          child: const _FakeMonthlyTodos(),
        ),
        _PreviewFrame(
          caption: AppStrings.monthlyStatsJobSection,
          child: const _FakeMonthlyJobs(),
        ),
      ],
    );
  }
}

class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview();

  @override
  Widget build(BuildContext context) {
    return _CyclingPreview(
      frames: [
        const _PreviewFrame(
          caption: AppStrings.calendarStartSunday,
          child: _FakeWeekStartCalendar(startMonday: false),
        ),
        const _PreviewFrame(
          caption: AppStrings.calendarStartMonday,
          child: _FakeWeekStartCalendar(startMonday: true),
        ),
        if (showFontSizeSettings) ...[
          const _PreviewFrame(
            caption: '${AppStrings.fontTodoSize} ${AppStrings.fontSizeLarge}',
            child: _FontPreviewCard(
              fontFamily: AppFonts.pretendard,
              todoScale: 1.14,
              calendarScale: 1,
              calendarLabelScale: 1,
            ),
          ),
          const _PreviewFrame(
            caption: '${AppStrings.fontCalendarSize} ${AppStrings.fontSizeLarge}',
            child: _FontPreviewCard(
              fontFamily: AppFonts.pretendard,
              todoScale: 1,
              calendarScale: 1.14,
              calendarLabelScale: 1,
            ),
          ),
          const _PreviewFrame(
            caption:
                '${AppStrings.fontCalendarLabelSize} ${AppStrings.fontSizeLarge}',
            child: _FontPreviewCard(
              fontFamily: AppFonts.pretendard,
              todoScale: 1,
              calendarScale: 1,
              calendarLabelScale: 1.14,
            ),
          ),
        ],
      ],
    );
  }
}

class _FakeWeekStartCalendar extends StatelessWidget {
  const _FakeWeekStartCalendar({required this.startMonday});

  final bool startMonday;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final labels = AppStrings.weekdayLabels(startMonday: startMonday);
    final numbers = startMonday
        ? const ['1', '2', '3', '4', '5', '6', '7']
        : const ['31', '1', '2', '3', '4', '5', '6'];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          children: [
            Row(
              children: [
                for (final label in labels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < numbers.length; i++)
                  Expanded(
                    child: Text(
                      numbers[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: i == 0 && !startMonday
                            ? colors.outside
                            : colors.text,
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

class _TodoPreview extends StatelessWidget {
  const _TodoPreview();

  @override
  Widget build(BuildContext context) {
    return _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.timeDisplay,
          child: const _FakeHomeCard(
            title: AppStrings.todayTitle,
            children: [
              _FakeTodo(
                title: '면접 연습',
                category: '면접',
                color: Color(0xFF22C55E),
                timeText: '오후 4:00',
              ),
              _FakeTodo(
                title: '자기소개서 제출',
                category: '서류',
                color: Color(0xFF3B82F6),
                timeText: '오전 9:00',
              ),
              _FakeTodo(
                title: '코딩테스트 준비',
                category: '코딩테스트',
                color: Color(0xFFF59E0B),
                timeText: '오후 2:00',
              ),
            ],
          ),
        ),
        _PreviewFrame(
          caption: AppStrings.timeSortView,
          child: const _FakeHomeCard(
            title: AppStrings.todayTitle,
            children: [
              _FakeTodo(
                title: '자기소개서 제출',
                category: '서류',
                color: Color(0xFF3B82F6),
                timeText: '오전 9:00',
              ),
              _FakeTodo(
                title: '코딩테스트 준비',
                category: '코딩테스트',
                color: Color(0xFFF59E0B),
                timeText: '오후 2:00',
              ),
              _FakeTodo(
                title: '면접 연습',
                category: '면접',
                color: Color(0xFF22C55E),
                timeText: '오후 4:00',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _FakeNotificationCard(
          title: '코딩테스트 준비',
          body: '10분 후 시작해요',
          time: '지금',
        ),
        SizedBox(height: 10),
        _FakeNotificationCard(
          title: '오늘의 일정 3개',
          body: '자기소개서 제출, 코딩테스트 준비, 면접 연습',
          time: '오전 8:00',
        ),
      ],
    );
  }
}

class _BackupPreview extends StatelessWidget {
  const _BackupPreview();

  @override
  Widget build(BuildContext context) {
    return const _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.backupData,
          child: _FakeBackupScene(
            icon: Icons.ios_share_rounded,
            title: AppStrings.backupSavedTitle,
            body: '잡플래너_백업.zip',
          ),
        ),
        _PreviewFrame(
          caption: AppStrings.restoreData,
          child: _FakeBackupScene(
            icon: Icons.download_rounded,
            title: AppStrings.restoreDoneTitle,
            body: AppStrings.restoreDoneBody,
          ),
        ),
        _PreviewFrame(
          caption: AppStrings.autoBackupSetting,
          child: _FakeBackupScene(
            icon: Icons.sync_rounded,
            title: AppStrings.autoBackupDaily,
            body: '앱을 켜면 매일 자동으로 저장해요',
          ),
        ),
      ],
    );
  }
}

class _FakeBackupScene extends StatelessWidget {
  const _FakeBackupScene({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.tint(colors.accentBright, 0.18),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  icon,
                  size: 24,
                  color: colors.accentBright,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppPreview extends StatelessWidget {
  const _AppPreview();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final note = ReleaseNotes.all.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.version,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            if (note.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                AppStrings.releaseNotesFeatures,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 6),
              _FakeReleaseBullet(note.items.first),
            ],
            if (note.fixes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                AppStrings.releaseNotesFixes,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 6),
              _FakeReleaseBullet(note.fixes.first),
            ],
          ],
        ),
      ),
    );
  }
}

class _FakeReleaseBullet extends StatelessWidget {
  const _FakeReleaseBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final style = TextStyle(
      fontFamily: AppFonts.of(context),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: colors.text,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 14,
          child: Text('·', style: style),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _FontPreview extends StatelessWidget {
  const _FontPreview();

  @override
  Widget build(BuildContext context) {
    return const _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.fontFamily,
          child: _TypefacePreviewCard(typeface: AppTypeface.bazzi),
        ),
        _PreviewFrame(
          caption: AppStrings.fontLabelScale,
          child: _TypefacePreviewCard(
            typeface: AppTypeface.pretendard,
            labelScale: FontPreference.maxScale,
          ),
        ),
        _PreviewFrame(
          caption: AppStrings.fontCalendarChipScale,
          child: _TypefacePreviewCard(
            typeface: AppTypeface.pretendard,
            calendarLabelScale: FontPreference.maxScale,
          ),
        ),
      ],
    );
  }
}

class _TypefacePreviewCard extends StatelessWidget {
  const _TypefacePreviewCard({
    required this.typeface,
    this.labelScale,
    this.calendarLabelScale,
  });

  final AppTypeface typeface;
  final double? labelScale;
  final double? calendarLabelScale;

  @override
  Widget build(BuildContext context) {
    final current = FontScope.maybeOf(context);
    final colors = AppColors.of(context);
    return FontScope(
      typeface: typeface,
      todoScale: current?.todoScale ?? 1,
      labelScale: labelScale ?? current?.labelScale ?? 1,
      calendarScale: current?.calendarScale ?? 1,
      calendarLabelScale:
          calendarLabelScale ?? current?.calendarLabelScale ?? 1,
      child: Builder(
        builder: (context) {
          return DecoratedBox(
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
          );
        },
      ),
    );
  }
}

class _FontPreviewCard extends StatelessWidget {
  const _FontPreviewCard({
    required this.fontFamily,
    required this.todoScale,
    required this.calendarScale,
    required this.calendarLabelScale,
  });

  final String fontFamily;
  final double todoScale;
  final double calendarScale;
  final double calendarLabelScale;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '삼성전자',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 18 * todoScale,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '자기소개서 제출',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12 * todoScale,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final label in AppStrings.weekdays)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 12 * calendarScale,
                        fontWeight: FontWeight.w500,
                        color: colors.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: Text(
                    '면접 연습',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11 * calendarLabelScale,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    for (final asset in AppSkinAssets.precacheDecorations) {
      precacheImage(AssetImage(asset), context);
    }
    return _CyclingPreview(
      frames: [
        for (final skin in AppSkin.values)
          _PreviewFrame(
            caption: _themeCaption(skin),
            child: _ThemeHelpScene(skin: skin),
          ),
      ],
    );
  }

  static String _themeCaption(AppSkin skin) {
    switch (skin) {
      case AppSkin.classic:
        return AppStrings.themeClassic;
      case AppSkin.blossom:
        return AppStrings.themeBlossom;
      case AppSkin.summerBeach:
        return AppStrings.themeSummerBeach;
      case AppSkin.autumnForest:
        return AppStrings.themeAutumnForest;
      case AppSkin.snowyWinter:
        return AppStrings.themeSnowyWinter;
      case AppSkin.squishyBear:
        return AppStrings.themeSquishyBear;
      case AppSkin.strawberryMilk:
        return AppStrings.themeStrawberryMilk;
      case AppSkin.onionVillage:
        return AppStrings.themeOnionVillage;
      case AppSkin.lovelyBear:
        return AppStrings.themeLovelyBear;
      case AppSkin.rainyDay:
        return AppStrings.themeRainyDay;
      case AppSkin.concertDay:
        return AppStrings.themeConcertDay;
      case AppSkin.boyhood:
        return AppStrings.themeBoyhood;
      case AppSkin.interlude:
        return AppStrings.themeInterlude;
      case AppSkin.fluffyCloud:
        return AppStrings.themeFluffyCloud;
      case AppSkin.catVillage:
        return AppStrings.themeCatVillage;
      case AppSkin.hamsterBakery:
        return AppStrings.themeHamsterBakery;
    }
  }
}

class _ThemeHelpScene extends StatelessWidget {
  const _ThemeHelpScene({required this.skin});

  final AppSkin skin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: 188,
          child: AppSkinBackground(
            skin: skin,
            liftForNav: false,
            scaleByWidth: true,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                children: [
                  Spacer(),
                  _FakeHomeCard(
                    title: AppStrings.todayTitle,
                    children: [
                      _FakeTodo(
                        title: '자기소개서 제출',
                        category: '서류',
                        color: Color(0xFF3B82F6),
                      ),
                      _FakeTodo(
                        title: '면접 연습',
                        category: '면접',
                        color: Color(0xFF22C55E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ThemedPreviewPhone(
            theme: AppTheme.light,
            caption: AppStrings.lightMode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ThemedPreviewPhone(
            theme: AppTheme.dark,
            caption: AppStrings.darkMode,
          ),
        ),
      ],
    );
  }
}

class _ThemedPreviewPhone extends StatelessWidget {
  const _ThemedPreviewPhone({
    required this.theme,
    this.caption,
    this.background,
    this.child,
  });

  final ThemeData theme;
  final String? caption;
  final Color? background;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Theme(
          data: theme,
          child: Builder(
            builder: (context) {
              final colors = AppColors.of(context);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: background ?? colors.groupedBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: child ??
                      const _FakeHomeCard(
                        title: AppStrings.todayTitle,
                        children: [
                          _FakeTodo(
                            title: '자기소개서 제출',
                            category: '서류',
                            color: Color(0xFF3B82F6),
                          ),
                          _FakeTodo(
                            title: '면접 연습',
                            category: '면접',
                            color: Color(0xFF22C55E),
                          ),
                        ],
                      ),
                ),
              );
            },
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).text,
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewFrame {
  const _PreviewFrame({required this.caption, required this.child});

  final String caption;
  final Widget child;
}

class _CyclingPreview extends StatefulWidget {
  const _CyclingPreview({required this.frames});

  final List<_PreviewFrame> frames;

  @override
  State<_CyclingPreview> createState() => _CyclingPreviewState();
}

class _CyclingPreviewState extends State<_CyclingPreview> {
  var _index = 0;
  Timer? _timer;

  bool get _canCycle => widget.frames.length > 1;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_canCycle) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _goTo(_index + 1);
    });
  }

  void _goTo(int next, {bool fromUser = false}) {
    if (!_canCycle) return;
    final index = next % widget.frames.length;
    final wrapped = index < 0 ? index + widget.frames.length : index;
    if (wrapped == _index) return;
    setState(() => _index = wrapped);
    if (fromUser) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[_index];
    final colors = AppColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: !_canCycle
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 180) return;
              _goTo(
                velocity < 0 ? _index + 1 : _index - 1,
                fromUser: true,
              );
            },
      child: Column(
        children: [
          Row(
            children: [
              if (_canCycle)
                _PreviewNavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _goTo(_index - 1, fromUser: true),
                )
              else
                const SizedBox(width: 32),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    child: DecoratedBox(
                      key: ValueKey(frame.caption),
                      decoration: BoxDecoration(
                        color: colors.tint(colors.accentBright, 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          frame.caption,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.accentBright,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_canCycle)
                _PreviewNavButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _goTo(_index + 1, fromUser: true),
                )
              else
                const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(frame.caption),
                child: IgnorePointer(child: frame.child),
              ),
            ),
          ),
          if (_canCycle) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.frames.length; i++)
                  PressBounce(
                    onPressed: () => _goTo(i, fromUser: true),
                    pressedScale: 0.9,
                    pressedColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: i == _index ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? colors.accentBright
                              : colors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewNavButton extends StatelessWidget {
  const _PreviewNavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.88,
      pressedColor: Colors.transparent,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 26,
          color: colors.muted,
        ),
      ),
    );
  }
}

class _FakeHomeCard extends StatelessWidget {
  const _FakeHomeCard({
    required this.title,
    required this.children,
    this.dateLabel,
  });

  final String title;
  final String? dateLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: colors.text,
              ),
            ),
            if (dateLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                dateLabel!,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                ),
              ),
            ],
            const SizedBox(height: 10),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _FakeBannerCard extends StatelessWidget {
  const _FakeBannerCard(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.accentBright,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: colors.accentBright,
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeDayHeader extends StatelessWidget {
  const _FakeDayHeader(this.name, {this.showTopGap = false});

  final String name;
  final bool showTopGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: showTopGap ? 8 : 0, bottom: 6),
      child: Text(
        name,
        style: TextStyle(
          fontFamily: AppFonts.of(context),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1,
          color: AppColors.of(context).text,
        ),
      ),
    );
  }
}

class _FakeLeftoverPeek extends StatelessWidget {
  const _FakeLeftoverPeek();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'D + 2',
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: colors.danger,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '8. 17. (월)',
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 10),
            const _FakeTodo(
              title: '자기소개서 제출',
              category: '서류',
              color: Color(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeMonthlySummary extends StatelessWidget {
  const _FakeMonthlySummary();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: colors.text,
            ),
            children: [
              TextSpan(text: '${AppStrings.monthlyStatsHeadlineMonth(7)}\n'),
              TextSpan(
                text: AppStrings.monthlyStatsTodoCount(12),
                style: TextStyle(color: colors.accent),
              ),
              const TextSpan(text: '${AppStrings.monthlyStatsCompleteAnd}\n'),
              TextSpan(
                text: AppStrings.monthlyStatsRoundCount(5),
                style: TextStyle(color: colors.accent),
              ),
              const TextSpan(text: AppStrings.monthlyStatsRoundsTail),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _FakeHighlightTile(
                label: AppStrings.monthlyStatsCompletedLabel,
                value: '12',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _FakeHighlightTile(
                label: AppStrings.monthlyStatsRateLabel,
                value: '67%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(
              child: _FakeHighlightTile(
                label: AppStrings.monthlyStatsRoundsLabel,
                value: '5',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _FakeHighlightTile(
                label: AppStrings.monthlyStatsCompaniesLabel,
                value: '3',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FakeHighlightTile extends StatelessWidget {
  const _FakeHighlightTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
                color: colors.accentBright,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeMonthlyTodos extends StatelessWidget {
  const _FakeMonthlyTodos();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FakeMiniCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.monthlyStatsRateLabel,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colors.text,
                      ),
                    ),
                  ),
                  Text(
                    '67%',
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.67,
                  minHeight: 6,
                  backgroundColor: colors.border,
                  color: colors.accentBright,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.monthlyStatsFraction(12, 18),
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _FakeMiniCard(
          child: Column(
            children: const [
              _FakeStatLine(
                label: AppStrings.monthlyStatsCompletedLabel,
                value: '12',
              ),
              _FakeStatLine(
                label: AppStrings.monthlyStatsIncompleteLabel,
                value: '6',
              ),
              _FakeStatLine(
                label: AppStrings.monthlyStatsTotalLabel,
                value: '18',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _FakeMiniCard(
          child: Column(
            children: [
              _FakeCategoryBar(
                label: '서류',
                done: 5,
                total: 7,
                color: const Color(0xFF3B82F6),
              ),
              _FakeCategoryBar(
                label: '면접',
                done: 4,
                total: 6,
                color: const Color(0xFF22C55E),
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FakeMonthlyJobs extends StatelessWidget {
  const _FakeMonthlyJobs();

  @override
  Widget build(BuildContext context) {
    return _FakeMiniCard(
      child: Column(
        children: const [
          _FakeStatLine(
            label: AppStrings.monthlyStatsRoundsLabel,
            value: '5',
          ),
          _FakeStatLine(
            label: AppStrings.monthlyStatsCompaniesLabel,
            value: '3',
          ),
          _FakeStatLine(
            label: AppStrings.monthlyStatsCoverLettersLabel,
            value: '2',
          ),
          _FakeStatLine(
            label: AppStrings.monthlyStatsFinalPassedLabel,
            value: '1',
            dotColor: Color(0xFF1F4D08),
          ),
          _FakeStatLine(
            label: AppStrings.monthlyStatsPassedLabel,
            value: '1',
            dotColor: Color(0xFF4A8A10),
          ),
          _FakeStatLine(
            label: AppStrings.monthlyStatsRejectedLabel,
            value: '1',
            dotColor: Color(0xFF94A3B8),
          ),
          _FakeStatLine(
            label: AppStrings.monthlyStatsInProgressLabel,
            value: '1',
            dotColor: Color(0xFF3B82F6),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _FakeMiniCard extends StatelessWidget {
  const _FakeMiniCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      ),
    );
  }
}

class _FakeStatLine extends StatelessWidget {
  const _FakeStatLine({
    required this.label,
    required this.value,
    this.dotColor,
    this.last = false,
  });

  final String label;
  final String value;
  final Color? dotColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colors.text,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeCategoryBar extends StatelessWidget {
  const _FakeCategoryBar({
    required this.label,
    required this.done,
    required this.total,
    required this.color,
    this.last = false,
  });

  final String label;
  final int done;
  final int total;
  final Color color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                  ),
                ),
              ),
              Text(
                AppStrings.monthlyStatsFraction(done, total),
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 5,
              backgroundColor: colors.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeTodo extends StatelessWidget {
  const _FakeTodo({
    required this.title,
    required this.category,
    required this.color,
    this.timeText,
    this.trailingText,
    this.showCategory = true,
    this.showComplete = true,
    this.completed = false,
  });

  final String title;
  final String category;
  final Color color;
  final String? timeText;
  final String? trailingText;
  final bool showCategory;
  final bool showComplete;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = colors.tint(color, 0.22);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: background,
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              if (!completed)
                ColoredBox(
                  color: color,
                  child: const SizedBox(width: 4, height: 46),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          color: colors.text,
                        ),
                      ),
                      if (showCategory || timeText != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (showCategory)
                              Expanded(
                                child: Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppFonts.of(context),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.hint,
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            if (timeText != null)
                              Text(
                                timeText!,
                                style: TextStyle(
                                  fontFamily: AppFonts.of(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    trailingText!,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: color,
                    ),
                  ),
                ),
              if (showComplete)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: const SizedBox(width: 16, height: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeNotificationCard extends StatelessWidget {
  const _FakeNotificationCard({
    required this.title,
    required this.body,
    required this.time,
  });

  final String title;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.92),
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.accentBright,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.notifications_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.appName,
                              style: TextStyle(
                                fontFamily: AppFonts.of(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.muted,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
