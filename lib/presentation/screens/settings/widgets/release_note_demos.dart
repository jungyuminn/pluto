import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/domain/entities/ledger_entry.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:job_planner/presentation/widgets/themed_asset.dart';

enum ReleaseDemo {
  ledgerMonth,
  ledgerDay,
  ledgerRepeat,
  ledgerLabel,
  ledger,
  stickers,
  daySticker,
  leftoverCount,
  someday,
  challenge,
  lunar,
  customTheme,
  themeEdit,
  themePacks,
  backupDownload,
  diaryDraw,
  diaryNote,
  categoryColor,
  search,
  rangeDiary,
  diaryDelete,
  tutorial,
  tabTransition,
  importPick,
  samsungImport,
  importWizard,
  calendarTitle,
  backupKeep,
  restoreLatest,
  appTutorial,
  settingsHelp,
  diaryLongPress,
  diary,
  companyCategory,
  backup,
  autoSave,
  companySearch,
  homeReorder,
  homeBounce,
  releaseNotes,
  weekWidget,
  compactWidget,
  monthWidget,
  notification,
  somedayGoal,
  themeAccent,
  theme,
  fontSize,
  settings,
  homeWidget,
  summary,
  todoReminder,
  dailySummary,
  appearance,
  searchChoseong,
  homeCards,
  holiday,
  homeCalendar,
  jobTracker,
  stickerByMode,
  penKinds,
  drawOpen,
  navSlide,
  jobReorder,
  diaryCover,
  diaryCoverOrder,
  appContact,
  dailySearch,
  license,
  wordmark,
  licenseFile,
  themeBadge,
  feature,
  fix,
}

ReleaseDemo releaseDemoFor(String text, {required bool isFix}) {
  if (isFix) {
    if (text.contains('지원서 순서') || text.contains('손이 떼면')) {
      return ReleaseDemo.jobReorder;
    }
    if (text.contains('알림')) return ReleaseDemo.notification;
    if (text.contains('숨긴 할 일')) return ReleaseDemo.monthWidget;
    if (text.contains('캘린더가 깨지') || text.contains('아이콘이 한 번')) {
      return ReleaseDemo.customTheme;
    }
    if (text.contains('흐릿') || text.contains('위젯 글씨')) {
      return ReleaseDemo.compactWidget;
    }
    if (text.contains('일기 그림') || text.contains('뒤틀')) {
      return ReleaseDemo.diaryDraw;
    }
    if (text.contains('앱 테마를 따라')) {
      return ReleaseDemo.compactWidget;
    }
    return ReleaseDemo.fix;
  }
  if (text.contains('모드마다') || text.contains('따로 붙여')) {
    return ReleaseDemo.stickerByMode;
  }
  if (text.contains('질감') || text.contains('펜을 고르면')) {
    return ReleaseDemo.penKinds;
  }
  if (text.contains('그림 화면')) return ReleaseDemo.drawOpen;
  if (text.contains('밀어 화면') || text.contains('탭을 밀어')) {
    return ReleaseDemo.navSlide;
  }
  if (text.contains('일기장 디자인')) return ReleaseDemo.diaryCover;
  if (text.contains('일기장 순서')) return ReleaseDemo.diaryCoverOrder;
  if (text.contains('앱 문의')) return ReleaseDemo.appContact;
  if (text.contains('일상 모드') && text.contains('검색')) {
    return ReleaseDemo.dailySearch;
  }
  if (text.contains('자격증을 모아') || text.contains('간략 보기')) {
    return ReleaseDemo.license;
  }
  if (text.contains('파일을 올릴')) return ReleaseDemo.licenseFile;
  if (text.contains('화면 제목') || text.contains('이름을 바꿀')) {
    return ReleaseDemo.wordmark;
  }
  if (text.contains('테마색')) return ReleaseDemo.themeBadge;
  if (text.contains('크게 볼') || text.contains('패턴과 사진')) {
    return ReleaseDemo.customTheme;
  }
  if (text.contains('가장 많이 쓴') || text.contains('월 통계')) {
    return ReleaseDemo.ledgerMonth;
  }
  if (text.contains('그날 소비')) return ReleaseDemo.ledgerDay;
  if (text.contains('반복해서 넣을')) return ReleaseDemo.ledgerRepeat;
  if (text.contains('여행 햄스터') || text.contains('스티커 팩')) {
    return ReleaseDemo.stickers;
  }
  if (text.contains('내역 또는 금액')) return ReleaseDemo.ledgerLabel;
  if (text.contains('스티커를 누르면') || text.contains('날짜에 스티커')) {
    return ReleaseDemo.daySticker;
  }
  if (text.contains('남은 할 일')) return ReleaseDemo.leftoverCount;
  if (text.contains('언젠가 할 일 카드')) return ReleaseDemo.someday;
  if (text.contains('챌린지')) return ReleaseDemo.challenge;
  if (text.contains('음력')) return ReleaseDemo.lunar;
  if (text.contains('나만의 테마')) return ReleaseDemo.customTheme;
  if (text.contains('일기장')) return ReleaseDemo.diaryNote;
  if (text.contains('앱 문의')) return ReleaseDemo.settingsHelp;
  if (text.contains('일상 모드') && text.contains('검색')) {
    return ReleaseDemo.search;
  }
  if (text.contains('꾹 눌러 순서를')) return ReleaseDemo.themeEdit;
  if (text.contains('클로버') || text.contains('수달') || text.contains('고양이 마을')) {
    return ReleaseDemo.themePacks;
  }
  if (text.contains('다운로드에도')) return ReleaseDemo.backupDownload;
  if (text.contains('가계부로 수입')) return ReleaseDemo.ledger;
  if (text.contains('그림을 그리고')) return ReleaseDemo.diaryDraw;
  if (text.contains('노트처럼')) return ReleaseDemo.diaryNote;
  if (text.contains('카테고리 색')) return ReleaseDemo.categoryColor;
  if (text.contains('초성')) return ReleaseDemo.searchChoseong;
  if (text.contains('카테고리 이름으로도')) return ReleaseDemo.companySearch;
  if (text.contains('기간을 정하거나')) return ReleaseDemo.search;
  if (text.contains('검색할 수')) return ReleaseDemo.search;
  if (text.contains('기간 일기') || text.contains('날짜를 밀어')) {
    return ReleaseDemo.rangeDiary;
  }
  if (text.contains('휴지통')) return ReleaseDemo.diaryDelete;
  if (text.contains('앱 둘러보기')) return ReleaseDemo.tutorial;
  if (text.contains('하단 탭')) return ReleaseDemo.tabTransition;
  if (text.contains('가져올 할 일을 체크')) return ReleaseDemo.importPick;
  if (text.contains('삼성 캘린더')) return ReleaseDemo.samsungImport;
  if (text.contains('단계별로')) return ReleaseDemo.importWizard;
  if (text.contains('할 일마다 카테고리')) return ReleaseDemo.companyCategory;
  if (text.contains('달력 제목')) return ReleaseDemo.calendarTitle;
  if (text.contains('직접 백업도')) return ReleaseDemo.backupKeep;
  if (text.contains('복구하기를 누르면')) return ReleaseDemo.restoreLatest;
  if (text.contains('처음 설치하거나')) return ReleaseDemo.appTutorial;
  if (text.contains('도움말이 생겼어요')) return ReleaseDemo.settingsHelp;
  if (text.contains('길게 눌러 일기를')) return ReleaseDemo.diaryLongPress;
  if (text.contains('일기를 쓰고 사진')) return ReleaseDemo.diary;
  if (text.contains('기업에도 카테고리')) return ReleaseDemo.companyCategory;
  if (text.contains('백업하고 복구')) return ReleaseDemo.backup;
  if (text.contains('자동저장 주기')) return ReleaseDemo.autoSave;
  if (text.contains('홈에서 카드를 길게')) return ReleaseDemo.homeReorder;
  if (text.contains('바운스')) return ReleaseDemo.homeBounce;
  if (text.contains('업데이트 내용') || text.contains('릴리즈 노트')) {
    return ReleaseDemo.releaseNotes;
  }
  if (text.contains('일상 모드') || text.contains('지원서 메뉴')) {
    return ReleaseDemo.tabTransition;
  }
  if (text.contains('위젯 폰트')) return ReleaseDemo.fontSize;
  if (text.contains('테마·폰트') || text.contains('따라갈지')) {
    return ReleaseDemo.compactWidget;
  }
  if (text.contains('이번 달 달력')) return ReleaseDemo.monthWidget;
  if (text.contains('숨긴 할 일')) return ReleaseDemo.monthWidget;
  if (text.contains('밖으로 빼') || text.contains('다른 날로')) {
    return ReleaseDemo.homeReorder;
  }
  if (text.contains('위젯을 고를 때')) return ReleaseDemo.homeWidget;
  if (text.contains('작은 위젯')) return ReleaseDemo.compactWidget;
  if (text.contains('일주일 위젯')) return ReleaseDemo.weekWidget;
  if (text.contains('언젠가 목표')) return ReleaseDemo.somedayGoal;
  if (text.contains('아이콘·버튼 강조색')) return ReleaseDemo.themeAccent;
  if (text.contains('테마로 바꿀')) return ReleaseDemo.theme;
  if (text.contains('글꼴과')) return ReleaseDemo.fontSize;
  if (text.contains('설정 화면을 더 보기')) return ReleaseDemo.settings;
  if (text.contains('홈 화면을 위젯')) return ReleaseDemo.homeWidget;
  if (text.contains('지난주·지난달')) return ReleaseDemo.summary;
  if (text.contains('시작 전에 알림')) return ReleaseDemo.todoReminder;
  if (text.contains('알림을 보내지')) return ReleaseDemo.notification;
  if (text.contains('하루 요약')) return ReleaseDemo.dailySummary;
  if (text.contains('라이트 모드')) return ReleaseDemo.appearance;
  if (text.contains('홈에 보여줄 카드')) return ReleaseDemo.homeCards;
  if (text.contains('대체공휴일')) return ReleaseDemo.holiday;
  if (text.contains('오늘·내일')) return ReleaseDemo.homeCalendar;
  if (text.contains('기업별로')) return ReleaseDemo.jobTracker;
  return ReleaseDemo.feature;
}

