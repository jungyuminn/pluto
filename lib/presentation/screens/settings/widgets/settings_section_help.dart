import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/calendar/lunar_date.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/constants/release_notes.dart';
import 'package:pluto/presentation/screens/settings/widgets/release_note_demos.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_skin_background.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/font_preference.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_event_label.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_category_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_time_chip.dart';
import 'package:pluto/presentation/screens/shell/widgets/pill_bottom_nav.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

enum SettingsHelpSection {
  homeLayout,
  monthlyStats,
  calendar,
  todo,
  notification,
  font,
  appearance,
  theme,
  nav,
  widget,
  backup,
  calendarSync,
  app,
  category,
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                  if (section.body.isNotEmpty) ...[
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
                  ],
                  if (section.wrapsPreview)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.groupedBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                        child: section.preview,
                      ),
                    )
                  else
                    section.preview,
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
      case SettingsHelpSection.nav:
        return AppStrings.settingsNavSection;
      case SettingsHelpSection.widget:
        return AppStrings.settingsWidgetSection;
      case SettingsHelpSection.backup:
        return AppStrings.settingsBackupSection;
      case SettingsHelpSection.calendarSync:
        return AppStrings.settingsCalendarSyncSection;
      case SettingsHelpSection.app:
        return AppStrings.settingsAppSection;
      case SettingsHelpSection.category:
        return AppStrings.settingsCategorySection;
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
        return '';
      case SettingsHelpSection.notification:
        return AppStrings.settingsNotificationHelp;
      case SettingsHelpSection.font:
        return AppStrings.settingsFontHelp;
      case SettingsHelpSection.appearance:
        return AppStrings.settingsAppearanceHelp;
      case SettingsHelpSection.theme:
        return AppStrings.settingsThemeHelp;
      case SettingsHelpSection.nav:
        return AppStrings.settingsNavHelp;
      case SettingsHelpSection.widget:
        return AppStrings.settingsWidgetHelp;
      case SettingsHelpSection.backup:
        return AppStrings.settingsBackupHelp;
      case SettingsHelpSection.calendarSync:
        return AppStrings.settingsCalendarSyncHelp;
      case SettingsHelpSection.app:
        return AppStrings.settingsAppHelp;
      case SettingsHelpSection.category:
        return AppStrings.settingsCategoryHelp;
    }
  }

  bool get wrapsPreview => this != SettingsHelpSection.todo;

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
      case SettingsHelpSection.nav:
        return const _NavPreview();
      case SettingsHelpSection.widget:
        return const _WidgetPreview();
      case SettingsHelpSection.backup:
        return const _BackupPreview();
      case SettingsHelpSection.calendarSync:
        return const _CalendarSyncPreview();
      case SettingsHelpSection.app:
        return const _AppPreview();
      case SettingsHelpSection.category:
        return const _CategoryPreview();
    }
  }
}

class _HomeLayoutPreview extends StatelessWidget {
  const _HomeLayoutPreview();

  @override
  Widget build(BuildContext context) {
    return const _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.homePickCards,
          child: _HomeCardToggleDemo(),
        ),
        _PreviewFrame(
          caption: AppStrings.homeShowLeftover,
          child: _FakeLeftoverPeek(),
        ),
        _PreviewFrame(
          caption: AppStrings.homeReorderCards,
          child: _HomeReorderDemo(),
        ),
      ],
    );
  }
}

class _MonthlyStatsPreview extends StatelessWidget {
  const _MonthlyStatsPreview();

  @override
  Widget build(BuildContext context) {
    return const _StatsToggleDemo();
  }
}

class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview();

  @override
  Widget build(BuildContext context) {
    const weekStart = _CalendarSwitchDemo();
    const lunar = _LunarSwitchDemo();
    if (!showFontSizeSettings) {
      return const _CyclingPreview(
      frames: [
          _PreviewFrame(
            caption: AppStrings.calendarStartMonday,
            child: weekStart,
          ),
          _PreviewFrame(
            caption: AppStrings.calendarShowLunar,
            child: lunar,
          ),
        ],
      );
    }
    return const _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.calendarStartMonday,
          child: weekStart,
        ),
        _PreviewFrame(
          caption: AppStrings.calendarShowLunar,
          child: lunar,
        ),
        _PreviewFrame(
            caption: '${AppStrings.fontTodoSize} ${AppStrings.fontSizeLarge}',
            child: _FontPreviewCard(
              fontFamily: AppFonts.pretendard,
              todoScale: 1.14,
              calendarScale: 1,
              calendarLabelScale: 1,
            ),
          ),
        _PreviewFrame(
            caption: '${AppStrings.fontCalendarSize} ${AppStrings.fontSizeLarge}',
            child: _FontPreviewCard(
              fontFamily: AppFonts.pretendard,
              todoScale: 1,
              calendarScale: 1.14,
              calendarLabelScale: 1,
            ),
          ),
        _PreviewFrame(
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

enum _TodoHelpKind { sort, showTime, hour24, category, parseTitle }

class _TodoPreview extends StatelessWidget {
  const _TodoPreview();

  @override
  Widget build(BuildContext context) {
    return const _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.timeSortView,
          description: AppStrings.settingsTodoHelpSort,
          child: _TodoSettingsDemo(kind: _TodoHelpKind.sort),
        ),
        _PreviewFrame(
          caption: AppStrings.timeDisplay,
          description: AppStrings.settingsTodoHelpTime,
          child: _TodoSettingsDemo(kind: _TodoHelpKind.showTime),
        ),
        _PreviewFrame(
          caption: AppStrings.timeHour24,
          description: AppStrings.settingsTodoHelpHour24,
          child: _TodoSettingsDemo(kind: _TodoHelpKind.hour24),
        ),
        _PreviewFrame(
          caption: AppStrings.categoryView,
          description: AppStrings.settingsTodoHelpCategory,
          child: _TodoSettingsDemo(kind: _TodoHelpKind.category),
        ),
        _PreviewFrame(
          caption: AppStrings.parseTitleTime,
          description: AppStrings.settingsTodoHelpParse,
          child: _TodoSettingsDemo(kind: _TodoHelpKind.parseTitle),
        ),
      ],
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();

  static final _cards = [
    _FakeNotificationCard(title: '코딩테스트 준비', body: '10분 후 시작해요', time: '지금'),
        _FakeNotificationCard(
          title: '오늘의 일정 3개',
          body: '자기소개서 제출, 코딩테스트 준비, 면접 연습',
          time: '오전 8:00',
        ),
        _FakeNotificationCard(
      title: AppStrings.leftoverNotificationTitle(2),
          body: '자기소개서 제출, 면접 연습',
          time: '오후 9:00',
        ),
  ];

  @override
  Widget build(BuildContext context) {
    return _HelpSelectDemo(
      labels: const [
        AppStrings.todoNotificationSetting,
        AppStrings.summaryNotificationSetting,
        AppStrings.leftoverNotificationSetting,
      ],
      values: [
        AppStrings.notifyMinutes10,
        AppStrings.summaryTimeLabel(8 * 60),
        AppStrings.summaryTimeLabel(21 * 60),
      ],
      chevron: true,
      sceneHeight: 110,
      scene: (context, selected) {
        return _HelpSceneFill(
          child: _helpKeyedSwitch(switchKey: selected, child: _cards[selected]),
        );
      },
    );
  }
}

class _BackupPreview extends StatelessWidget {
  const _BackupPreview();