class ReleaseDemoView extends StatelessWidget {
  const ReleaseDemoView({super.key, required this.demo});

  final ReleaseDemo demo;

  @override
  Widget build(BuildContext context) {
    return switch (demo) {
      ReleaseDemo.ledgerMonth => const _LedgerMonthDemo(),
      ReleaseDemo.ledgerDay => const _LedgerDayDemo(),
      ReleaseDemo.ledgerRepeat => const _LedgerRepeatDemo(),
      ReleaseDemo.ledgerLabel => const _LedgerLabelDemo(),
      ReleaseDemo.ledger => const _LedgerDemo(),
      ReleaseDemo.stickers || ReleaseDemo.daySticker => const _StickerDemo(),
      ReleaseDemo.leftoverCount => const _LeftoverCountDemo(),
      ReleaseDemo.someday || ReleaseDemo.somedayGoal => const _SomedayDemo(),
      ReleaseDemo.challenge => const _ChallengeDemo(),
      ReleaseDemo.lunar => const _LunarDemo(),
      ReleaseDemo.customTheme ||
      ReleaseDemo.themePacks ||
      ReleaseDemo.theme ||
      ReleaseDemo.themeAccent => const _ThemeSwapDemo(),
      ReleaseDemo.themeEdit => const _ThemeEditDemo(),
      ReleaseDemo.backupDownload ||
      ReleaseDemo.backup ||
      ReleaseDemo.backupKeep ||
      ReleaseDemo.restoreLatest => const _BackupDemo(),
      ReleaseDemo.autoSave => const _AutoSaveDemo(),
      ReleaseDemo.diaryDraw => const _DiaryDrawDemo(),
      ReleaseDemo.diaryNote || ReleaseDemo.diary => const _DiaryNoteDemo(),
      ReleaseDemo.categoryColor => const _CategoryColorDemo(),
      ReleaseDemo.search ||
      ReleaseDemo.searchChoseong ||
      ReleaseDemo.companySearch => const _SearchDemo(),
      ReleaseDemo.rangeDiary => const _RangeDiaryDemo(),
      ReleaseDemo.diaryDelete ||
      ReleaseDemo.diaryLongPress => const _DiaryDeleteDemo(),
      ReleaseDemo.tutorial || ReleaseDemo.appTutorial => const _TutorialDemo(),
      ReleaseDemo.tabTransition || ReleaseDemo.homeCalendar => const _TabDemo(),
      ReleaseDemo.importPick ||
      ReleaseDemo.samsungImport ||
      ReleaseDemo.importWizard => const _ImportDemo(),
      ReleaseDemo.calendarTitle => const _CalendarTitleDemo(),
      ReleaseDemo.settingsHelp || ReleaseDemo.settings => const _HelpDemo(),
      ReleaseDemo.companyCategory => const _CompanyChipDemo(),
      ReleaseDemo.homeReorder => const _ReorderDemo(),
      ReleaseDemo.homeBounce => const _BounceDemo(),
      ReleaseDemo.releaseNotes => const _NotesPeekDemo(),
      ReleaseDemo.weekWidget || ReleaseDemo.homeWidget => const _WidgetDemo(),
      ReleaseDemo.compactWidget => const _CompactWidgetDemo(),
      ReleaseDemo.monthWidget => const _MonthWidgetDemo(),
      ReleaseDemo.notification ||
      ReleaseDemo.todoReminder ||
      ReleaseDemo.dailySummary ||
      ReleaseDemo.summary => const _NotifyDemo(),
      ReleaseDemo.fontSize => const _FontSizeDemo(),
      ReleaseDemo.appearance => const _AppearanceDemo(),
      ReleaseDemo.homeCards => const _HomeCardsDemo(),
      ReleaseDemo.holiday => const _HolidayDemo(),
      ReleaseDemo.jobTracker => const _JobDemo(),
      ReleaseDemo.stickerByMode => const _StickerByModeDemo(),
      ReleaseDemo.penKinds => const _PenKindsDemo(),
      ReleaseDemo.drawOpen => const _DrawOpenDemo(),
      ReleaseDemo.navSlide => const _NavSlideDemo(),
      ReleaseDemo.jobReorder => const _JobReorderDemo(),
      ReleaseDemo.diaryCover => const _DiaryCoverDemo(),
      ReleaseDemo.diaryCoverOrder => const _DiaryCoverOrderDemo(),
      ReleaseDemo.appContact => const _AppContactDemo(),
      ReleaseDemo.dailySearch => const _DailySearchDemo(),
      ReleaseDemo.license => const _LicenseDemo(),
      ReleaseDemo.wordmark => const _WordmarkDemo(),
      ReleaseDemo.licenseFile => const _LicenseFileDemo(),
      ReleaseDemo.themeBadge => const _ThemeBadgeDemo(),
      ReleaseDemo.feature => const _FeatureDemo(),
      ReleaseDemo.fix => const _FixDemo(),
    };
  }
}