  static final _scenes = [
    _FakeBackupScene(
            icon: Icons.ios_share_rounded,
            title: AppStrings.backupSavedTitle,
            body: '플루토_백업.zip',
          ),
    _FakeBackupScene(
            icon: Icons.download_rounded,
            title: AppStrings.restoreDoneTitle,
            body: AppStrings.restoreDoneBody,
          ),
    _FakeBackupScene(
            icon: Icons.sync_rounded,
            title: AppStrings.autoBackupDaily,
      body: AppStrings.autoBackupHint(AppStrings.autoBackupDaily),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _HelpSelectDemo(
      labels: const [
        AppStrings.backupData,
        AppStrings.restoreData,
        AppStrings.autoBackupSetting,
      ],
      chevron: true,
      sceneHeight: 176,
      scene: (context, selected) {
        return _HelpSceneFill(
          child: _helpKeyedSwitch(
            switchKey: selected,
            child: _scenes[selected],
          ),
        );
      },
    );
  }
}

class _CalendarSyncPreview extends StatelessWidget {
  const _CalendarSyncPreview();

  @override
  Widget build(BuildContext context) {
    return _HelpSelectDemo(
      labels: const [
        AppStrings.importSamsungCalendar,
        AppStrings.importIosCalendar,
      ],
      chevron: true,
      sceneHeight: 176,
      scene: (context, selected) {
        return _HelpSceneFill(
          child: _helpKeyedSwitch(
            switchKey: selected,
          child: _FakeBackupScene(
            icon: Icons.event_available_rounded,
            title: AppStrings.importDoneTitle,
              body: AppStrings.importDoneBody(3),
            ),
          ),
        );
      },
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
                child: Icon(icon, size: 24, color: colors.accentBright),
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

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview();

  @override
  Widget build(BuildContext context) {
    return const ReleaseDemoView(demo: ReleaseDemo.categoryAi);
  }
}

class _AppPreview extends StatelessWidget {
  const _AppPreview();

  @override
  Widget build(BuildContext context) {
    return _HelpSelectDemo(
      labels: const [
        AppStrings.releaseNotesTitle,
        AppStrings.appTutorial,
        AppStrings.appContact,
        AppStrings.accountLogin,
      ],
      values: [ReleaseNotes.latestVersion, '', '', ''],
      chevron: true,
      chevrons: const [true, true, true, true],
      sceneHeight: 276,
      scene: (context, selected) {
        return _HelpSceneFill(
          child: _helpKeyedSwitch(
            switchKey: selected,
            child: selected == 0
                ? const _ReleaseNotesHelpDemo()
                : selected == 1
                    ? const _FakeTutorialPeek()
                    : selected == 2
                        ? const _ContactHelpDemo()
                        : const _AccountHelpDemo(),
          ),
        );
      },
    );
  }
}

class _ContactHelpDemo extends StatelessWidget {
  const _ContactHelpDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline_rounded,
              size: 28,
              color: colors.accentBright,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.appContact,
              style: TextStyle(
                fontFamily: font,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.appContactEmail,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: font,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountHelpDemo extends StatelessWidget {
  const _AccountHelpDemo();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 28,
              color: colors.accentBright,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.accountLogin,
              style: TextStyle(
                fontFamily: font,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.accountLoginBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.accountLoginPcHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HelpBrandCircle(
                  asset: AppIcons.kakaoLogo,
                  background: const Color(0xFFFEE500),
                ),
                const SizedBox(width: 10),
                _HelpBrandCircle(
                  asset: AppIcons.googleLogo,
                  background: Colors.white,
                  border: colors.border,
                ),
                const SizedBox(width: 10),
                _HelpBrandCircle(
                  asset: AppIcons.appleLogo,
                  background: const Color(0xFF111111),
                  tint: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpBrandCircle extends StatelessWidget {
  const _HelpBrandCircle({
    required this.asset,
    required this.background,
    this.border,
    this.tint,
  });

  final String asset;
  final Color background;
  final Color? border;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final tintColor = tint;
    final image = asset.endsWith('.svg')
        ? SvgPicture.asset(
            asset,
            width: 12,
            height: 12,
            colorFilter: tintColor == null
                ? null
                : ColorFilter.mode(tintColor, BlendMode.srcIn),
          )
        : Image.asset(
            asset,
            width: 12,
            height: 12,
            color: tint,
            colorBlendMode: BlendMode.srcIn,
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border!),
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(child: image),
      ),
    );
  }
}

class _FakeTutorialPeek extends StatelessWidget {
  const _FakeTutorialPeek();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.tutorialWelcomeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: font,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.tutorialWelcomeBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: font,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseNotesHelpDemo extends StatefulWidget {
  const _ReleaseNotesHelpDemo();

  @override
  State<_ReleaseNotesHelpDemo> createState() => _ReleaseNotesHelpDemoState();
}

class _ReleaseNotesHelpDemoState extends State<_ReleaseNotesHelpDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final note = ReleaseNotes.all.first;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final tap = _helpPulse(t, 0.18, 0.28, 0.42);
        final sheet = Curves.easeOutCubic.transform(_helpGate(t, 0.30, 0.48));
        return Stack(
          children: [
            const Align(
              alignment: Alignment.topCenter,
              child: _FakeReleaseNotesCard(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, (1 - sheet) * 80),
                child: Opacity(
                  opacity: sheet,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 28,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.releaseNotesPreview,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.muted,
                            ),
                          ),
                          Text(
                            note.version,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                          if (note.items.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.tint(colors.accentBright, 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  note.items.first,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    color: colors.accentBright,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 36,
                top: 28,
                child: _HelpFinger(pressed: tap, opacity: tap),
              ),
          ],
        );
      },
    );
  }
}

class _FakeReleaseNotesCard extends StatelessWidget {
  const _FakeReleaseNotesCard();

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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.version,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: colors.text,
              ),
            ),
            if (note.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.releaseNotesFeatures,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 4),
              _FakeReleaseBullet(note.items.first),
            ],
            if (note.fixes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.releaseNotesFixes,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 4),
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
        SizedBox(width: 14, child: Text('·', style: style)),
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

  static const _faces = [
    AppTypeface.pretendard,
    AppTypeface.theJamsil,
    AppTypeface.bazzi,
  ];

  @override
  Widget build(BuildContext context) {
    return _CyclingPreview(
      frames: [
        _PreviewFrame(
          caption: AppStrings.fontFamily,
          child: _HelpSelectDemo(
            showCaption: false,
            labels: [for (final face in _faces) _typefaceCaption(face)],
            sceneHeight: 168,
            scene: (context, selected) {
              return _FontDemoScene(typeface: _faces[selected]);
            },
          ),
        ),
        const _PreviewFrame(
          caption: AppStrings.fontLabelScale,
          child: _FontScaleDemo(kind: _FontScaleKind.label),
          ),
        const _PreviewFrame(
          caption: AppStrings.fontCalendarChipScale,
          child: _FontScaleDemo(kind: _FontScaleKind.calendar),
        ),
        const _PreviewFrame(
          caption: AppStrings.fontCalendarDateScale,
          child: _FontScaleDemo(kind: _FontScaleKind.date),
        ),
      ],
    );
  }
}

String _typefaceCaption(AppTypeface typeface) {
  return switch (typeface) {
    AppTypeface.pretendard => AppStrings.fontPretendard,
    AppTypeface.theJamsil => AppStrings.fontTheJamsil,
    AppTypeface.bazzi => AppStrings.fontBazzi,
    _ => AppStrings.fontFamily,
  };
}

class _FontDemoScene extends StatelessWidget {
  const _FontDemoScene({
    this.typeface,
    this.labelScale,
    this.calendarLabelScale,
    this.calendarDateScale,
  });

  final AppTypeface? typeface;
  final double? labelScale;
  final double? calendarLabelScale;
  final double? calendarDateScale;

  @override
  Widget build(BuildContext context) {
    final current = FontScope.maybeOf(context);
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.groupedBackground,
      child: FontScope(
        typeface: typeface ?? current?.typeface ?? AppTypeface.pretendard,
      todoScale: current?.todoScale ?? 1,
      labelScale: labelScale ?? current?.labelScale ?? 1,
      calendarScale: current?.calendarScale ?? 1,
      calendarLabelScale:
          calendarLabelScale ?? current?.calendarLabelScale ?? 1,
      calendarDateScale:
          calendarDateScale ?? current?.calendarDateScale ?? 1,
      child: Builder(
        builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Align(
                alignment: Alignment.bottomCenter,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final day in [8, 9, 10, 11, 12, 13, 14])
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final dateScale =
                                  AppFonts.calendarDateScaleOf(context);
                              final showLunar = AppScope.of(context)
                                  .calendarPreference
                                  .showLunar;
                              final now = DateTime.now();
                              return Column(
                                children: [
                                  Text(
                                    '$day',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppFonts.of(context),
                                      fontSize: 12 * dateScale,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                      color: colors.text,
                                    ),
                                  ),
                                  if (showLunar) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      LunarDate.labelOf(
                                            DateTime(now.year, now.month, day),
                                          ) ??
                                          '',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppFonts.of(context),
                                        fontSize: 9 * dateScale,
                                        fontWeight: FontWeight.w500,
                                        height: 1.1,
                                        color: colors.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
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
      ),
    );
  }
}

class _FontScaleKind {
  static const label = 0;
  static const calendar = 1;
  static const date = 2;
}

class _FontScaleDemo extends StatefulWidget {
  const _FontScaleDemo({required this.kind});

  final int kind;