class _Loop extends StatefulWidget {
  const _Loop({required this.builder, this.ms = 2800});

  final Widget Function(BuildContext context, double t) builder;
  final int ms;
  static const height = 168.0;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.ms),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: colors.groupedBackground,
        child: SizedBox(
          height: _Loop.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, child) => widget.builder(context, _loop.value),
          ),
        ),
      ),
    );
  }
}

double _gate(double t, double a, double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return ((t - a) / (b - a)).clamp(0.0, 1.0);
}

double _pulse(double t, double a, double b, double c) {
  if (t < a) return 0;
  if (t < b) return _gate(t, a, b);
  if (t < c) return 1;
  return (1 - _gate(t, c, math.min(1, c + 0.1))).clamp(0.0, 1.0);
}

class _Finger extends StatelessWidget {
  const _Finger({required this.pressed});

  final double pressed;

  @override
  Widget build(BuildContext context) {
    final scale = 1 - pressed * 0.12;
    return Opacity(
      opacity: pressed.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 26,
          height: 26,
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

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: child,
      ),
    );
  }
}

class _LedgerMonthDemo extends StatelessWidget {
  const _LedgerMonthDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.12, 0.32);
        final tap = _pulse(t, 0.48, 0.58, 0.9);
        final open = t >= 0.58;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          '8월',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
                        ),
                        const Spacer(),
                        Opacity(
                          opacity: open ? 1 : 0.35 + tap * 0.65,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                AppStrings.calendarShowLedgerMonthStats,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: show,
                      child: Row(
                        children: [
                          _MiniStat(
                            label: AppStrings.ledgerConsumption,
                            value: '-248,000',
                            color: LedgerEntry.consumptionColor,
                          ),
                          _MiniStat(
                            label: AppStrings.ledgerExpense,
                            value: '+80,000',
                            color: LedgerEntry.expenseColor,
                          ),
                          _MiniStat(
                            label: AppStrings.ledgerPay,
                            value: '+2,400,000',
                            color: LedgerEntry.salaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tap > 0)
              const Positioned(right: 36, top: 28, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: font,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: font,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerDayDemo extends StatelessWidget {
  const _LedgerDayDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final tap = _pulse(t, 0.18, 0.3, 0.86);
        final sheet = Curves.easeOutCubic.transform(_gate(t, 0.3, 0.48));
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 12; i <= 16; i++)
                    _DayCell(
                      day: '$i',
                      selected: i == 14 && t >= 0.3,
                      child: i == 14
                          ? CalendarEventLabel(
                              title: t >= 0.42 ? '-12,400' : '식비',
                              color: LedgerEntry.consumptionColor,
                              height: 16,
                              fontSize: 10,
                              applyCalendarScale: false,
                            )
                          : null,
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, (1 - sheet) * 90),
                child: Opacity(
                  opacity: sheet,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '8월 14일',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '식비 · 소비',
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.text,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '-12,400',
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: LedgerEntry.consumptionColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (tap > 0)
              Positioned(left: 148, top: 48, child: _Finger(pressed: tap)),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, this.selected = false, this.child});

  final String day;
  final bool selected;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 64,
      decoration: BoxDecoration(
        color: selected ? colors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: colors.accent) : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              fontFamily: font,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          ?child,
        ],
      ),
    );
  }
}