  @override
  State<_FontScaleDemo> createState() => _FontScaleDemoState();
}

class _FontScaleDemoState extends State<_FontScaleDemo>
    with SingleTickerProviderStateMixin {
  static const _sceneHeight = 168.0;
  static const _sliderHeight = 52.0;
  static const _thumb = 14.0;

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double _progress(double t) {
    if (t < 0.18) return 0;
    if (t < 0.48) {
      return Curves.easeInOutCubic.transform(_helpGate(t, 0.18, 0.48));
    }
    if (t < 0.58) return 1;
    if (t < 0.88) {
      return 1 - Curves.easeInOutCubic.transform(_helpGate(t, 0.58, 0.88));
    }
    return 0;
  }

  double _fingerOpacity(double t) {
    if (t < 0.08) return 0;
    if (t < 0.16) return _helpGate(t, 0.08, 0.16);
    if (t < 0.90) return 1;
    if (t < 0.96) return 1 - _helpGate(t, 0.90, 0.96);
    return 0;
  }

  double _fingerPress(double t) {
    final dragging = (t >= 0.18 && t <= 0.48) || (t >= 0.58 && t <= 0.88);
    return dragging ? 1 : (t >= 0.16 && t <= 0.90 ? 0.35 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final steps = FontPreference.scaleSteps;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final progress = _progress(t);
        final scale =
            FontPreference.minScale +
            (FontPreference.maxScale - FontPreference.minScale) * progress;
        final finger = _fingerOpacity(t);
        final press = _fingerPress(t);
        final labelScale = widget.kind == _FontScaleKind.label ? scale : 1.0;
        final calendarScale = widget.kind == _FontScaleKind.calendar
            ? scale
            : 1.0;
        final dateScale = widget.kind == _FontScaleKind.date ? scale : 1.0;
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: _sceneHeight + _sliderHeight,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const pad = 22.0;
                    final track = (constraints.maxWidth - pad * 2 - _thumb)
                        .clamp(1.0, constraints.maxWidth);
                    final thumbX = pad + _thumb / 2 + track * progress;
                    return Stack(
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              height: _sceneHeight,
                              width: double.infinity,
                              child: ClipRect(
                                child: _FontDemoScene(
                                  labelScale: labelScale,
                                  calendarLabelScale: calendarScale,
                                  calendarDateScale: dateScale,
                                ),
                              ),
                            ),
                            ColoredBox(
                              color: colors.card,
                              child: SizedBox(
                                height: _sliderHeight,
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: pad,
                                  ),
                                  child: CustomPaint(
                                    painter: _FontScaleTrackPainter(
                                      progress: progress,
                                      count: steps.length,
                                      color: colors.accentBright,
                                      inactive: colors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (finger > 0)
                          Positioned(
                            left: thumbX - 14,
                            top: _sceneHeight + (_sliderHeight - 28) / 2,
                            child: _HelpFinger(pressed: press, opacity: finger),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FontScaleTrackPainter extends CustomPainter {
  const _FontScaleTrackPainter({
    required this.progress,
    required this.count,
    required this.color,
    required this.inactive,
  });

  final double progress;
  final int count;
  final Color color;
  final Color inactive;

  @override
  void paint(Canvas canvas, Size size) {
    const thumb = 7.0;
    const trackH = 4.0;
    final cy = size.height / 2;
    final start = thumb;
    final end = size.width - thumb;
    final trackW = end - start;
    final track = RRect.fromLTRBR(
      start - trackH / 2,
      cy - trackH / 2,
      end + trackH / 2,
      cy + trackH / 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(track, Paint()..color = inactive);
    final thumbX = start + trackW * progress.clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromLTRBR(
        start - trackH / 2,
        cy - trackH / 2,
        thumbX + trackH / 2,
        cy + trackH / 2,
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
    for (var i = 0; i < count; i++) {
      final x = start + trackW * (count <= 1 ? 0 : i / (count - 1));
      final passed = i / (count - 1) <= progress + 0.001;
      canvas.drawCircle(
        Offset(x, cy),
        2.2,
        Paint()..color = passed ? Colors.white : color,
      );
    }
    canvas.drawCircle(Offset(thumbX, cy), thumb, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FontScaleTrackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.inactive != inactive;
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

  static const _skins = [AppSkin.classic, AppSkin.blossom, AppSkin.catVillage];

  @override
  Widget build(BuildContext context) {
    return _HelpSelectDemo(
      labels: [for (final skin in _skins) _themeCaption(skin)],
      scene: (context, selected) {
        return AppSkinBackground(
          skin: _skins[selected],
          animate: true,
          liftForNav: false,
          scaleByWidth: true,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _FakeHomeCard(
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
          ),
        );
      },
    );
  }
}

class _WidgetPreview extends StatefulWidget {
  const _WidgetPreview();

  @override
  State<_WidgetPreview> createState() => _WidgetPreviewState();
}

class _WidgetPreviewState extends State<_WidgetPreview>
    with SingleTickerProviderStateMixin {
  static const _sceneHeight = 168.0;
  static const _rowHeight = 44.0;
  static const _labels = [
    AppStrings.widgetFollowTheme,
    AppStrings.widgetFollowFont,
  ];

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double _fingerRow(double t) {
    if (t < 0.38) return 0;
    if (t < 0.48) {
      return Curves.easeInOutCubic.transform(_helpGate(t, 0.38, 0.48));
    }
    return 1;
  }

  double _fingerOpacity(double t) {
    if (t < 0.08) return 0;
    if (t < 0.16) return _helpGate(t, 0.08, 0.16);
    if (t < 0.88) return 1;
    if (t < 0.96) return 1 - _helpGate(t, 0.88, 0.96);
    return 0;
  }

  double _fingerPress(double t) {
    final a = _helpPulse(t, 0.18, 0.26, 0.36);
    final b = _helpPulse(t, 0.48, 0.56, 0.66);
    return a > b ? a : b;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final themeOn = t < 0.22
            ? 0.0
            : Curves.easeOutCubic.transform(_helpGate(t, 0.22, 0.32));
        final fontOn = t < 0.50
            ? 0.0
            : Curves.easeOutCubic.transform(_helpGate(t, 0.50, 0.60));
        final ons = [themeOn, fontOn];
        final finger = _fingerOpacity(t);
        final press = _fingerPress(t);
        final fingerRow = _fingerRow(t);
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: _sceneHeight + _rowHeight * _labels.length,
                width: double.infinity,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: _sceneHeight,
                          width: double.infinity,
                          child: ColoredBox(
                            color: Color.lerp(
                              const Color(0xFFF1F5F9),
                              const Color(0xFFFFF1F2),
                              themeOn,
                            )!,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                              child: Align(
                                child: _FakeWidgetCard(
                                  themeOn: themeOn,
                                  fontOn: fontOn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ColoredBox(
                          color: colors.card,
                          child: Column(
                            children: [
                              for (var i = 0; i < _labels.length; i++)
                                _HelpSwitchRow(
                                  label: _labels[i],
                                  on: ons[i],
                                  height: _rowHeight,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (finger > 0)
                      Positioned(
                        right: 26,
                        top:
                            _sceneHeight +
                            fingerRow * _rowHeight +
                            (_rowHeight - 28) / 2,
                        child: _HelpFinger(pressed: press, opacity: finger),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FakeWidgetCard extends StatelessWidget {
  const _FakeWidgetCard({
    required this.themeOn,
    required this.fontOn,
  });

  final double themeOn;
  final double fontOn;

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF0F172A);
    final font = fontOn > 0.45 ? AppFonts.pretendard : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, const Color(0xFFFFF1F2), themeOn),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: AppStrings.todayTitle,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: text,
                    ),
                  ),
                  TextSpan(
                    text: '  9월 1일',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF3B82F6),
                      const Color(0xFFFB7185),
                      themeOn,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 7, height: 7),
                ),
                const SizedBox(width: 6),
                Text(
                  '자기소개서 제출',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: text,
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

String _themeCaption(AppSkin skin) {
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

class _HelpSelectDemo extends StatefulWidget {
  const _HelpSelectDemo({
    required this.labels,
    required this.scene,
    this.sceneHeight = 188,
    this.showCaption = true,
    this.chevron = false,
    this.chevrons,
    this.values,
    this.themeOf,
  });

  final List<String> labels;
  final Widget Function(BuildContext context, int selected) scene;
  final double sceneHeight;
  final bool showCaption;
  final bool chevron;
  final List<bool>? chevrons;
  final List<String>? values;
  final ThemeData Function(int selected)? themeOf;

  @override
  State<_HelpSelectDemo> createState() => _HelpSelectDemoState();
}

class _HelpSelectDemoState extends State<_HelpSelectDemo>
    with SingleTickerProviderStateMixin {
  static const _rowHeight = 40.0;

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.labels.length >= 3 ? 5600 : 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  int _selected(double t) {
    final n = widget.labels.length;
    if (n <= 1) return 0;
    if (n == 2) return t < 0.42 ? 0 : 1;
    if (t < 0.42) return 0;
    if (t < 0.74) return 1;
    return 2;
  }

  double _fingerRow(double t) {
    final n = widget.labels.length;
    if (n <= 1) return 0;
    if (n == 2) return 1;
    if (t < 0.30) return 0;
    if (t < 0.42) {
      return Curves.easeInOutCubic.transform(_helpGate(t, 0.30, 0.42));
    }
    if (t < 0.62) return 1;
    if (t < 0.74) {
      return 1 + Curves.easeInOutCubic.transform(_helpGate(t, 0.62, 0.74));
    }
    return 2;
  }

  double _fingerOpacity(double t) {
    if (widget.labels.length == 2) {
      if (t < 0.12) return 0;
      if (t < 0.20) return _helpGate(t, 0.12, 0.20);
      if (t < 0.78) return 1;
      if (t < 0.88) return 1 - _helpGate(t, 0.78, 0.88);
      return 0;
    }
    if (t < 0.04) return 0;
    if (t < 0.12) return _helpGate(t, 0.04, 0.12);
    if (t < 0.90) return 1;
    if (t < 0.98) return 1 - _helpGate(t, 0.90, 0.98);
    return 0;
  }

  double _fingerPress(double t) {
    if (widget.labels.length == 2) {
      return _helpPulse(t, 0.22, 0.32, 0.46);
    }
    final a = _helpPulse(t, 0.10, 0.18, 0.28);
    final b = _helpPulse(t, 0.42, 0.50, 0.60);
    final c = _helpPulse(t, 0.74, 0.82, 0.90);
    return [a, b, c].reduce((x, y) => x > y ? x : y);
  }

  Widget _card({
    required BuildContext context,
    required int selected,
    required double finger,
    required double press,
    required double fingerRow,
  }) {
    final colors = AppColors.of(context);
    final labels = widget.labels;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: widget.sceneHeight + _rowHeight * labels.length,
          width: double.infinity,
          child: Stack(
                children: [
              Column(
                    children: [
                  SizedBox(
                    height: widget.sceneHeight,
                    width: double.infinity,
                    child: ClipRect(
                      child: widget.scene(context, selected),
                    ),
                  ),
                  ColoredBox(
                    color: colors.card,
                    child: Column(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          _HelpSelectRow(
                            label: labels[i],
                            selected: selected == i,
                            height: _rowHeight,
                            chevron: widget.chevrons?[i] ?? widget.chevron,
                            value: widget.values == null
                                ? null
                                : widget.values![i],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (finger > 0)
                Positioned(
                  right: 28,
                  top:
                      widget.sceneHeight +
                      fingerRow * _rowHeight +
                      (_rowHeight - 28) / 2,
                  child: _HelpFinger(pressed: press, opacity: finger),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetColors = AppColors.of(context);
    final labels = widget.labels;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final selected = _selected(t).clamp(0, labels.length - 1).toInt();
        final finger = _fingerOpacity(t);
        final press = _fingerPress(t);
        final fingerRow = _fingerRow(t);
        final theme = widget.themeOf?.call(selected);
        final card = theme == null
            ? _card(
                context: context,
                selected: selected,
                finger: finger,
                press: press,
                fingerRow: fingerRow,
              )
            : Theme(
                data: theme,
                child: Builder(
                  builder: (context) {
                    return _card(
                      context: context,
                      selected: selected,
                      finger: finger,
                      press: press,
                      fingerRow: fingerRow,
                    );
                  },
                ),
              );
        return Column(
          children: [
            if (widget.showCaption) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: DecoratedBox(
                  key: ValueKey(labels[selected]),
                  decoration: BoxDecoration(
                    color: sheetColors.tint(sheetColors.accentBright, 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      labels[selected],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sheetColors.accentBright,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            IgnorePointer(child: card),
          ],
        );
      },
    );
  }
}

class _HelpSelectRow extends StatelessWidget {
  const _HelpSelectRow({
    required this.label,
    required this.selected,
    required this.height,
    this.chevron = false,
    this.value,
  });

  final String label;
  final bool selected;
  final double height;
  final bool chevron;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
      children: [
        Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.text,
                ),
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              Text(
                value!,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colors.muted,
                ),
              ),
              const SizedBox(width: 2),
            ],
            if (chevron)
              Icon(Icons.chevron_right_rounded, size: 22, color: colors.muted)
            else
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: selected ? 1 : 0,
                child: Icon(Icons.check_rounded, size: 20, color: colors.text),
              ),
          ],
        ),
      ),
    );
  }
}

class _HelpFinger extends StatelessWidget {
  const _HelpFinger({required this.pressed, required this.opacity});

  final double pressed;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final scale = 1 - pressed * 0.12;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _helpGate(double t, double a, double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return ((t - a) / (b - a)).clamp(0.0, 1.0);
}

double _helpPulse(double t, double a, double b, double c) {
  if (t < a) return 0;
  if (t < b) return _helpGate(t, a, b);
  if (t < c) return 1;
  return (1 - _helpGate(t, c, (c + 0.12).clamp(0.0, 1.0))).clamp(0.0, 1.0);
}

class _HelpSceneFill extends StatelessWidget {
  const _HelpSceneFill({
    required this.child,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.of(context).groupedBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Align(alignment: alignment, child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _helpKeyedSwitch({required Object switchKey, required Widget child}) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: KeyedSubtree(key: ValueKey(switchKey), child: child),
  );
}

class _NavPreview extends StatefulWidget {
  const _NavPreview();

  @override
  State<_NavPreview> createState() => _NavPreviewState();
}

class _NavPreviewState extends State<_NavPreview>
    with SingleTickerProviderStateMixin {
  static const _sceneHeight = 88.0;
  static const _rowHeight = 44.0;

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
              final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final jobOn = t >= 0.28 && t < 0.90;
        final statsOn = t < 0.68 || t >= 0.90;
        final finger = t < 0.10
            ? 0.0
            : t < 0.18
                ? _helpGate(t, 0.10, 0.18)
                : t < 0.86
                    ? 1.0
                    : t < 0.94
                        ? 1 - _helpGate(t, 0.86, 0.94)
                        : 0.0;
        final pressA = _helpPulse(t, 0.20, 0.28, 0.38);
        final pressB = _helpPulse(t, 0.60, 0.68, 0.78);
        final press = pressA > pressB ? pressA : pressB;
        final fingerOnStats = t >= 0.48;
        return IgnorePointer(
          child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: _sceneHeight + _rowHeight * 2,
                width: double.infinity,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: _sceneHeight,
                          width: double.infinity,
                          child: ColoredBox(
                            color: colors.groupedBackground,
                            child: Center(
                              child: PillBottomNav(
                                currentIndex: 1,
                                showStats: statsOn,
                                showJob: jobOn,
                                tutorial: false,
                                embedded: true,
                                onChanged: (_) {},
                              ),
                            ),
                          ),
                        ),
                        ColoredBox(
                          color: colors.card,
                          child: _HelpSwitchRow(
                            label: AppStrings.jobMode,
                            on: jobOn ? 1 : 0,
                            height: _rowHeight,
                          ),
                        ),
                        ColoredBox(
                          color: colors.card,
                          child: _HelpSwitchRow(
                            label: AppStrings.statsTab,
                            on: statsOn ? 1 : 0,
                            height: _rowHeight,
                          ),
                        ),
                      ],
                    ),
                    if (finger > 0)
                      Positioned(
                        right: 28,
                        top: _sceneHeight +
                            (fingerOnStats ? _rowHeight : 0) +
                            (_rowHeight - 28) / 2,
                        child: _HelpFinger(pressed: press, opacity: finger),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  const _AppearancePreview();

  @override
  Widget build(BuildContext context) {
    return _HelpSelectDemo(
      labels: const [AppStrings.lightMode, AppStrings.darkMode],
      sceneHeight: 188,
      themeOf: (selected) => selected == 0 ? AppTheme.light : AppTheme.dark,
      scene: (context, selected) {
        final theme = selected == 0 ? AppTheme.light : AppTheme.dark;
        return _helpKeyedSwitch(
          switchKey: selected,
          child: Theme(
            data: theme,
            child: Builder(
              builder: (context) {
                return ColoredBox(
                  color: AppColors.of(context).groupedBackground,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _FakeHomeCard(
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
                ),
              );
            },
          ),
        ),
        );
      },
    );
  }
}

class _PreviewFrame {
  const _PreviewFrame({
    required this.caption,
    required this.child,
    this.description,
  });

  final String caption;
  final Widget child;
  final String? description;
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
    final description = frame.description ?? '';

    final preview = Column(
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
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: !_canCycle
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 180) return;
              _goTo(velocity < 0 ? _index + 1 : _index - 1, fromUser: true);
            },
      child: description.isEmpty
          ? preview
          : Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Text(
                      description,
                      key: ValueKey(description),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.groupedBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      child: preview,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PreviewNavButton extends StatelessWidget {
  const _PreviewNavButton({required this.icon, required this.onPressed});

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
        child: Icon(icon, size: 26, color: colors.muted),
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

class _HomeCardToggleDemo extends StatefulWidget {
  const _HomeCardToggleDemo();

  @override
  State<_HomeCardToggleDemo> createState() => _HomeCardToggleDemoState();
}

class _HomeCardToggleDemoState extends State<_HomeCardToggleDemo>
    with SingleTickerProviderStateMixin {
  static const _sceneHeight = 220.0;
  static const _rowHeight = 44.0;
  static const _labels = [
    AppStrings.homeShowToday,
    AppStrings.homeShowTomorrow,
    AppStrings.homeShowWeek,
  ];

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double _fingerRow(double t) {
    if (t < 0.38) return 1;
    if (t < 0.48) {
      return 1 + Curves.easeInOutCubic.transform(_helpGate(t, 0.38, 0.48));
    }
    if (t < 0.66) return 2;
    if (t < 0.76) {
      return 2 - 2 * Curves.easeInOutCubic.transform(_helpGate(t, 0.66, 0.76));
    }
    return 0;
  }

  double _fingerOpacity(double t) {
    if (t < 0.08) return 0;
    if (t < 0.16) return _helpGate(t, 0.08, 0.16);
    if (t < 0.88) return 1;
    if (t < 0.96) return 1 - _helpGate(t, 0.88, 0.96);
    return 0;
  }

  double _fingerPress(double t) {
    final a = _helpPulse(t, 0.18, 0.26, 0.36);
    final b = _helpPulse(t, 0.48, 0.56, 0.66);
    final c = _helpPulse(t, 0.76, 0.84, 0.90);
    return [a, b, c].reduce((x, y) => x > y ? x : y);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final today = t < 0.76
            ? 1.0
            : 1 - Curves.easeOutCubic.transform(_helpGate(t, 0.76, 0.86));
        final tomorrow = t < 0.22
            ? 0.0
            : Curves.easeOutCubic.transform(_helpGate(t, 0.22, 0.32));
        final week = t < 0.50
            ? 0.0
            : Curves.easeOutCubic.transform(_helpGate(t, 0.50, 0.60));
        final ons = [today, tomorrow, week];
        final finger = _fingerOpacity(t);
        final press = _fingerPress(t);
        final fingerRow = _fingerRow(t);
        return IgnorePointer(
          child: DecoratedBox(
      decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: _sceneHeight + _rowHeight * _labels.length,
                width: double.infinity,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: _sceneHeight,
                          width: double.infinity,
                          child: ColoredBox(
                            color: colors.groupedBackground,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                14,
                                12,
                                10,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      _HomeCollapsingCard(
                                        open: today,
                                        child: const _HomePeekCard(
                                          title: AppStrings.todayTitle,
                                          date: '8. 19. (수)',
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                      _HomeCollapsingCard(
                                        open: tomorrow,
                                        child: const _HomePeekCard(
                                          title: AppStrings.tomorrowTitle,
                                          date: '8. 20. (목)',
                                          color: Color(0xFF22C55E),
                                        ),
                                      ),
                                      _HomeCollapsingCard(
                                        open: week,
                                        child: const _HomePeekCard(
                                          title: AppStrings.weekTitle,
                                          date: '8. 19. (수) - 8. 23. (일)',
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ColoredBox(
                          color: colors.card,
                          child: Column(
          children: [
                              for (var i = 0; i < _labels.length; i++)
                                _HelpSwitchRow(
                                  label: _labels[i],
                                  on: ons[i],
                                  height: _rowHeight,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (finger > 0)
                      Positioned(
                        right: 26,
                        top:
                            _sceneHeight +
                            fingerRow * _rowHeight +
                            (_rowHeight - 28) / 2,
                        child: _HelpFinger(pressed: press, opacity: finger),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeCollapsingCard extends StatelessWidget {
  const _HomeCollapsingCard({required this.open, required this.child});

  final double open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = open.clamp(0.0, 1.0);
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: visible,
        child: Opacity(
          opacity: visible,
          child: Padding(
            padding: EdgeInsets.only(bottom: 8 * visible),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _HomePeekCard extends StatelessWidget {
  const _HomePeekCard({
    required this.title,
    required this.date,
    required this.color,
  });

  final String title;
  final String date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
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
        child: Row(
          children: [
            ColoredBox(
              color: color,
              child: const SizedBox(width: 4, height: 36),
            ),
            const SizedBox(width: 10),
            Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                    title,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                      fontSize: 15,
                fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: colors.text,
              ),
            ),
                  const SizedBox(height: 2),
            Text(
                    date,
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
          ],
        ),
      ),
    );
  }
}

class _HelpSwitchRow extends StatelessWidget {
  const _HelpSwitchRow({
    required this.label,
    required this.on,
    required this.height,
  });

  final String label;
  final double on;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
      children: [
            Expanded(
              child: Text(
                label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
              color: colors.text,
            ),
              ),
              ),
            _HelpMiniSwitch(on: on),
            ],
          ),
        ),
    );
  }
}

class _CalendarSwitchDemo extends StatefulWidget {
  const _CalendarSwitchDemo();

  @override
  State<_CalendarSwitchDemo> createState() => _CalendarSwitchDemoState();
}

class _CalendarSwitchDemoState extends State<_CalendarSwitchDemo>
    with SingleTickerProviderStateMixin {
  static const _sceneHeight = 148.0;
  static const _rowHeight = 48.0;

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final monday = t < 0.22
            ? 0.0
            : t < 0.34
            ? Curves.easeOutCubic.transform(_helpGate(t, 0.22, 0.34))
            : t < 0.68
            ? 1.0
            : t < 0.80
            ? 1 - Curves.easeOutCubic.transform(_helpGate(t, 0.68, 0.80))
            : 0.0;
        final finger = () {
          if (t < 0.10) return 0.0;
          if (t < 0.18) return _helpGate(t, 0.10, 0.18);
          if (t < 0.40) return 1.0;
          if (t < 0.48) return 1 - _helpGate(t, 0.40, 0.48);
          if (t < 0.56) return 0.0;
          if (t < 0.64) return _helpGate(t, 0.56, 0.64);
          if (t < 0.86) return 1.0;
          if (t < 0.94) return 1 - _helpGate(t, 0.86, 0.94);
          return 0.0;
        }();
        final a = _helpPulse(t, 0.18, 0.26, 0.36);
        final b = _helpPulse(t, 0.64, 0.72, 0.82);
        final press = a > b ? a : b;
        final startMonday = monday > 0.5;
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: _sceneHeight + _rowHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: _sceneHeight,
                          width: double.infinity,
                          child: ColoredBox(
                            color: colors.groupedBackground,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                16,
                                12,
                                12,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 420),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: KeyedSubtree(
                                    key: ValueKey(startMonday),
                                    child: _FakeWeekStartCalendar(
                                      startMonday: startMonday,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ColoredBox(
                          color: colors.card,
                          child: _HelpSwitchRow(
                            label: AppStrings.calendarStartMonday,
                            on: monday,
                            height: _rowHeight,
              ),
            ),
          ],
                    ),
                    if (finger > 0)
                      Positioned(
                        right: 26,
                        top: _sceneHeight + (_rowHeight - 28) / 2,
                        child: _HelpFinger(pressed: press, opacity: finger),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LunarSwitchDemo extends StatefulWidget {
  const _LunarSwitchDemo();

  @override
  State<_LunarSwitchDemo> createState() => _LunarSwitchDemoState();
}

class _LunarSwitchDemoState extends State<_LunarSwitchDemo>
    with SingleTickerProviderStateMixin {
  static const _sceneHeight = 148.0;
  static const _rowHeight = 48.0;

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final on = t < 0.22
            ? 0.0
            : t < 0.34
            ? Curves.easeOutCubic.transform(_helpGate(t, 0.22, 0.34))
            : t < 0.68
            ? 1.0
            : t < 0.80
            ? 1 - Curves.easeOutCubic.transform(_helpGate(t, 0.68, 0.80))
            : 0.0;
        final finger = () {
          if (t < 0.10) return 0.0;
          if (t < 0.18) return _helpGate(t, 0.10, 0.18);
          if (t < 0.40) return 1.0;
          if (t < 0.48) return 1 - _helpGate(t, 0.40, 0.48);
          if (t < 0.56) return 0.0;
          if (t < 0.64) return _helpGate(t, 0.56, 0.64);
          if (t < 0.86) return 1.0;
          if (t < 0.94) return 1 - _helpGate(t, 0.86, 0.94);
          return 0.0;
        }();
        final a = _helpPulse(t, 0.18, 0.26, 0.36);
        final b = _helpPulse(t, 0.64, 0.72, 0.82);
        final press = a > b ? a : b;
        final showLunar = on > 0.5;
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: _sceneHeight + _rowHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: _sceneHeight,
                          width: double.infinity,
                          child: ColoredBox(
                            color: colors.groupedBackground,
                            child: Center(
                              child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colors.border.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 64,
                                  height: 72,
        child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                                        '15',
              style: TextStyle(
                                          fontFamily: font,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          color: colors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        opacity: showLunar ? 1 : 0,
                                        child: Text(
                                          '6.22',
              style: TextStyle(
                                            fontFamily: font,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: colors.muted,
                                          ),
              ),
            ),
          ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ColoredBox(
                          color: colors.card,
                          child: _HelpSwitchRow(
                            label: AppStrings.calendarShowLunar,
                            on: on,
                            height: _rowHeight,
                          ),
                        ),
                      ],
                    ),
                    if (finger > 0)
                      Positioned(
                        right: 26,
                        top: _sceneHeight + (_rowHeight - 28) / 2,
                        child: _HelpFinger(pressed: press, opacity: finger),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsToggleDemo extends StatefulWidget {
  const _StatsToggleDemo();

  @override
  State<_StatsToggleDemo> createState() => _StatsToggleDemoState();
}

class _StatsToggleDemoState extends State<_StatsToggleDemo>
    with SingleTickerProviderStateMixin {
  static const _sceneHeight = 268.0;
  static const _rowHeight = 44.0;
  static const _labels = [
    AppStrings.homeShowWeeklyStats,
    AppStrings.homeShowMonthlyStats,
  ];

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double _fingerRow(double t) {
    if (t < 0.38) return 0;
    if (t < 0.48) {
      return Curves.easeInOutCubic.transform(_helpGate(t, 0.38, 0.48));
    }
    return 1;
  }

  double _fingerOpacity(double t) {
    if (t < 0.08) return 0;
    if (t < 0.16) return _helpGate(t, 0.08, 0.16);
    if (t < 0.88) return 1;
    if (t < 0.96) return 1 - _helpGate(t, 0.88, 0.96);
    return 0;
  }

  double _fingerPress(double t) {
    final a = _helpPulse(t, 0.18, 0.26, 0.36);
    final b = _helpPulse(t, 0.48, 0.56, 0.66);
    return a > b ? a : b;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final weekly = t < 0.22
            ? 0.0
            : Curves.easeOutCubic.transform(_helpGate(t, 0.22, 0.32));
        final monthly = t < 0.50
            ? 0.0
            : Curves.easeOutCubic.transform(_helpGate(t, 0.50, 0.60));
        final ons = [weekly, monthly];
        final finger = _fingerOpacity(t);
        final press = _fingerPress(t);
        final fingerRow = _fingerRow(t);
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: _sceneHeight + _rowHeight * _labels.length,
                width: double.infinity,
                child: Stack(
      children: [
                    Column(
                      children: [
                        SizedBox(
                          height: _sceneHeight,
                          width: double.infinity,
                          child: ColoredBox(
                            color: colors.groupedBackground,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                14,
                                12,
                                10,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
                                      _HomeCollapsingCard(
                                        open: weekly,
                                        child: const _FakeStatsPeek(
                                          headline:
                                              AppStrings.weeklyStatsHeadline,
                                          todoCount: 8,
                                          rate: 80,
                                          diaryCount: 3,
                                          ledgerCount: 6,
                                        ),
                                      ),
                                      _HomeCollapsingCard(
                                        open: monthly,
                                        child: _FakeStatsPeek(
                                          headline:
                                              AppStrings.monthlyStatsHeadlineMonth(
                                                7,
                                              ),
                                          todoCount: 12,
                                          rate: 67,
                                          roundCount: 5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ColoredBox(
                          color: colors.card,
                          child: Column(
                children: [
                              for (var i = 0; i < _labels.length; i++)
                                _HelpSwitchRow(
                                  label: _labels[i],
                                  on: ons[i],
                                  height: _rowHeight,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (finger > 0)
                      Positioned(
                        right: 26,
                        top:
                            _sceneHeight +
                            fingerRow * _rowHeight +
                            (_rowHeight - 28) / 2,
                        child: _HelpFinger(pressed: press, opacity: finger),
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodoSettingsDemo extends StatefulWidget {
  const _TodoSettingsDemo({required this.kind});

  final _TodoHelpKind kind;

  @override
  State<_TodoSettingsDemo> createState() => _TodoSettingsDemoState();
}

class _TodoSettingsDemoState extends State<_TodoSettingsDemo>
    with SingleTickerProviderStateMixin {
  static const _rowHeight = 44.0;
  static const _itemH = 46.0;
  static const _gap = 6.0;
  static const _headerH = 22.0;
  static const _titles = ['면접 연습', '자기소개서 제출', '코딩테스트 준비'];
  static const _categories = ['면접', '서류', '코딩테스트'];
  static const _colors = [
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
  ];
  static const _times24 = ['16:00', '09:00', '14:00'];
  static const _times12 = ['오후 4:00', '오전 9:00', '오후 2:00'];
  static const _sortedSlot = [2.0, 0.0, 1.0];

  late final AnimationController _loop;

  bool get _isParse => widget.kind == _TodoHelpKind.parseTitle;

  double get _sceneHeight {
    switch (widget.kind) {
      case _TodoHelpKind.category:
        return 300;
      case _TodoHelpKind.parseTitle:
        return 220;
      default:
        return 220;
    }
  }

  String get _label {
    switch (widget.kind) {
      case _TodoHelpKind.sort:
        return AppStrings.timeSortView;
      case _TodoHelpKind.showTime:
        return AppStrings.timeDisplay;
      case _TodoHelpKind.hour24:
        return AppStrings.timeHour24;
      case _TodoHelpKind.category:
        return AppStrings.categoryView;
      case _TodoHelpKind.parseTitle:
        return AppStrings.parseTitleTime;
    }
  }

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isParse ? 6000 : 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double _toggle(double t) {
    if (t < 0.22) return 0;
    if (t < 0.34) {
      return Curves.easeOutCubic.transform(_helpGate(t, 0.22, 0.34));
    }
    if (t < 0.68) return 1;
    if (t < 0.80) {
      return 1 - Curves.easeOutCubic.transform(_helpGate(t, 0.68, 0.80));
    }
    return 0;
  }

  double _switchFinger(double t) {
    if (t < 0.10) return 0;
    if (t < 0.18) return _helpGate(t, 0.10, 0.18);
    if (t < 0.40) return 1;
    if (t < 0.48) return 1 - _helpGate(t, 0.40, 0.48);
    if (t < 0.56) return 0;
    if (t < 0.64) return _helpGate(t, 0.56, 0.64);
    if (t < 0.86) return 1;
    if (t < 0.94) return 1 - _helpGate(t, 0.86, 0.94);
    return 0;
  }

  double _switchPress(double t) {
    final a = _helpPulse(t, 0.18, 0.26, 0.36);
    final b = _helpPulse(t, 0.64, 0.72, 0.82);
    return a > b ? a : b;
  }

  double _parseApplied(double t) {
    return Curves.easeOutCubic.transform(_helpGate(t, 0.58, 0.74));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        if (_isParse) {
          return IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: colors.groupedBackground,
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _parseForm(context, t),
                  ),
                ),
              ),
            ),
          );
        }
        final on = _toggle(t);
        final finger = _switchFinger(t);
        final press = _switchPress(t);
        return IgnorePointer(
          child: Column(
            children: [
              SizedBox(
                height: _sceneHeight,
                width: double.infinity,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _scene(context, t, on),
                      ),
                    ),
                  ),
                ),
              ),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: colors.card,
                      child: _HelpSwitchRow(
                        label: _label,
                        on: on,
                        height: _rowHeight,
                      ),
                    ),
                  ),
                  if (finger > 0)
                    Positioned(
                      right: 16,
                      top: (_rowHeight - 28) / 2,
                      child: _HelpFinger(pressed: press, opacity: finger),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scene(BuildContext context, double t, double on) {
    final slot = _itemH + _gap;
    final listH = widget.kind == _TodoHelpKind.category
        ? lerpDouble(
            _itemH * 3 + _gap * 2,
            _headerH * 3 + _itemH * 3 + _gap * 2,
            on,
          )!
        : _itemH * 3 + _gap * 2;
    return _FakeHomeCard(
      title: AppStrings.todayTitle,
      children: [
        SizedBox(
          width: double.infinity,
          height: listH,
          child: Stack(
            children: [
              if (widget.kind == _TodoHelpKind.category)
                for (var i = 0; i < _titles.length; i++)
                  Positioned(
                    top: lerpDouble(i * slot, i * (_headerH + slot), on)!,
                    left: 0,
                    right: 0,
                    height: 16,
                    child: Opacity(
                      opacity: on.clamp(0.0, 1.0),
                      child: _FakeCategoryDotHeader(
                        name: _categories[i],
                        color: _colors[i],
                      ),
                    ),
                  ),
              for (var i = 0; i < _titles.length; i++)
                Positioned(
                  top: _itemTop(i, on, slot),
                  left: 0,
                  right: 0,
                  height: _itemH,
                  child: _FakeTodo(
                    title: _titles[i],
                    category: _categories[i],
                    color: _colors[i],
                    timeText: _timeText(i, on),
                    timeOpacity: _timeOpacity(on),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  double _itemTop(int i, double on, double slot) {
    switch (widget.kind) {
      case _TodoHelpKind.sort:
        return lerpDouble(i.toDouble(), _sortedSlot[i], on)! * slot;
      case _TodoHelpKind.category:
        return lerpDouble(i * slot, i * (_headerH + slot) + _headerH, on)!;
      default:
        return i * slot;
    }
  }

  String? _timeText(int i, double on) {
    switch (widget.kind) {
      case _TodoHelpKind.sort:
      case _TodoHelpKind.showTime:
        return _times24[i];
      case _TodoHelpKind.hour24:
        return on > 0.5 ? _times24[i] : _times12[i];
      default:
        return null;
    }
  }

  double _timeOpacity(double on) {
    switch (widget.kind) {
      case _TodoHelpKind.sort:
      case _TodoHelpKind.hour24:
        return 1;
      case _TodoHelpKind.showTime:
        return on;
      default:
        return 0;
    }
  }

  Widget _parseForm(BuildContext context, double t) {
    const full = '면접 연습 14시';
    const markAt = 6;
    const color = Color(0xFF22C55E);
    final font = AppFonts.of(context);
    final colors = AppColors.of(context);
    final typed = (full.length * _helpGate(t, 0.08, 0.36)).round();
    final shown = full.substring(0, typed);
    final saved = _parseApplied(t) > 0.45;
    final caretOn = t < 0.36 && (t * 12).floor().isEven;
    final title = saved ? '면접 연습' : shown;
    void noop() {}
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tint(color, 0.14),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  if (title.isEmpty)
                    TextSpan(
                      text: AppStrings.eventTitleHint,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.hint,
                      ),
                    )
                  else if (saved || title.length <= markAt)
                    TextSpan(
                      text: title,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    )
                  else ...[
                    TextSpan(
                      text: full.substring(0, markAt),
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    TextSpan(
                      text: title.substring(markAt),
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                        backgroundColor: color.withValues(alpha: 0.28),
                      ),
                    ),
                  ],
                  if (title.isNotEmpty && caretOn)
                    TextSpan(
                      text: '|',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: [
                        EventCategoryChip(
                          name: '면접',
                          color: color,
                          onPressed: noop,
                        ),
                        const SizedBox(width: 4),
                        EventDateChip(
                          date: DateTime(2026, 9, 11),
                          color: color,
                          onPressed: noop,
                        ),
                        const SizedBox(width: 4),
                        EventTimeChip(
                          color: color,
                          startMinutes: saved ? 14 * 60 : null,
                          onPressed: noop,
                        ),
                        const SizedBox(width: 4),
                        EventActionIcon(
                          label: AppStrings.memoAction,
                          color: color,
                          onPressed: noop,
                          child: const AppAssetImage(
                            asset: AppIcons.memoOutlined,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SaveCompanyButton(onPressed: noop, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeReorderDemo extends StatefulWidget {
  const _HomeReorderDemo();

  @override
  State<_HomeReorderDemo> createState() => _HomeReorderDemoState();
}

class _HomeReorderDemoState extends State<_HomeReorderDemo>
    with SingleTickerProviderStateMixin {
  static const _cardH = 44.0;
  static const _gap = 8.0;

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, child) {
        final t = _loop.value;
        final move = t < 0.22
            ? 0.0
            : t < 0.48
            ? Curves.easeInOutCubic.transform(_helpGate(t, 0.22, 0.48))
            : t < 0.78
            ? 1.0
            : t < 0.92
            ? 1 - Curves.easeInOutCubic.transform(_helpGate(t, 0.78, 0.92))
            : 0.0;
        final finger = () {
          if (t < 0.10) return 0.0;
          if (t < 0.18) return _helpGate(t, 0.10, 0.18);
          if (t < 0.88) return 1.0;
          if (t < 0.96) return 1 - _helpGate(t, 0.88, 0.96);
          return 0.0;
        }();
        final press = (t >= 0.16 && t <= 0.86) ? 0.7 : 0.0;
        final travel = _cardH + _gap;
        return IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: ColoredBox(
                color: colors.groupedBackground,
                child: SizedBox(
                  height: 168,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                        child: Stack(
                          children: [
                            _HomeMiniCard(
                              title: AppStrings.homeShowToday,
                              top: 8 + travel * move,
                              lifted: false,
                            ),
                            _HomeMiniCard(
                              title: AppStrings.homeShowTomorrow,
                              top: 8 + travel - travel * move,
                              lifted: move > 0.04 && move < 0.96,
                            ),
                          ],
                        ),
                      ),
                      if (finger > 0)
                        Positioned(
                          right: 36,
                          top: 18 + 8 + travel - travel * move + 8,
                          child: _HelpFinger(pressed: press, opacity: finger),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeMiniCard extends StatelessWidget {
  const _HomeMiniCard({
    required this.title,
    required this.top,
    required this.lifted,
  });

  final String title;
  final double top;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
          boxShadow: lifted
              ? [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpMiniSwitch extends StatelessWidget {
  const _HelpMiniSwitch({required this.on});

  final double on;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: 24,
      child: FittedBox(
        child: SizedBox(
          width: 51,
          height: 31,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(colors.border, colors.accentBright, on),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  on,
                )!,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const SizedBox(width: 27, height: 27),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FakeStatsPeek extends StatelessWidget {
  const _FakeStatsPeek({
    required this.headline,
    required this.todoCount,
    required this.rate,
    this.roundCount,
    this.diaryCount,
    this.ledgerCount,
  });

  final String headline;
  final int todoCount;
  final int rate;
  final int? roundCount;
  final int? diaryCount;
  final int? ledgerCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return DecoratedBox(
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
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: colors.text,
                ),
                children: [
                  TextSpan(text: '$headline\n'),
                  TextSpan(
                    text: AppStrings.monthlyStatsTodoCount(todoCount),
                    style: TextStyle(color: colors.accent),
                  ),
                  if (roundCount != null) ...[
                    TextSpan(text: AppStrings.monthlyStatsCompleteAnd),
                    const TextSpan(text: '\n'),
                    TextSpan(
                      text: AppStrings.monthlyStatsRoundCount(roundCount!),
                      style: TextStyle(color: colors.accent),
                    ),
                    TextSpan(text: AppStrings.monthlyStatsRoundsTail),
                  ] else
                    TextSpan(text: AppStrings.monthlyStatsCompletedTail),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FakeStatsTile(
                    label: AppStrings.monthlyStatsCompletedLabel,
                    value: '$todoCount',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _FakeStatsTile(
                    label: AppStrings.monthlyStatsRateLabel,
                    value: AppStrings.monthlyStatsRateValue(rate),
                  ),
                ),
              ],
            ),
            if (diaryCount != null || ledgerCount != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (diaryCount != null)
                    Expanded(
                      child: _FakeStatsTile(
                        label: AppStrings.monthlyStatsDiaryCountLabel,
                        value: '$diaryCount',
                      ),
                    ),
                  if (diaryCount != null && ledgerCount != null)
                    const SizedBox(width: 6),
                  if (ledgerCount != null)
                    Expanded(
                      child: _FakeStatsTile(
                        label: AppStrings.monthlyStatsLedgerCountLabel,
                        value: '$ledgerCount',
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FakeStatsTile extends StatelessWidget {
  const _FakeStatsTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
              decoration: BoxDecoration(
        color: colors.groupedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
                fontSize: 18,
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
    final font = AppFonts.of(context);
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
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: colors.text,
                ),
                children: [
                  const TextSpan(text: '${AppStrings.leftoverHeadline}\n'),
                  TextSpan(
                    text: AppStrings.leftoverCount(2),
                    style: TextStyle(color: colors.accent),
                  ),
                  const TextSpan(text: ' ${AppStrings.leftoverTail}'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'D + 2',
              style: TextStyle(
                fontFamily: font,
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
                fontFamily: font,
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

class _FakeCategoryDotHeader extends StatelessWidget {
  const _FakeCategoryDotHeader({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1,
            color: AppColors.of(context).text,
          ),
        ),
      ],
    );
  }
}

class _FakeTodo extends StatelessWidget {
  const _FakeTodo({
    required this.title,
    required this.category,
    required this.color,
    this.timeText,
    this.timeOpacity = 1,
    this.trailingText,
    this.showCategory = true,
    this.showComplete = true,
    this.completed = false,
  });

  final String title;
  final String category;
  final Color color;
  final String? timeText;
  final double timeOpacity;
  final String? trailingText;
  final bool showCategory;
  final bool showComplete;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = colors.tint(color, 0.14);
    final ink = EventCategory.labelOf(color);
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
                              Opacity(
                                opacity: timeOpacity.clamp(0.0, 1.0),
                                child: Text(
                                timeText!,
                                style: TextStyle(
                                  fontFamily: AppFonts.of(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                  ),
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
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: ink,
                    ),
                  ),
                ),
              if (showComplete)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ink, width: 2),
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