class _LedgerRepeatDemo extends StatelessWidget {
  const _LedgerRepeatDemo();

  @override
  Widget build(BuildContext context) {
    const labels = [
      AppStrings.ledgerPaySameDay,
      AppStrings.ledgerPayWeekly,
      AppStrings.ledgerPayMonthly,
    ];
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final selected = t < 0.38 ? 0 : (t < 0.68 ? 1 : 2);
        final tap = _pulse(t, 0.28, 0.38, 0.55) + _pulse(t, 0.58, 0.68, 0.86);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: _Card(
                child: Column(
                  children: [
                    Text(
                      AppStrings.ledgerPayCycleLabel,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected == i
                                      ? colors.accent
                                      : colors.groupedBackground,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  labels[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: selected == i
                                        ? Colors.white
                                        : colors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 28.0 + selected * 104,
                top: 78,
                child: _Finger(pressed: tap.clamp(0.0, 1.0)),
              ),
          ],
        );
      },
    );
  }
}

class _LedgerLabelDemo extends StatelessWidget {
  const _LedgerLabelDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final amount = t >= 0.46;
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 42, 28, 24),
          child: _Card(
            child: CalendarEventLabel(
              title: amount ? '-8,400' : '점심',
              color: LedgerEntry.consumptionColor,
              height: 22,
              fontSize: 13,
              applyCalendarScale: false,
            ),
          ),
        );
      },
    );
  }
}

class _LedgerDemo extends StatelessWidget {
  const _LedgerDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final show = _gate(t, 0.2, 0.45);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: _Card(
            child: Row(
              children: [
                ThemedAsset(asset: AppIcons.wallet, width: 28, height: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: show,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CalendarEventLabel(
                          title: '식비',
                          color: LedgerEntry.consumptionColor,
                          height: 18,
                          fontSize: 11,
                          applyCalendarScale: false,
                        ),
                        const SizedBox(height: 6),
                        CalendarEventLabel(
                          title: '월급',
                          color: LedgerEntry.salaryColor,
                          height: 18,
                          fontSize: 11,
                          applyCalendarScale: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StickerDemo extends StatelessWidget {
  const _StickerDemo();

  static const _assets = [
    'assets/stickers/company_rabbit/07_salary.png',
    'assets/stickers/university_rabbit/02_exam.png',
    'assets/stickers/daily_dog/01_thank_you.png',
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 3; i++)
                Column(
                  children: [
                    Text(
                      '${12 + i}',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Transform.scale(
                      scale: Curves.elasticOut.transform(
                        _gate(t, 0.12 + i * 0.16, 0.28 + i * 0.16),
                      ),
                      child: Image.asset(_assets[i], width: 52, height: 52),
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

class _LeftoverCountDemo extends StatelessWidget {
  const _LeftoverCountDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.14, 0.36);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Opacity(
            opacity: show,
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: colors.text,
                ),
                children: [
                  const TextSpan(text: '${AppStrings.leftoverHeadline}\n'),
                  TextSpan(
                    text: AppStrings.leftoverCount(7),
                    style: TextStyle(color: colors.accent),
                  ),
                  const TextSpan(text: ' ${AppStrings.leftoverTail}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SomedayDemo extends StatelessWidget {
  const _SomedayDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final slide = Curves.easeOutCubic.transform(_gate(t, 0.12, 0.4));
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Opacity(
                opacity: 0.45,
                child: _Card(
                  child: SizedBox(
                    height: 36,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.homeShowToday,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 68, 18, 12),
              child: Transform.translate(
                offset: Offset(0, (1 - slide) * 24),
                child: Opacity(
                  opacity: slide,
                  child: _Card(
                    child: Row(
                      children: [
                        Text(
                          AppStrings.homeShowSomeday,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '여행 가방',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChallengeDemo extends StatelessWidget {
  const _ChallengeDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final fill = Curves.easeOutCubic.transform(_gate(t, 0.18, 0.7));
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 36, 18, 20),
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.longGoalTitle,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(fill * 70).round()} / 100',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LunarDemo extends StatelessWidget {
  const _LunarDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.22, 0.48);
        return Center(
          child: _Card(
            child: SizedBox(
              width: 72,
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '15',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: show,
                    child: Text(
                      '6.22',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
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

class _ThemeSwapDemo extends StatelessWidget {
  const _ThemeSwapDemo();

  static const _swatches = [
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3200,
      builder: (context, t) {
        final index = t < 0.33 ? 0 : (t < 0.66 ? 1 : 2);
        final tap =
            _pulse(t, 0.18, 0.28, 0.42) +
            _pulse(t, 0.5, 0.6, 0.74) +
            _pulse(t, 0.82, 0.9, 0.98);
        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              color: _swatches[index].withValues(alpha: 0.18),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            color: _swatches[i],
                            borderRadius: BorderRadius.circular(14),
                            border: index == i
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 36.0 + index * 108,
                top: 68,
                child: _Finger(pressed: tap.clamp(0.0, 1.0)),
              ),
          ],
        );
      },
    );
  }
}

class _ThemeEditDemo extends StatelessWidget {
  const _ThemeEditDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final swap = Curves.easeInOutCubic.transform(_gate(t, 0.28, 0.55));
        final hold = _pulse(t, 0.12, 0.22, 0.55);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
              child: Column(
                children: [
                  Transform.translate(
                    offset: Offset(0, swap * 44),
                    child: _swatch(colors.accent, high: swap < 0.5),
                  ),
                  const SizedBox(height: 8),
                  Transform.translate(
                    offset: Offset(0, -swap * 44),
                    child: _swatch(const Color(0xFF22C55E), high: swap >= 0.5),
                  ),
                ],
              ),
            ),
            if (hold > 0)
              Positioned(left: 48, top: 44, child: _Finger(pressed: hold)),
          ],
        );
      },
    );
  }

  Widget _swatch(Color color, {required bool high}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: high ? 1 : 0.7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(height: 36, width: double.infinity),
      ),
    );
  }
}

class _BackupDemo extends StatelessWidget {
  const _BackupDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final drop = Curves.easeOutBack.transform(_gate(t, 0.2, 0.55));
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: _Card(
            child: Row(
              children: [
                Icon(Icons.folder_rounded, color: colors.accent, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '다운로드',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                ),
                Opacity(
                  opacity: drop.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - drop) * -18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          'zip',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AutoSaveDemo extends StatelessWidget {
  const _AutoSaveDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final spin = t * math.pi * 2;
        return Center(
          child: _Card(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: spin,
                  child: Icon(
                    Icons.sync_rounded,
                    color: colors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '매일 자동저장',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiaryDrawDemo extends StatelessWidget {
  const _DiaryDrawDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final draw = _gate(t, 0.18, 0.7);
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
          child: _Card(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 120,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFBFDBFE), Color(0xFF93C5FD)],
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _StrokePainter(
                      progress: draw,
                      color: colors.accent,
                    ),
                    child: const SizedBox.expand(),
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

class _StrokePainter extends CustomPainter {
  const _StrokePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.18,
        size.width * 0.78,
        size.height * 0.48,
      );
    final metric = path.computeMetrics().first;
    final extract = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      extract,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DiaryNoteDemo extends StatelessWidget {
  const _DiaryNoteDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final line = _gate(t, 0.2, 0.7);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '8월 14일',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: line,
                    child: Text(
                      '오늘은 면접 준비를 했다',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < 2; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ColoredBox(
                      color: colors.border,
                      child: const SizedBox(height: 1, width: double.infinity),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryColorDemo extends StatelessWidget {
  const _CategoryColorDemo();

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final selected = t < 0.38 ? 0 : (t < 0.68 ? 1 : 2);
        final tap = _pulse(t, 0.26, 0.36, 0.5);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                children: [
                  CalendarEventLabel(
                    title: '서류',
                    color: _colors[selected],
                    height: 22,
                    fontSize: 13,
                    applyCalendarScale: false,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: selected == i ? 28 : 22,
                            height: selected == i ? 28 : 22,
                            decoration: BoxDecoration(
                              color: _colors[i],
                              shape: BoxShape.circle,
                              border: selected == i
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 118.0 + selected * 38,
                top: 92,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }
}

class _SearchDemo extends StatelessWidget {
  const _SearchDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        const query = '자기소개서';
        final typed = (query.length * _gate(t, 0.12, 0.48)).round();
        final show = _gate(t, 0.5, 0.68);
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
          child: Column(
            children: [
              _Card(
                child: Row(
                  children: [
                    ThemedAsset(asset: AppIcons.search, width: 18, height: 18),
                    const SizedBox(width: 8),
                    Text(
                      query.substring(0, typed),
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: show,
                child: CalendarEventLabel(
                  title: '자기소개서 제출',
                  color: const Color(0xFF3B82F6),
                  height: 22,
                  fontSize: 12,
                  applyCalendarScale: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RangeDiaryDemo extends StatelessWidget {
  const _RangeDiaryDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final span = (1 + 2 * _gate(t, 0.18, 0.55)).round();
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 40, 18, 16),
              child: Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 48,
                        decoration: BoxDecoration(
                          color: i < span
                              ? colors.accent.withValues(alpha: 0.18)
                              : colors.card,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${12 + i}',
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 28.0 + (span - 1) * 58,
              top: 52,
              child: _Finger(pressed: _pulse(t, 0.16, 0.26, 0.7)),
            ),
          ],
        );
      },
    );
  }
}

class _DiaryDeleteDemo extends StatelessWidget {
  const _DiaryDeleteDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final gone = _gate(t, 0.55, 0.78);
        final tap = _pulse(t, 0.32, 0.44, 0.58);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 36, 22, 20),
              child: Opacity(
                opacity: 1 - gone,
                child: Transform.scale(
                  scale: 1 - gone * 0.12,
                  child: _Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '오늘 일기',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                        ),
                        Icon(Icons.delete_outline_rounded, color: colors.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (tap > 0)
              Positioned(right: 36, top: 52, child: _Finger(pressed: tap)),
          ],
        );
      },
    );
  }
}

class _TutorialDemo extends StatelessWidget {
  const _TutorialDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final fill = _gate(t, 0.1, 0.85);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 4,
                    backgroundColor: colors.border,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.tutorialWelcomeTitle,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabDemo extends StatelessWidget {
  const _TabDemo();

  static const _tabWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    const labels = ['홈', '캘린더', '지원서'];
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final selected = t < 0.42 ? 0 : 1;
        final tap = _pulse(t, 0.28, 0.4, 0.82);
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: _tabWidth,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected == i
                                ? colors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: selected == i ? Colors.white : colors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (tap > 0)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment((selected - 1) * 2 / 3, 0),
                    child: _Finger(pressed: tap),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ImportDemo extends StatelessWidget {
  const _ImportDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          child: _Card(
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          t > 0.2 + i * 0.18
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 20,
                          color: t > 0.2 + i * 0.18
                              ? colors.accent
                              : colors.muted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ['면접 준비', '자기소개서', '코딩테스트'][i],
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalendarTitleDemo extends StatelessWidget {
  const _CalendarTitleDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final tap = _pulse(t, 0.2, 0.32, 0.82);
        final zoomed = t >= 0.32 && t < 0.82;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: zoomed ? 1 : 0,
                    child: Text(
                      '2026년',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
                      ),
                    ),
                  ),
                  Text(
                    zoomed ? '연도 고르기' : '8월',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: zoomed ? 22 : 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(left: 40, top: 64, child: _Finger(pressed: tap)),
          ],
        );
      },
    );
  }
}

class _HelpDemo extends StatelessWidget {
  const _HelpDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final rise = Curves.easeOutCubic.transform(_gate(t, 0.28, 0.55));
        final tap = _pulse(t, 0.14, 0.26, 0.5);
        return Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: colors.muted,
                  size: 26,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, (1 - rise) * 70),
                child: Opacity(
                  opacity: rise,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _Card(
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            AppStrings.settingsHelpPreview,
                            style: TextStyle(
                              fontFamily: AppFonts.of(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (tap > 0)
              const Positioned(right: 22, top: 18, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }
}

class _CompanyChipDemo extends StatelessWidget {
  const _CompanyChipDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.28, 0.5);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: _Card(
            child: Row(
              children: [
                Text(
                  '네이버',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const Spacer(),
                Opacity(
                  opacity: show,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        '서류',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReorderDemo extends StatelessWidget {
  const _ReorderDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final swap = Curves.easeInOutCubic.transform(_gate(t, 0.28, 0.58));
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 16),
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(0, swap * 52),
                child: _mini(font, colors, AppStrings.homeShowToday),
              ),
              Transform.translate(
                offset: Offset(0, 52 - swap * 52),
                child: _mini(font, colors, AppStrings.homeShowWeek),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mini(String? font, AppColors colors, String title) {
    return _Card(
      child: SizedBox(
        height: 28,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _BounceDemo extends StatelessWidget {
  const _BounceDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final press = _pulse(t, 0.28, 0.4, 0.55);
        final scale = 1 - press * 0.08;
        return Center(
          child: Transform.scale(
            scale: scale,
            child: _Card(
              child: SizedBox(
                width: 160,
                child: Text(
                  AppStrings.homeShowToday,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
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

class _NotesPeekDemo extends StatelessWidget {
  const _NotesPeekDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final tap = _pulse(t, 0.22, 0.34, 0.7);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: _Card(
                child: Row(
                  children: [
                    Text(
                      '1.0.22',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: colors.muted),
                  ],
                ),
              ),
            ),
            if (tap > 0)
              const Positioned(left: 48, top: 52, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }
}

class _CompactWidgetDemo extends StatelessWidget {
  const _CompactWidgetDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.16, 0.38);
        return Center(
          child: Opacity(
            opacity: show,
            child: Transform.scale(
              scale: 0.82 + show * 0.18,
              child: SizedBox(
                width: 148,
                height: 148,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                    child: Column(
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
                                  height: 1.1,
                                  color: colors.text,
                                ),
                              ),
                              TextSpan(
                                text: ' 8월 31일',
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1,
                                  color: colors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in const [
                          (Color(0xFFA78BFA), '자소서'),
                          (Color(0xFF60A5FA), '면접 준비'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: item.$1,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.$2,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: colors.text,
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
            ),
          ),
        );
      },
    );
  }
}

class _MonthWidgetDemo extends StatelessWidget {
  const _MonthWidgetDemo();

  static const _dots = {
    3: Color(0xFFA78BFA),
    10: Color(0xFF60A5FA),
    17: Color(0xFFF9A8D4),
    24: Color(0xFFA78BFA),
    31: Color(0xFF60A5FA),
  };

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.16, 0.38);
        return Center(
          child: Opacity(
            opacity: show,
            child: Transform.scale(
              scale: 0.86 + show * 0.14,
              child: SizedBox(
                width: 168,
                height: 168,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '8월',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: colors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: Text(
                                  ['일', '월', '화', '수', '목', '금', '토'][i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: i == 0
                                        ? const Color(0xFFEF4444)
                                        : i == 6
                                        ? const Color(0xFF60A5FA)
                                        : colors.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        for (var row = 0; row < 5; row++)
                          Expanded(
                            child: Row(
                              children: [
                                for (var col = 0; col < 7; col++)
                                  Expanded(
                                    child: _MonthDemoDay(
                                      day: row * 7 + col + 1,
                                      dot: _dots[row * 7 + col + 1],
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
            ),
          ),
        );
      },
    );
  }
}

class _MonthDemoDay extends StatelessWidget {
  const _MonthDemoDay({required this.day, this.dot});

  final int day;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    if (day > 31) return const SizedBox.shrink();
    final colors = AppColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$day',
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            height: 1,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 2),
        if (dot != null)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}

class _WidgetDemo extends StatelessWidget {
  const _WidgetDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.18, 0.42);
        return Padding(
          padding: const EdgeInsets.fromLTRB(36, 16, 36, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Opacity(
                opacity: show,
                child: _Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final day in ['월', '화', '수', '목', '금'])
                        Text(
                          day,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
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

class _NotifyDemo extends StatelessWidget {
  const _NotifyDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final ring = math.sin(_gate(t, 0.3, 0.7) * math.pi * 6) * 0.18;
        final banner = _gate(t, 0.38, 0.55);
        return Stack(
          children: [
            Center(
              child: Transform.rotate(
                angle: ring,
                child: Icon(
                  Icons.notifications_rounded,
                  size: 44,
                  color: colors.accent,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: banner,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _Card(
                    child: Text(
                      '하루 요약이 도착했어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FontSizeDemo extends StatelessWidget {
  const _FontSizeDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final size = 13.0 + 6 * _gate(t, 0.15, 0.7);
        return Center(
          child: Text(
            '할 일 글자',
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
        );
      },
    );
  }
}

class _AppearanceDemo extends StatelessWidget {
  const _AppearanceDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final dark = t >= 0.46;
        final bg = dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
        final fg = dark ? Colors.white : const Color(0xFF111827);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          color: bg,
          child: Center(
            child: Icon(
              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 42,
              color: fg,
            ),
          ),
        );
      },
    );
  }
}

class _HomeCardsDemo extends StatelessWidget {
  const _HomeCardsDemo();

  @override
  Widget build(BuildContext context) {
    const labels = [
      AppStrings.homeShowToday,
      AppStrings.homeShowTomorrow,
      AppStrings.homeShowWeek,
    ];
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
          child: _Card(
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          t > 0.18 + i * 0.18 || i == 0
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 20,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HolidayDemo extends StatelessWidget {
  const _HolidayDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final font = AppFonts.of(context);
        final show = _gate(t, 0.22, 0.5);
        return Center(
          child: _Card(
            child: SizedBox(
              width: 72,
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '15',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: show,
                    child: Text(
                      '광복절',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
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

class _JobDemo extends StatelessWidget {
  const _JobDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final step = t < 0.4 ? 0 : (t < 0.7 ? 1 : 2);
        const stages = ['서류', '면접', '최종'];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 18),
          child: _Card(
            child: Column(
              children: [
                Text(
                  '네이버',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: i == step
                                ? colors.accent
                                : colors.groupedBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            stages[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: i == step ? Colors.white : colors.muted,
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
      },
    );
  }
}

class _StickerByModeDemo extends StatelessWidget {
  const _StickerByModeDemo();

  static const _modes = ['할 일', '가계부', '일기'];
  static const _stickers = [
    'assets/stickers/company_cat/07_fighting.png',
    'assets/stickers/daily_dog/12_snack.png',
    'assets/stickers/daily_rabbit/05_good_morning.png',
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3200,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final mode = t < 0.34 ? 0 : (t < 0.67 ? 1 : 2);
        final tap = _pulse(t, 0.08, 0.18, 0.28) +
            _pulse(t, 0.38, 0.48, 0.58) +
            _pulse(t, 0.72, 0.82, 0.92);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Expanded(
                    child: _Card(
                      child: Column(
                        children: [
                          Text(
                            '2',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Image.asset(
                                _stickers[mode],
                                key: ValueKey(mode),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: mode == i
                                    ? colors.accent
                                    : colors.card,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _modes[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: mode == i
                                      ? Colors.white
                                      : colors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned.fill(
                child: Align(
                  alignment: Alignment((mode - 1) * 0.72, 0.78),
                  child: _Finger(pressed: tap.clamp(0.0, 1.0)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PenKindsDemo extends StatelessWidget {
  const _PenKindsDemo();

  static const _kinds = ['브러시', '크레용', '연필'];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final pen = t < 0.52;
        final kinds = Curves.easeOutCubic.transform(
          pen ? _gate(t, 0.04, 0.16) : 1 - _gate(t, 0.52, 0.66),
        );
        final tap = _pulse(t, 0.44, 0.54, 0.72);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _toolChip(
                        context,
                        icon: pen ? AppIcons.pen : AppIcons.penOutlined,
                        selected: pen,
                        label: '펜',
                      ),
                      const SizedBox(width: 8),
                      _toolChip(
                        context,
                        icon: pen
                            ? AppIcons.paintBrushOutlined
                            : AppIcons.paintBrush,
                        selected: !pen,
                        label: '채우기',
                      ),
                    ],
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: kinds,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          children: [
                            for (var i = 0; i < _kinds.length; i++)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: i == 0 && pen
                                      ? colors.selected
                                      : colors.card,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  child: Text(
                                    _kinds[i],
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: colors.text,
                                    ),
                                  ),
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
            if (tap > 0)
              const Positioned(left: 92, top: 22, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }

  Widget _toolChip(
    BuildContext context, {
    required String icon,
    required bool selected,
    required String label,
  }) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? colors.selected : colors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedAsset(asset: icon, width: 18, height: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawOpenDemo extends StatelessWidget {
  const _DrawOpenDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final open = Curves.easeOutCubic.transform(_gate(t, 0.28, 0.52));
        final tap = _pulse(t, 0.12, 0.24, 0.4);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: _Card(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.diaryPhotoHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.muted,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          AppStrings.diaryPhotoDraw,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tap > 0)
              const Positioned(right: 42, top: 40, child: _Finger(pressed: 1)),
            Opacity(
              opacity: open,
              child: Transform.translate(
                offset: Offset(0, (1 - open) * 28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: _Card(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 148,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: ColoredBox(color: Color(0xFFFFFFFF)),
                          ),
                          CustomPaint(
                            painter: _StrokePainter(
                              progress: _gate(t, 0.55, 0.88),
                              color: colors.accent,
                            ),
                            child: const SizedBox.expand(),
                          ),
                          Positioned(
                            left: 12,
                            top: 10,
                            child: Text(
                              AppStrings.diaryDrawTitle,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colors.text,
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
          ],
        );
      },
    );
  }
}

class _NavSlideDemo extends StatelessWidget {
  const _NavSlideDemo();

  static const _cell = 56.0;
  static const _indicator = 42.0;

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final slide = Curves.easeInOutCubic.transform(_gate(t, 0.16, 0.72));
        final index = slide < 0.5 ? 0 : 1;
        final finger = _pulse(t, 0.1, 0.2, 0.82);
        final minLeft = (_cell - _indicator) / 2;
        final left = minLeft + slide * _cell;
        return Stack(
          children: [
            Center(
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
                  width: _cell * 3,
                  height: 48,
                  child: Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: 4,
                        width: _indicator,
                        height: 40,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.pressed,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final asset in [
                            index == 0 ? AppIcons.home : AppIcons.homeOutlined,
                            index == 1
                                ? AppIcons.calendar
                                : AppIcons.calendarOutlined,
                            AppIcons.resumeOutlined,
                          ])
                            SizedBox(
                              width: _cell,
                              child: Center(
                                child: ThemedAsset(
                                  asset: asset,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (finger > 0)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(-0.42 + slide * 0.42, 0),
                  child: _Finger(pressed: finger),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _JobReorderDemo extends StatelessWidget {
  const _JobReorderDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final move = Curves.easeInOutCubic.transform(_gate(t, 0.18, 0.55));
        final hold = _pulse(t, 0.08, 0.18, 0.62);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              child: Stack(
                children: [
                  Transform.translate(
                    offset: Offset(0, -move * 46),
                    child: _jobCard(font, colors, '카카오', const Color(0xFFF59E0B)),
                  ),
                  Transform.translate(
                    offset: Offset(0, 52 + move * 46),
                    child: Opacity(
                      opacity: 0.55 + move * 0.45,
                      child: _jobCard(
                        font,
                        colors,
                        '네이버',
                        const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hold > 0)
              Positioned(
                left: 36,
                top: 28 + move * 46,
                child: _Finger(pressed: hold),
              ),
          ],
        );
      },
    );
  }

  Widget _jobCard(String? font, AppColors colors, String name, Color color) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCoverDemo extends StatelessWidget {
  const _DiaryCoverDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3200,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final sheet = Curves.easeOutCubic.transform(_gate(t, 0.22, 0.4));
        final lined = t >= 0.55;
        final tapChip = _pulse(t, 0.1, 0.2, 0.34);
        final tapCover = _pulse(t, 0.46, 0.56, 0.7);
        final paper = lined ? const Color(0xFFF7F4EA) : colors.card;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
              child: Column(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘의 제목',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (var i = 0; i < 2; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ColoredBox(
                                  color: lined
                                      ? const Color(0xFFD6D1C4)
                                      : colors.border,
                                  child: const SizedBox(
                                    height: 1,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                        child: Text(
                          lined
                              ? AppStrings.diaryCoverLined
                              : AppStrings.diaryCoverBasic,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (sheet > 0)
              Opacity(
                opacity: sheet * (lined ? 0.0 : 1.0) +
                    (lined ? (1 - _gate(t, 0.55, 0.68)) * sheet : 0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _Card(
                      child: Row(
                        children: [
                          _miniCover(
                            colors.card,
                            AppStrings.diaryCoverBasic,
                            selected: !lined,
                          ),
                          const SizedBox(width: 8),
                          _miniCover(
                            const Color(0xFFF7F4EA),
                            AppStrings.diaryCoverLined,
                            selected: lined,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (tapChip > 0)
              const Positioned(left: 36, top: 126, child: _Finger(pressed: 1)),
            if (tapCover > 0)
              const Positioned(left: 118, top: 108, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }

  Widget _miniCover(Color paper, String name, {required bool selected}) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : const Color(0x22000000),
            width: selected ? 2 : 1,
          ),
        ),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaryCoverOrderDemo extends StatelessWidget {
  const _DiaryCoverOrderDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final swap = Curves.easeInOutCubic.transform(_gate(t, 0.28, 0.58));
        final hold = _pulse(t, 0.12, 0.22, 0.58);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(swap * 96, 0),
                      child: _coverTile(const Color(0xFFF7F4EA), '줄노트'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(-swap * 96, 0),
                      child: _coverTile(const Color(0xFFE8F4EE), '민트'),
                    ),
                  ),
                ],
              ),
            ),
            if (hold > 0)
              Positioned(
                left: 36 + swap * 96,
                top: 52,
                child: _Finger(pressed: hold),
              ),
          ],
        );
      },
    );
  }

  Widget _coverTile(Color paper, String name) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000)),
      ),
      child: SizedBox(
        height: 72,
        child: Center(
          child: Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _AppContactDemo extends StatelessWidget {
  const _AppContactDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final mail = Curves.easeOutCubic.transform(_gate(t, 0.28, 0.52));
        final tap = _pulse(t, 0.12, 0.24, 0.4);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: _Card(
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      color: colors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.appContact,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tap > 0)
              const Positioned(left: 36, top: 44, child: _Finger(pressed: 1)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, (1 - mail) * 64),
                child: Opacity(
                  opacity: mail,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _Card(
                      child: Text(
                        AppStrings.appContactEmail,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DailySearchDemo extends StatelessWidget {
  const _DailySearchDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        const query = '면접';
        final typed = (query.length * _gate(t, 0.16, 0.48)).round();
        final show = _gate(t, 0.52, 0.7);
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            children: [
              _Card(
                child: Row(
                  children: [
                    ThemedAsset(asset: AppIcons.search, width: 18, height: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        typed == 0
                            ? AppStrings.calendarSearchHintDaily
                            : query.substring(0, typed),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: typed == 0 ? colors.hint : colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      AppStrings.calendarModeRange,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.muted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: show,
                child: CalendarEventLabel(
                  title: '면접 준비',
                  color: const Color(0xFF3B82F6),
                  height: 22,
                  fontSize: 12,
                  applyCalendarScale: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LicenseDemo extends StatelessWidget {
  const _LicenseDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final open = _gate(t, 0.28, 0.55);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '정보처리기사',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          '88',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00ACC1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '기사',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00ACC1),
                      ),
                    ),
                  ],
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: open,
                    child: Opacity(
                      opacity: open,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '취득일  2024. 3. 5.\n만료일  2029. 3. 5.',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: colors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WordmarkDemo extends StatelessWidget {
  const _WordmarkDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final custom = _gate(t, 0.38, 0.58) > 0.5;
        final tap = _pulse(t, 0.22, 0.32, 0.42);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Transform.scale(
            scale: 1 - tap * 0.04,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                custom ? '내 플래너' : '잡플래너',
                style: TextStyle(
                  fontFamily: AppFonts.jalnan,
                  fontSize: 22,
                  color: AppFonts.wordmarkColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LicenseFileDemo extends StatelessWidget {
  const _LicenseFileDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.28, 0.5);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: _Card(
            child: Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: colors.hint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    show > 0.5 ? '정보처리기사.pdf' : '자격증',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: show > 0.5 ? colors.accent : colors.hint,
                      decoration: show > 0.5
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: colors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeBadgeDemo extends StatelessWidget {
  const _ThemeBadgeDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = _gate(t, 0.2, 0.42);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: _Card(
                  child: Row(
                    children: [
                      Text(
                        '네이버',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: show,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '서류합격',
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colors.accent,
                              ),
                            ),
                          ),
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

class _FeatureDemo extends StatelessWidget {
  const _FeatureDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final colors = AppColors.of(context);
        final pop = Curves.elasticOut.transform(_gate(t, 0.12, 0.45));
        return Center(
          child: Transform.scale(
            scale: pop.clamp(0.0, 1.2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 36,
                  color: colors.accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FixDemo extends StatelessWidget {
  const _FixDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      builder: (context, t) {
        final fixed = t >= 0.46;
        return Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Icon(
              fixed ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              key: ValueKey(fixed),
              size: 48,
              color: fixed ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            ),
          ),
        );
      },
    );
  }
}
