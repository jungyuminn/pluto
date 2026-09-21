import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_event_label.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_category_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_date_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_time_chip.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

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
  icloudBackup,
  searchOpenList,
  searchGroupBy,
  searchRangePill,
  diaryPhotoSave,
  diaryStickerRemove,
  icloudRestore,
  jobMode,
  jobExpand,
  jobFaded,
  wordmarkAccount,
  pastelTint,
  planetCollection,
  homeHideJobs,
  pcLaunch,
  accountSync,
  categoryAi,
  homeMemo,
  categoryView,
  friendsMiniCal,
  friendsAdd,
  pcEnterSave,
  jobCategorySlide,
  featureIntro,
  settingsFollow,
  loginPaint,
  featureIntroStay,
  feature,
  fix,
}

ReleaseDemo releaseDemoFor(String text, {required bool isFix}) {
  if (isFix) {
    if (text.contains('상대 프로필') ||
        text.contains('바로 없어') ||
        text.contains('제목도 같이') ||
        text.contains('뒤 화면') ||
        text.contains('바로 보내')) {
      return ReleaseDemo.friendsMiniCal;
    }
    if (text.contains('AI 카테고리') || text.contains('제목을 치면')) {
      return ReleaseDemo.categoryAi;
    }
    if (text.contains('친구 추가')) return ReleaseDemo.friendsAdd;
    if (text.contains('월 통계')) return ReleaseDemo.ledgerMonth;
    if (text.contains('날짜 창')) return ReleaseDemo.pcLaunch;
    if (text.contains('화살표')) return ReleaseDemo.pcLaunch;
    if (text.contains('로그인 화면')) return ReleaseDemo.accountSync;
    if (text.contains('홈 카드에 지원서') || text.contains('취준 모드를 끄면')) {
      return ReleaseDemo.homeHideJobs;
    }
    if (text.contains('잘리지') || text.contains('그림 창')) {
      return ReleaseDemo.diaryDraw;
    }
    if (text.contains('일기 사진')) return ReleaseDemo.diaryPhotoSave;
    if (text.contains('일기 스티커')) return ReleaseDemo.diaryStickerRemove;
    if (text.contains('복구할 파일') || text.contains('아이클라우드에서 복구')) {
      return ReleaseDemo.icloudRestore;
    }
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
    if (text.contains('여러 개를 지울') || text.contains('일기를 지울')) {
      return ReleaseDemo.diaryDelete;
    }
    if (text.contains('일기 그림') || text.contains('뒤틀')) {
      return ReleaseDemo.diaryDraw;
    }
    if (text.contains('앱 테마를 따라')) {
      return ReleaseDemo.compactWidget;
    }
    if (text.contains('흰 카드') || text.contains('같이 줄지')) {
      return ReleaseDemo.searchOpenList;
    }
    if (text.contains('기능 안내')) return ReleaseDemo.featureIntroStay;
    if (text.contains('스티커 팩')) return ReleaseDemo.stickers;
    return ReleaseDemo.fix;
  }
  if (text.contains('시간에 넣') || text.contains('4시나')) {
    return ReleaseDemo.categoryAi;
  }
  if (text.contains('24시간') || text.contains('오전·오후')) {
    return ReleaseDemo.settingsHelp;
  }
  if (text.contains('종료 시간')) {
    return ReleaseDemo.settingsHelp;
  }
  if (text.contains('홈에 메모') || text.contains('메모를 둘')) {
    return ReleaseDemo.homeMemo;
  }
  if (text.contains('모아 볼') || text.contains('카테고리별 보기')) {
    return ReleaseDemo.categoryView;
  }
  if (text.contains('미니캘린더') || text.contains('일정만')) {
    return ReleaseDemo.friendsMiniCal;
  }
  if (text.contains('같이 할 일') ||
      text.contains('둘 다 체크') ||
      text.contains('상대 캘린더') ||
      text.contains('내 얼굴')) {
    return ReleaseDemo.friendsMiniCal;
  }
  if (text.contains('아이디로 친구') || text.contains('친구를 추가')) {
    return ReleaseDemo.friendsAdd;
  }
  if (text.contains('Enter키')) return ReleaseDemo.pcEnterSave;
  if (text.contains('카테고리별로') || text.contains('칸이 부드럽게')) {
    return ReleaseDemo.jobCategorySlide;
  }
  if (text.contains('AI가 카테고리') || text.contains('카테고리를 미리')) {
    return ReleaseDemo.categoryAi;
  }
  if (text.contains('더 많은 기능')) return ReleaseDemo.featureIntro;
  if (text.contains('계정을 따라')) return ReleaseDemo.settingsFollow;
  if (text.contains('바로 입혀')) return ReleaseDemo.loginPaint;
  if (text.contains('앱 아이콘') || text.contains('로그인 로고')) {
    return ReleaseDemo.accountSync;
  }
  if (text.contains('커서가')) {
    return ReleaseDemo.themeAccent;
  }
  if (text.contains('그림 도구')) {
    return ReleaseDemo.penKinds;
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
  if (text.contains('아이클라우드에 저장')) return ReleaseDemo.icloudBackup;
  if (text.contains('돋보기를 열면') || text.contains('전체 목록이 나와')) {
    return ReleaseDemo.searchOpenList;
  }
  if (text.contains('카테고리별 보기와 날짜별')) {
    return ReleaseDemo.searchGroupBy;
  }
  if (text.contains('알약으로')) return ReleaseDemo.searchRangePill;
  if (text.contains('취준 모드를 켜야')) return ReleaseDemo.jobMode;
  if (text.contains('아래로 펼쳐') || text.contains('할 일처럼 간략히')) {
    return ReleaseDemo.jobExpand;
  }
  if (text.contains('자격증도 같은')) return ReleaseDemo.license;
  if (text.contains('탈락한 지원서') || text.contains('만료된 자격증')) {
    return ReleaseDemo.jobFaded;
  }
  if (text.contains('계정마다') || text.contains('로고가 계정')) {
    return ReleaseDemo.wordmarkAccount;
  }
  if (text.contains('더 연해') || text.contains('카테고리 색 배경')) {
    return ReleaseDemo.pastelTint;
  }
  if (text.contains('모은 행성') || text.contains('해마다')) {
    return ReleaseDemo.planetCollection;
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
  if (text.contains('커서를 올리면') || text.contains('눌림 효과')) {
    return ReleaseDemo.homeBounce;
  }
  if (text.contains('브라우저') || text.contains('위 바')) {
    return ReleaseDemo.appearance;
  }
  if (text.contains('달력을 마우스') || text.contains('화살표로 옮길')) {
    return ReleaseDemo.pcLaunch;
  }
  if (text.contains('로그인 화면') || text.contains('PC로 여는 주소')) {
    return ReleaseDemo.accountSync;
  }
  if (text.contains('그림에서 드래그') ||
      (text.contains('드래그') && text.contains('그림'))) {
    return ReleaseDemo.diaryDraw;
  }
  if (text.contains('PC버전') || text.contains('PC 버전') || text.contains('출시됐어요')) {
    return ReleaseDemo.pcLaunch;
  }
  if (text.contains('같은 계정') || text.contains('PC에서도')) {
    return ReleaseDemo.pcLaunch;
  }
  if (text.contains('통계 탭') || text.contains('행성')) {
    return ReleaseDemo.summary;
  }
  if (text.contains('로그인하면') || text.contains('계정별로')) {
    return ReleaseDemo.accountSync;
  }
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
      ReleaseDemo.icloudBackup => const _IcloudBackupDemo(),
      ReleaseDemo.searchOpenList => const _SearchOpenListDemo(),
      ReleaseDemo.searchGroupBy => const _SearchGroupByDemo(),
      ReleaseDemo.searchRangePill => const _SearchRangePillDemo(),
      ReleaseDemo.diaryPhotoSave => const _DiaryPhotoSaveDemo(),
      ReleaseDemo.diaryStickerRemove => const _DiaryStickerRemoveDemo(),
      ReleaseDemo.icloudRestore => const _IcloudRestoreDemo(),
      ReleaseDemo.jobMode => const _JobModeDemo(),
      ReleaseDemo.jobExpand => const _JobExpandDemo(),
      ReleaseDemo.jobFaded => const _JobFadedDemo(),
      ReleaseDemo.wordmarkAccount => const _WordmarkAccountDemo(),
      ReleaseDemo.pastelTint => const _PastelTintDemo(),
      ReleaseDemo.planetCollection => const _PlanetCollectionDemo(),
      ReleaseDemo.homeHideJobs => const _HomeHideJobsDemo(),
      ReleaseDemo.pcLaunch => const _PcLaunchDemo(),
      ReleaseDemo.accountSync => const _AccountSyncDemo(),
      ReleaseDemo.categoryAi => const _CategoryAiDemo(),
      ReleaseDemo.homeMemo => const _HomeMemoDemo(),
      ReleaseDemo.categoryView => const _CategoryViewDemo(),
      ReleaseDemo.friendsMiniCal => const _FriendsMiniCalDemo(),
      ReleaseDemo.friendsAdd => const _FriendsAddDemo(),
      ReleaseDemo.pcEnterSave => const _PcEnterSaveDemo(),
      ReleaseDemo.jobCategorySlide => const _JobCategorySlideDemo(),
      ReleaseDemo.featureIntro => const _FeatureIntroDemo(),
      ReleaseDemo.settingsFollow => const _SettingsFollowDemo(),
      ReleaseDemo.loginPaint => const _LoginPaintDemo(),
      ReleaseDemo.featureIntroStay => const _FeatureIntroStayDemo(),
      ReleaseDemo.feature => const _FeatureDemo(),
      ReleaseDemo.fix => const _FixDemo(),
    };
  }
}

class _Loop extends StatefulWidget {
  const _Loop({required this.builder, this.ms = 2800, this.boxHeight});

  final Widget Function(BuildContext context, double t) builder;
  final int ms;
  final double? boxHeight;
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
          height: widget.boxHeight ?? _Loop.height,
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
      builder: (context, _) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: _Card(
            child: Text(
              AppStrings.tutorialWelcomeTitle,
              style: TextStyle(
                fontFamily: font,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
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
      ms: 3400,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final tap = _pulse(t, 0.12, 0.22, 0.36);
        final open = Curves.easeOutCubic.transform(
          t < 0.78 ? _gate(t, 0.22, 0.48) : 1 - _gate(t, 0.78, 0.94),
        );
        const accent = Color(0xFF00ACC1);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
              child: _eventLabel(
                colors: colors,
                font: font,
                title: '정보처리기사',
                subtitle: '기사',
                accent: accent,
                badge: '88',
                open: open,
                details: const ['취득일    2024. 3. 5.', '만료일    2029. 3. 5.'],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 52,
                top: 40,
                child: _Finger(pressed: tap),
              ),
          ],
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
                custom ? '내 플래너' : '플루토',
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

class _MiniSearchField extends StatelessWidget {
  const _MiniSearchField({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _Card(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      child: Row(
        children: [
          ThemedAsset(asset: AppIcons.search, width: 16, height: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.allEventsSearchHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.hint,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }
}

class _MiniGroupCard extends StatelessWidget {
  const _MiniGroupCard({
    required this.title,
    required this.subtitle,
    this.showCount = true,
  });

  final String title;
  final String subtitle;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return _Card(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title),
                if (showCount)
                  TextSpan(
                    text: ' 2',
                    style: TextStyle(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          CalendarEventLabel(
            title: subtitle,
            color: const Color(0xFF3B82F6),
            height: 20,
            fontSize: 11,
            applyCalendarScale: false,
          ),
        ],
      ),
    );
  }
}

class _IcloudBackupDemo extends StatelessWidget {
  const _IcloudBackupDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final lift = Curves.easeInCubic.transform(_gate(t, 0.16, 0.52));
        final glow = Curves.easeOutCubic.transform(_gate(t, 0.44, 0.68));
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                children: [
                  Icon(
                    Icons.cloud_rounded,
                    size: 42,
                    color: Color.lerp(colors.muted, colors.accent, glow)!,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '아이클라우드',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color.lerp(colors.muted, colors.accent, glow)!,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: (1 - lift * 0.9).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -lift * 56),
                    child: _Card(
                      child: Text(
                        '플루토_백업.zip',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 13,
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
        );
      },
    );
  }
}

class _SearchOpenListDemo extends StatelessWidget {
  const _SearchOpenListDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 2800,
      builder: (context, t) {
        final show = Curves.easeOutCubic.transform(_gate(t, 0.08, 0.32));
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Column(
            children: [
              const _MiniSearchField(),
              const SizedBox(height: 8),
              Opacity(
                opacity: show,
                child: Transform.translate(
                  offset: Offset(0, (1 - show) * 10),
                  child: const _MiniGroupCard(
                    title: '공부',
                    subtitle: '자기소개서 제출',
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

class _SearchGroupByDemo extends StatelessWidget {
  const _SearchGroupByDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3400,
      builder: (context, t) {
        final toDate = t < 0.5
            ? Curves.easeOutCubic.transform(_gate(t, 0.16, 0.38))
            : 1 - Curves.easeOutCubic.transform(_gate(t, 0.66, 0.88));
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Column(
            children: [
              _MiniSearchField(
                trailing: ThemedAsset(
                  asset: AppIcons.more,
                  width: 16,
                  height: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    Opacity(
                      opacity: (1 - toDate).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, toDate * 8),
                        child: const _MiniGroupCard(
                          title: '공부',
                          subtitle: '9월 4일',
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: toDate.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - toDate) * 8),
                        child: const _MiniGroupCard(
                          title: '9월 4일',
                          subtitle: '공부',
                          showCount: false,
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
}

class _SearchRangePillDemo extends StatelessWidget {
  const _SearchRangePillDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final pill = Curves.easeOutCubic.transform(_gate(t, 0.28, 0.48));
        final tap = _pulse(t, 0.12, 0.22, 0.36);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                children: [
                  _MiniSearchField(
                    trailing: ThemedAsset(
                      asset: AppIcons.more,
                      width: 16,
                      height: 16,
                    ),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: pill,
                      child: Opacity(
                        opacity: pill,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Text(
                                  '9. 1. ~ 9. 7.',
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (tap > 0)
              const Positioned(right: 28, top: 30, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }
}

class _DiaryPhotoSaveDemo extends StatelessWidget {
  const _DiaryPhotoSaveDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final photo = Curves.easeOutBack.transform(_gate(t, 0.22, 0.48));
        final check = _gate(t, 0.52, 0.7);
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
          child: _Card(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: colors.border),
                        Opacity(
                          opacity: photo.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.72 + photo * 0.28,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFBFDBFE),
                                    Color(0xFF93C5FD),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '오늘 일기',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                ),
                Opacity(
                  opacity: check,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF22C55E),
                    size: 22,
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

class _DiaryStickerRemoveDemo extends StatelessWidget {
  const _DiaryStickerRemoveDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final gone = Curves.easeInCubic.transform(_gate(t, 0.38, 0.62));
        final tap = _pulse(t, 0.22, 0.32, 0.46);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 22, 36, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 124,
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
                      Positioned(
                        right: 14,
                        top: 12,
                        child: Opacity(
                          opacity: (1 - gone).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(gone * 18, -gone * 28),
                            child: Transform.rotate(
                              angle: gone * 0.6,
                              child: Transform.scale(
                                scale: 1 - gone * 0.35,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF7ED),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Center(
                                      child: Text(
                                        '⭐',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (tap > 0)
              const Positioned(right: 48, top: 34, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }
}

class _IcloudRestoreDemo extends StatelessWidget {
  const _IcloudRestoreDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final pick = _gate(t, 0.28, 0.46);
        final tap = _pulse(t, 0.16, 0.26, 0.4);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: _Card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_rounded,
                          size: 18,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '플루토_백업.zip',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: pick,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Text(
                                AppStrings.restoreLatest,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 10,
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
                      opacity: 0.45,
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_outlined,
                            size: 18,
                            color: colors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '플루토_백업_이전.zip',
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
                  ],
                ),
              ),
            ),
            if (tap > 0)
              const Positioned(left: 36, top: 36, child: _Finger(pressed: 1)),
          ],
        );
      },
    );
  }
}

class _JobModeDemo extends StatelessWidget {
  const _JobModeDemo();

  static const _icon = 20.0;
  static const _cell = 48.0;

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3600,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final on = Curves.easeOutCubic.transform(_gate(t, 0.28, 0.52));
        final tap = _pulse(t, 0.14, 0.24, 0.4);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
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
                          height: 46,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _navIcon(AppIcons.homeOutlined, colors),
                              _navIcon(AppIcons.calendarOutlined, colors),
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: on,
                                  child: Opacity(
                                    opacity: on,
                                    child: SizedBox(
                                      width: _cell,
                                      child: Center(
                                        child: ThemedAsset(
                                          asset: AppIcons.officeOutlined,
                                          width: _icon,
                                          height: _icon,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _navIcon(AppIcons.planetOutlined, colors),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.jobMode,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.text,
                              ),
                            ),
                          ),
                          _FakeSwitch(on: on),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                right: 28,
                bottom: 18,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }

  Widget _navIcon(String asset, AppColors colors) {
    return SizedBox(
      width: _cell,
      child: Center(
        child: ThemedAsset(asset: asset, width: _icon, height: _icon),
      ),
    );
  }
}

class _FakeSwitch extends StatelessWidget {
  const _FakeSwitch({required this.on});

  final double on;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 42,
      height: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(colors.border, colors.accent, on),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: Alignment(-0.7 + on * 1.4, 0),
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _JobExpandDemo extends StatelessWidget {
  const _JobExpandDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3600,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final tap = _pulse(t, 0.12, 0.22, 0.36);
        final open = Curves.easeOutCubic.transform(
          t < 0.78 ? _gate(t, 0.22, 0.48) : 1 - _gate(t, 0.78, 0.94),
        );
        const accent = Color(0xFF5B8DEF);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
              child: _eventLabel(
                colors: colors,
                font: font,
                title: '플루토',
                subtitle: '개발 · 서버',
                accent: accent,
                badge: '면접',
                open: open,
                details: const ['9. 12.    서류', '9. 20.    면접'],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 52,
                top: 40,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }
}

class _JobFadedDemo extends StatelessWidget {
  const _JobFadedDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3200,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final fade = Curves.easeOutCubic.transform(_gate(t, 0.28, 0.55));
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Column(
            children: [
              _eventLabel(
                colors: colors,
                font: font,
                title: '플루토',
                subtitle: '개발 · 클라이언트',
                accent: const Color(0xFFF59E0B),
                badge: '서류',
                open: 0,
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: 1 - fade * 0.58,
                child: _eventLabel(
                  colors: colors,
                  font: font,
                  title: '플루토',
                  subtitle: '개발 · 서버',
                  accent: const Color(0xFF22C55E),
                  badge: fade > 0.5 ? '탈락' : '면접',
                  open: 0,
                  showBar: fade < 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WordmarkAccountDemo extends StatelessWidget {
  const _WordmarkAccountDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3600,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final custom = _gate(t, 0.28, 0.46) > 0.5;
        final tap = _pulse(t, 0.14, 0.24, 0.38);
        final cloud = Curves.easeOutCubic.transform(_gate(t, 0.5, 0.68));
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 36, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    alignment: Alignment.centerLeft,
                    scale: 1 - tap * 0.04,
                    child: Text(
                      custom ? '내 플래너' : '플루토',
                      style: TextStyle(
                        fontFamily: AppFonts.jalnan,
                        fontSize: 22,
                        color: AppFonts.wordmarkColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: cloud,
                    child: Transform.translate(
                      offset: Offset(0, (1 - cloud) * 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            size: 16,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '카카오 계정에 저장됨',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                left: 48,
                top: 42,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }
}

class _PastelTintDemo extends StatelessWidget {
  const _PastelTintDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3000,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final wash = Curves.easeInOutCubic.transform(
          t < 0.5 ? _gate(t, 0.12, 0.42) : 1 - _gate(t, 0.62, 0.9),
        );
        final amount = 0.28 - wash * 0.14;
        const accent = Color(0xFF5B8DEF);
        final bg = Color.lerp(colors.card, accent, amount)!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '자기소개서 다듬기',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '취준  ·  14:00',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.hint,
                          ),
                        ),
                      ],
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

class _PlanetCollectionDemo extends StatelessWidget {
  const _PlanetCollectionDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3600,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final page = Curves.easeInOutCubic.transform(_gate(t, 0.28, 0.62));
        final swipe = _pulse(t, 0.18, 0.3, 0.7);
        final year = page > 0.5 ? '2025' : '2026';
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Text(
                    year,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Transform.translate(
                            offset: Offset(-page * 220, 0),
                            child: _planetRow(
                              const [
                                Color(0xFF7DD3FC),
                                Color(0xFFF9A8D4),
                                Color(0xFFFCD34D),
                                Color(0xFFC4B5FD),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: Offset((1 - page) * 220, 0),
                            child: _planetRow(
                              const [
                                Color(0xFF86EFAC),
                                Color(0xFFFDBA74),
                                Color(0xFF93C5FD),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (swipe > 0)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0.35 - page * 0.8, 0.2),
                  child: _Finger(pressed: swipe),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _planetRow(List<Color> fills) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final fill in fills)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [fill.withValues(alpha: 0.35), fill],
                  center: const Alignment(-0.3, -0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: fill.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeHideJobsDemo extends StatelessWidget {
  const _HomeHideJobsDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3400,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final hide = Curves.easeOutCubic.transform(_gate(t, 0.32, 0.58));
        final tap = _pulse(t, 0.16, 0.26, 0.42);
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '오늘',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.accentBright,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _eventLabel(
                    colors: colors,
                    font: font,
                    title: '자기소개서 다듬기',
                    subtitle: '취준',
                    accent: const Color(0xFF5B8DEF),
                    badge: '',
                    open: 0,
                    compact: true,
                  ),
                  Opacity(
                    opacity: 1 - hide,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _eventLabel(
                        colors: colors,
                        font: font,
                        title: '플루토',
                        subtitle: '개발 · 면접',
                        accent: const Color(0xFF22C55E),
                        badge: '면접',
                        open: 0,
                        compact: true,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.jobMode,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                          ),
                        ),
                      ),
                      _FakeSwitch(on: 1 - hide),
                    ],
                  ),
                ],
              ),
            ),
            if (tap > 0)
              Positioned(
                right: 22,
                bottom: 12,
                child: _Finger(pressed: tap),
              ),
          ],
        );
      },
    );
  }
}

Widget _eventLabel({
  required AppColors colors,
  required String? font,
  required String title,
  required String subtitle,
  required Color accent,
  required String badge,
  required double open,
  List<String> details = const [],
  bool showBar = true,
  bool compact = false,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: Color.lerp(colors.card, accent, 0.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: compact ? 40 : 48,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: showBar ? 4 : 0,
                  color: accent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            color: colors.text,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                              color: colors.hint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (badge.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (details.isNotEmpty)
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: open,
                child: Opacity(
                  opacity: open,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in details)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
        ],
      ),
    ),
  );
}

class _PcLaunchDemo extends StatelessWidget {
  const _PcLaunchDemo();

  static const _url = 'pluto.day';

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 6800,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final typed = (_url.length * _gate(t, 0.06, 0.24)).round();
        final login = Curves.easeOutCubic.transform(_gate(t, 0.26, 0.4));
        final app = Curves.easeOutCubic.transform(_gate(t, 0.58, 0.74));
        final tap = _pulse(t, 0.44, 0.52, 0.62);
        final caretOn = typed < _url.length && (t * 12).floor().isEven;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                ColoredBox(
                  color: colors.groupedBackground,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                    child: Row(
                      children: [
                        const _WindowDot(Color(0xFFFF5F57)),
                        const SizedBox(width: 4),
                        const _WindowDot(Color(0xFFFEBC2E)),
                        const SizedBox(width: 4),
                        const _WindowDot(Color(0xFF28C840)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 10,
                                    color: typed == _url.length
                                        ? const Color(0xFF16A34A)
                                        : colors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      typed == 0
                                          ? ''
                                          : '${_url.substring(0, typed)}${caretOn ? '|' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(
                                        fontFamily: font,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors.text,
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
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(13),
                    ),
                    child: ColoredBox(
                      color: colors.background,
                      child: Stack(
                        children: [
                          if (login > 0)
                            Opacity(
                              opacity: login * (1 - app),
                              child: _PcLoginPage(
                                colors: colors,
                                font: font,
                              ),
                            ),
                          if (app > 0)
                            Opacity(
                              opacity: app,
                              child: _PcAppPage(
                                colors: colors,
                                font: font,
                              ),
                            ),
                          if (tap > 0 && app < 0.35)
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 92,
                              child: Center(child: _Finger(pressed: 1)),
                            ),
                        ],
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

class _PcLoginPage extends StatelessWidget {
  const _PcLoginPage({required this.colors, required this.font});

  final AppColors colors;
  final String? font;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppAssetImage(asset: AppIcons.plutoLogo, width: 36, height: 36),
          const SizedBox(height: 6),
          Text(
            AppStrings.webLoginBrand,
            style: TextStyle(
              fontFamily: AppFonts.jalnan,
              fontSize: 16,
              height: 1.1,
              letterSpacing: 0.6,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.webLoginTagline,
            style: TextStyle(
              fontFamily: font,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PcProviderDot(
                asset: AppIcons.kakaoLogo,
                background: Color(0xFFFEE500),
              ),
              SizedBox(width: 14),
              _PcProviderDot(
                asset: AppIcons.googleLogo,
                background: Colors.white,
                bordered: true,
              ),
              SizedBox(width: 14),
              _PcProviderDot(
                asset: AppIcons.appleLogo,
                background: Color(0xFF111111),
                tint: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PcProviderDot extends StatelessWidget {
  const _PcProviderDot({
    required this.asset,
    required this.background,
    this.bordered = false,
    this.tint,
  });

  final String asset;
  final Color background;
  final bool bordered;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: bordered
            ? Border.all(color: AppColors.of(context).border)
            : null,
      ),
      child: SizedBox.square(
        dimension: 26,
        child: Center(
          child: AppAssetImage(
            asset: asset,
            width: 14,
            height: 14,
            color: tint,
          ),
        ),
      ),
    );
  }
}

class _PcAppPage extends StatelessWidget {
  const _PcAppPage({required this.colors, required this.font});

  final AppColors colors;
  final String? font;

  static const _labels = {2: '운동', 8: '회의', 14: '약속', 19: '영화'};
  static const _labelColors = {
    2: Color(0xFF3B82F6),
    8: Color(0xFFA855F7),
    14: Color(0xFFF97316),
    19: Color(0xFFEC4899),
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '9${AppStrings.monthSuffix}',
              style: TextStyle(
                fontFamily: font,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              for (final day in AppStrings.weekdays)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          for (var week = 0; week < 4; week++)
            Expanded(
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: _PcCalDay(
                        day: week * 7 + d + 1,
                        title: _labels[week * 7 + d + 1],
                        color: _labelColors[week * 7 + d + 1],
                        font: font,
                        colors: colors,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.navBar,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThemedAsset(
                    asset: AppIcons.homeOutlined,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 18),
                  ThemedAsset(asset: AppIcons.calendar, width: 14, height: 14),
                  const SizedBox(width: 18),
                  ThemedAsset(
                    asset: AppIcons.planetOutlined,
                    width: 14,
                    height: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PcCalDay extends StatelessWidget {
  const _PcCalDay({
    required this.day,
    required this.title,
    required this.color,
    required this.font,
    required this.colors,
  });

  final int day;
  final String? title;
  final Color? color;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$day',
          style: TextStyle(
            fontFamily: font,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            height: 1,
            color: colors.secondary,
          ),
        ),
        const SizedBox(height: 1),
        if (title != null)
          CalendarEventLabel(
            title: title!,
            color: color!,
            height: 10,
            fontSize: 6,
            applyCalendarScale: false,
          ),
      ],
    );
  }
}

class _WindowDot extends StatelessWidget {
  const _WindowDot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 7),
    );
  }
}

class _AccountSyncDemo extends StatelessWidget {
  const _AccountSyncDemo();

  static const _kakaoLabels = {3: '면접', 12: '자소서'};
  static const _kakaoColors = {
    3: Color(0xFFF59E0B),
    12: Color(0xFFEAB308),
  };
  static const _kakaoSpans = [
    _SyncSpan(6, 8, '연수', Color(0xFFFB923C)),
  ];
  static const _googleLabels = {5: '운동', 16: '일기'};
  static const _googleColors = {
    5: Color(0xFF3B82F6),
    16: Color(0xFF10B981),
  };
  static const _googleSpans = [
    _SyncSpan(8, 10, '휴가', Color(0xFF38BDF8)),
  ];
  static const _appleLabels = {8: '여행', 19: '영화'};
  static const _appleColors = {
    8: Color(0xFFA855F7),
    19: Color(0xFFEC4899),
  };
  static const _appleSpans = [
    _SyncSpan(2, 4, '출장', Color(0xFFC084FC)),
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 7800,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final toGoogle = Curves.easeInOutCubic.transform(_gate(t, 0.18, 0.32));
        final toApple = Curves.easeInOutCubic.transform(_gate(t, 0.48, 0.62));
        final toStart = Curves.easeInOutCubic.transform(_gate(t, 0.80, 0.94));
        final page = (toGoogle + toApple - 2 * toStart).clamp(0.0, 2.0);
        final tapGoogle = _pulse(t, 0.10, 0.20, 0.34);
        final tapApple = _pulse(t, 0.40, 0.50, 0.64);
        return LayoutBuilder(
          builder: (context, box) {
            final slide = box.maxWidth;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SyncAccountChip(
                          asset: AppIcons.kakaoLogo,
                          label: AppStrings.accountKakaoShort,
                          selected: page < 0.5,
                          badge: const Color(0xFFF7E111),
                          font: font,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SyncTapChip(
                          tap: tapGoogle,
                          child: _SyncAccountChip(
                            asset: AppIcons.googleLogo,
                            label: AppStrings.accountGoogleShort,
                            selected: page >= 0.5 && page < 1.5,
                            badge: colors.accent,
                            font: font,
                            colors: colors,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SyncTapChip(
                          tap: tapApple,
                          child: _SyncAccountChip(
                            asset: AppIcons.appleLogo,
                            label: AppStrings.accountAppleShort,
                            selected: page >= 1.5,
                            badge: colors.muted,
                            font: font,
                            colors: colors,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          for (final i in const [0, 1, 2])
                            Transform.translate(
                              offset: Offset(slide * (i - page), 0),
                              child: _SyncVaultCal(
                                font: font,
                                colors: colors,
                                labels: switch (i) {
                                  0 => _kakaoLabels,
                                  1 => _googleLabels,
                                  _ => _appleLabels,
                                },
                                labelColors: switch (i) {
                                  0 => _kakaoColors,
                                  1 => _googleColors,
                                  _ => _appleColors,
                                },
                                spans: switch (i) {
                                  0 => _kakaoSpans,
                                  1 => _googleSpans,
                                  _ => _appleSpans,
                                },
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
      },
    );
  }
}

class _SyncTapChip extends StatelessWidget {
  const _SyncTapChip({required this.tap, required this.child});

  final double tap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        if (tap > 0)
          Positioned(
            right: 2,
            bottom: -6,
            child: _Finger(pressed: tap),
          ),
      ],
    );
  }
}

class _SyncAccountChip extends StatelessWidget {
  const _SyncAccountChip({
    required this.asset,
    required this.label,
    required this.selected,
    required this.badge,
    required this.font,
    required this.colors,
  });

  final String asset;
  final String label;
  final bool selected;
  final Color badge;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? badge.withValues(alpha: 0.22) : colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAssetImage(asset: asset, width: 12, height: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: font,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncSpan {
  const _SyncSpan(this.start, this.end, this.title, this.color);

  final int start;
  final int end;
  final String title;
  final Color color;
}

class _SyncVaultCal extends StatelessWidget {
  const _SyncVaultCal({
    required this.font,
    required this.colors,
    required this.labels,
    required this.labelColors,
    required this.spans,
  });

  final String? font;
  final AppColors colors;
  final Map<int, String> labels;
  final Map<int, Color> labelColors;
  final List<_SyncSpan> spans;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '9${AppStrings.monthSuffix}',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final day in AppStrings.weekdays)
                  Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: colors.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            for (var week = 0; week < 3; week++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _SyncVaultWeek(
                  weekStart: week * 7 + 1,
                  font: font,
                  colors: colors,
                  labels: labels,
                  labelColors: labelColors,
                  spans: spans,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SyncVaultWeek extends StatelessWidget {
  const _SyncVaultWeek({
    required this.weekStart,
    required this.font,
    required this.colors,
    required this.labels,
    required this.labelColors,
    required this.spans,
  });

  final int weekStart;
  final String? font;
  final AppColors colors;
  final Map<int, String> labels;
  final Map<int, Color> labelColors;
  final List<_SyncSpan> spans;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart + 6;
    return Column(
      children: [
        Row(
          children: [
            for (var d = 0; d < 7; d++)
              Expanded(
                child: Text(
                  '${weekStart + d}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 12,
          child: Stack(
            children: [
              Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: labels[weekStart + d] == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0.5,
                              ),
                              child: CalendarEventLabel(
                                title: labels[weekStart + d]!,
                                color: labelColors[weekStart + d]!,
                                height: 11,
                                fontSize: 7,
                                applyCalendarScale: false,
                              ),
                            ),
                    ),
                ],
              ),
              for (final span in spans)
                if (span.start <= weekEnd && span.end >= weekStart)
                  _SyncRangeBar(
                    weekStart: weekStart,
                    start: span.start < weekStart ? weekStart : span.start,
                    end: span.end > weekEnd ? weekEnd : span.end,
                    title: span.start >= weekStart ? span.title : '',
                    color: span.color,
                    showAccent: span.start >= weekStart,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncRangeBar extends StatelessWidget {
  const _SyncRangeBar({
    required this.weekStart,
    required this.start,
    required this.end,
    required this.title,
    required this.color,
    required this.showAccent,
  });

  final int weekStart;
  final int start;
  final int end;
  final String title;
  final Color color;
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final startIndex = start - weekStart;
    final span = end - start + 1;
    final trail = 6 - (end - weekStart);
    return Row(
      children: [
        if (startIndex > 0) Spacer(flex: startIndex),
        Expanded(
          flex: span,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.5),
            child: CalendarEventLabel(
              title: title,
              color: color,
              showAccent: showAccent,
              height: 11,
              fontSize: 7,
              applyCalendarScale: false,
            ),
          ),
        ),
        if (trail > 0) Spacer(flex: trail),
      ],
    );
  }
}

class _HomeMemoDemo extends StatelessWidget {
  const _HomeMemoDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3200,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final show = Curves.easeOutCubic.transform(_gate(t, 0.18, 0.42));
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 16),
          child: Row(
            children: [
              Expanded(
                child: _Card(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: SizedBox(
                    height: 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '장보기',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            height: 1.25,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '우유, 계란',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 11,
                            height: 1.3,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Opacity(
                  opacity: show,
                  child: Transform.translate(
                    offset: Offset(0, (1 - show) * 10),
                    child: _Card(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: SizedBox(
                        height: 88,
                        child: Center(
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 22,
                              height: 1,
                              color: colors.hint,
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _CategoryViewDemo extends StatelessWidget {
  const _CategoryViewDemo();

  static const _sport = Color(0xFF3B82F6);
  static const _study = Color(0xFFA855F7);

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 3400,
      builder: (context, t) {
        final font = AppFonts.of(context);
        final grouped = Curves.easeOutCubic.transform(_gate(t, 0.22, 0.48));
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: _Card(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: grouped,
                  child: _CategoryHeader(
                    name: '운동',
                    color: _sport,
                    font: font,
                  ),
                ),
                SizedBox(height: 4 * grouped),
                CalendarEventLabel(
                  title: '헬스장가기',
                  color: _sport,
                  applyCalendarScale: false,
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: grouped,
                  child: _CategoryHeader(
                    name: '공부',
                    color: _study,
                    font: font,
                  ),
                ),
                SizedBox(height: 4 * grouped),
                CalendarEventLabel(
                  title: '과제하기',
                  color: _study,
                  applyCalendarScale: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryAiDemo extends StatelessWidget {
  const _CategoryAiDemo();

  static const _title = '헬스장가기';
  static const _study = Color(0xFFA855F7);
  static const _sport = Color(0xFF3B82F6);
  static final _date = DateTime(2026, 9, 11);

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 6000,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final typed = (_title.length * _gate(t, 0.08, 0.36)).round();
        final shown = _title.substring(0, typed);
        final thinking = _gate(t, 0.36, 0.50);
        final pick = Curves.easeOutCubic.transform(_gate(t, 0.58, 0.74));
        final caretOn = t < 0.36 && (t * 12).floor().isEven;
        final color = Color.lerp(_study, _sport, pick)!;
        final loading = t >= 0.36 && pick < 0.45;
        final name = pick > 0.45 ? '운동' : '공부';
        final twinkle = thinking > 0.15 && pick < 0.85
            ? 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 22 * math.pi))
            : 1.0;
        void noop() {}
        return Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tint(color, 0.14),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                        TextSpan(
                          text: shown.isEmpty
                              ? AppStrings.eventTitleHint
                              : shown,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: shown.isEmpty ? colors.hint : colors.text,
                          ),
                        ),
                        if (shown.isNotEmpty && caretOn)
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
                                name: name,
                                color: color,
                                onPressed: noop,
                                caption: loading
                                    ? _AiDots(t: t, color: color)
                                    : null,
                                mark: Opacity(
                                  opacity: twinkle,
                                  child: AppAssetImage(
                                    asset: AppIcons.stars,
                                    width: 16,
                                    height: 16,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              EventDateChip(
                                date: _date,
                                color: color,
                                onPressed: noop,
                              ),
                              const SizedBox(width: 4),
                              EventTimeChip(
                                color: color,
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
          ),
        );
      },
    );
  }
}

class _AiDots extends StatelessWidget {
  const _AiDots({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Transform.translate(
              offset: Offset(0, 1.5 - 3 * _bounce(i)),
              child: Opacity(
                opacity: 0.35 + 0.65 * _bounce(i),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _bounce(int index) {
    final phase = (t * (6000 / 900) - index / 3) % 1;
    return math.sin(phase * math.pi).clamp(0.0, 1.0);
  }
}

class _FriendsMiniCalDemo extends StatelessWidget {
  const _FriendsMiniCalDemo();

  static const _minji = Color(0xFF60A5FA);
  static const _junho = Color(0xFF34D399);
  static const _minjiLabels = {4: '운동', 16: '약속'};
  static const _minjiColors = {
    4: Color(0xFF3B82F6),
    16: Color(0xFFF97316),
  };
  static const _minjiSpans = [
    _SyncSpan(11, 13, '여행', Color(0xFFA855F7)),
  ];
  static const _junhoLabels = {7: '회의', 19: '영화'};
  static const _junhoColors = {
    7: Color(0xFFA855F7),
    19: Color(0xFFEC4899),
  };
  static const _junhoSpans = [
    _SyncSpan(2, 4, '출장', Color(0xFF38BDF8)),
  ];
  static const _gahyunLabels = {5: '카페', 12: '수업'};
  static const _gahyunColors = {
    5: Color(0xFFF97316),
    12: Color(0xFF3B82F6),
  };
  static const _gahyunSpans = [
    _SyncSpan(16, 18, '여행', Color(0xFFA855F7)),
  ];
  static const _junhyukLabels = {2: '헬스', 15: '알바'};
  static const _junhyukColors = {
    2: Color(0xFF34D399),
    15: Color(0xFFEC4899),
  };
  static const _junhyukSpans = [
    _SyncSpan(8, 10, '시험', Color(0xFF38BDF8)),
  ];
  static const _cals = [
    (_junhoLabels, _junhoColors, _junhoSpans),
    (_gahyunLabels, _gahyunColors, _gahyunSpans),
    (_junhyukLabels, _junhyukColors, _junhyukSpans),
  ];
  static const _taehee = FriendProfile(
    uid: 'demo-taehee',
    displayName: '태희',
    friendCode: 'taehee',
  );
  static const _friends = [
    _taehee,
    FriendProfile(uid: 'demo-gahyun', displayName: '가현', friendCode: 'gahyun'),
    FriendProfile(uid: 'demo-junhyuk', displayName: '준혁', friendCode: 'junhyuk'),
    FriendProfile(uid: 'demo-minsu', displayName: '민수', friendCode: 'minsu'),
    FriendProfile(uid: 'demo-sua', displayName: '수아', friendCode: 'sua'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 9000,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final acceptTap = _pulse(t, 0.08, 0.16, 0.26);
        final accepted = t >= 0.14;
        final reveal = Curves.easeOutCubic.transform(_gate(t, 0.22, 0.36));
        final hide = Curves.easeInCubic.transform(_gate(t, 0.90, 1.0));
        final requestOpacity = (1 - reveal + hide).clamp(0.0, 1.0);
        final friendsOpacity = (reveal - hide).clamp(0.0, 1.0);
        final toGahyun = Curves.easeInOutCubic.transform(_gate(t, 0.46, 0.58));
        final toJunhyuk = Curves.easeInOutCubic.transform(_gate(t, 0.68, 0.80));
        final page = toGahyun + toJunhyuk;
        return Stack(
          children: [
            Opacity(
              opacity: requestOpacity,
              child: IgnorePointer(
                child: _FriendRequestPane(
                  accepted: accepted,
                  tap: acceptTap,
                  font: font,
                  colors: colors,
                ),
              ),
            ),
            Opacity(
              opacity: friendsOpacity,
              child: IgnorePointer(
                child: _FriendHomePane(
                  page: page,
                  tapGahyun: _pulse(t, 0.40, 0.48, 0.60),
                  tapJunhyuk: _pulse(t, 0.62, 0.70, 0.82),
                  font: font,
                  colors: colors,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FriendRequestPane extends StatelessWidget {
  const _FriendRequestPane({
    required this.accepted,
    required this.tap,
    required this.font,
    required this.colors,
  });

  final bool accepted;
  final double tap;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final check = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF40A6FF);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 2, 8),
              child: Text(
                AppStrings.friendsIncoming,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    const FriendAvatar(
                      size: 40,
                      profile: _FriendsMiniCalDemo._taehee,
                      showFavorite: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '태희',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                          Text(
                            'taehee',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 13,
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: accepted ? 0.35 : 1,
                      child: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: colors.muted,
                      ),
                    ),
                    _SyncTapChip(
                      tap: tap,
                      child: Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: check,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendHomePane extends StatelessWidget {
  const _FriendHomePane({
    required this.page,
    required this.tapGahyun,
    required this.tapJunhyuk,
    required this.font,
    required this.colors,
  });

  final double page;
  final double tapGahyun;
  final double tapJunhyuk;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          _FriendHomeRow(
            page: page,
            tapGahyun: tapGahyun,
            tapJunhyuk: tapJunhyuk,
            font: font,
            colors: colors,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _FriendCalendarCard(
              page: page,
              font: font,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendHomeRow extends StatelessWidget {
  const _FriendHomeRow({
    required this.page,
    required this.tapGahyun,
    required this.tapJunhyuk,
    required this.font,
    required this.colors,
  });

  final double page;
  final double tapGahyun;
  final double tapJunhyuk;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          _FriendHomeCell(
            label: AppStrings.friendsHomeMe,
            font: font,
            colors: colors,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const FriendAvatar(size: 34, showFavorite: false),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FriendAvatar.accentOf(context),
                        border: Border.all(color: colors.background, width: 2),
                      ),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: Icon(
                          Icons.add_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < _FriendsMiniCalDemo._friends.length; i++)
            _SyncTapChip(
              tap: i == 1
                  ? tapGahyun
                  : i == 2
                      ? tapJunhyuk
                      : 0,
              child: _FriendHomeCell(
                label: _FriendsMiniCalDemo._friends[i].label,
                selected: (page - i).abs() < 0.5,
                font: font,
                colors: colors,
                child: FriendAvatar(
                  size: 34,
                  profile: _FriendsMiniCalDemo._friends[i],
                  showFavorite: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendHomeCell extends StatelessWidget {
  const _FriendHomeCell({
    required this.label,
    required this.child,
    required this.font,
    required this.colors,
    this.selected = false,
  });

  final String label;
  final Widget child;
  final String? font;
  final AppColors colors;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: font,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              color: selected ? colors.text : colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCalendarCard extends StatelessWidget {
  const _FriendCalendarCard({
    required this.page,
    required this.font,
    required this.colors,
  });

  final double page;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, box) {
            return Stack(
              children: [
                for (var i = 0; i < _FriendsMiniCalDemo._cals.length; i++)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(box.maxWidth * (i - page), 0),
                      child: _SyncVaultCal(
                        font: font,
                        colors: colors,
                        labels: _FriendsMiniCalDemo._cals[i].$1,
                        labelColors: _FriendsMiniCalDemo._cals[i].$2,
                        spans: _FriendsMiniCalDemo._cals[i].$3,
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
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({
    required this.name,
    required this.color,
    required this.size,
    required this.colors,
    this.selected = false,
  });

  final String name;
  final Color color;
  final double size;
  final AppColors colors;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : Colors.transparent,
          width: 1.6,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tint(color, 0.28),
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Text(
              name.characters.first,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                height: 1,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureIntroDemo extends StatelessWidget {
  const _FeatureIntroDemo();

  static const _features = [
    (AppIcons.monitor, AppStrings.featureIntroPcTitle),
    (AppIcons.link, AppStrings.featureIntroSyncTitle),
    (AppIcons.stars, AppStrings.featureIntroAiTitle),
    (AppIcons.addFriend, AppStrings.featureIntroFriendsTitle),
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 7200,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final pop = Curves.easeOutBack.transform(_gate(t, 0.04, 0.18));
        final tap = _pulse(t, 0.22, 0.30, 0.40);
        final sheetUp = t < 0.82
            ? Curves.easeOutCubic.transform(_gate(t, 0.30, 0.46))
            : 1 - Curves.easeInCubic.transform(_gate(t, 0.82, 0.96));
        final selected = t < 0.50
            ? 0
            : t < 0.58
            ? 1
            : t < 0.66
            ? 2
            : 3;
        return ClipRect(
          child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '9${AppStrings.monthSuffix}',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: pop.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.78 + 0.22 * pop.clamp(0.0, 1.2),
                      child: _IntroBannerChip(colors: colors, font: font),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Opacity(
                      opacity: (1 - sheetUp * 0.55).clamp(0.2, 1.0),
                      child: _IntroMiniGrid(colors: colors, font: font),
                    ),
                  ),
                ],
              ),
            ),
            if (tap > 0 && sheetUp < 0.35)
              const Positioned(
                left: 36,
                top: 58,
                child: _Finger(pressed: 1),
              ),
            if (sheetUp > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionalTranslation(
                  translation: Offset(0, 1 - sheetUp),
                  child: _IntroSheetFrame(
                    colors: colors,
                    font: font,
                    selected: selected,
                    features: _features,
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

class _IntroBannerChip extends StatelessWidget {
  const _IntroBannerChip({required this.colors, required this.font});

  final AppColors colors;
  final String? font;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.selected,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            AppAssetImage(asset: AppIcons.plutoLogo, width: 16, height: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppStrings.featureIntroBanner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: colors.accentBright,
                ),
              ),
            ),
            Icon(Icons.close_rounded, size: 12, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _IntroMiniGrid extends StatelessWidget {
  const _IntroMiniGrid({required this.colors, required this.font});

  final AppColors colors;
  final String? font;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final day in AppStrings.weekdays)
              Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < 2; week++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var d = 1; d <= 7; d++)
                  Expanded(
                    child: Text(
                      '${week * 7 + d}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IntroSheetFrame extends StatelessWidget {
  const _IntroSheetFrame({
    required this.colors,
    required this.font,
    required this.selected,
    required this.features,
  });

  final AppColors colors;
  final String? font;
  final int selected;
  final List<(String, String)> features;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.muted.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const SizedBox(width: 32, height: 3),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < features.length; i++)
              _IntroFeatureRow(
                asset: features[i].$1,
                title: features[i].$2,
                selected: selected == i,
                colors: colors,
                font: font,
              ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.tint(colors.accent, 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppAssetImage(
                      asset: AppIcons.plutoLogo,
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.accountLogin,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroFeatureRow extends StatelessWidget {
  const _IntroFeatureRow({
    required this.asset,
    required this.title,
    required this.selected,
    required this.colors,
    required this.font,
  });

  final String asset;
  final String title;
  final bool selected;
  final AppColors colors;
  final String? font;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? colors.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppAssetImage(
              asset: asset,
              width: 16,
              height: 16,
              color: colors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

class _SettingsFollowDemo extends StatelessWidget {
  const _SettingsFollowDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 7000,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final phoneWeek = Curves.easeOutCubic.transform(_gate(t, 0.16, 0.28));
        final pcWeek = Curves.easeOutCubic.transform(_gate(t, 0.36, 0.48));
        final phoneJob = Curves.easeOutCubic.transform(_gate(t, 0.52, 0.64));
        final pcJob = Curves.easeOutCubic.transform(_gate(t, 0.70, 0.82));
        final phoneFont = Curves.easeOutCubic.transform(_gate(t, 0.20, 0.34));
        final pcFont = Curves.easeOutCubic.transform(_gate(t, 0.40, 0.54));
        final cloudA = _pulse(t, 0.28, 0.38, 0.50);
        final cloudB = _pulse(t, 0.62, 0.72, 0.84);
        final cloud = math.max(cloudA, cloudB);
        final tapWeek = _pulse(t, 0.12, 0.20, 0.32);
        final tapJob = _pulse(t, 0.48, 0.56, 0.68);
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _FollowDevice(
                      title: '폰',
                      week: phoneWeek,
                      job: phoneJob,
                      titleFont: phoneFont,
                      colors: colors,
                      font: font,
                    ),
                    if (tapWeek > 0)
                      const Positioned(
                        right: 10,
                        top: 86,
                        child: _Finger(pressed: 1),
                      ),
                    if (tapJob > 0)
                      const Positioned(
                        right: 14,
                        bottom: 16,
                        child: _Finger(pressed: 1),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                child: Opacity(
                  opacity: 0.35 + 0.65 * cloud,
                  child: Transform.scale(
                    scale: 0.86 + 0.18 * cloud,
                    child: AppAssetImage(
                      asset: AppIcons.link,
                      width: 16,
                      height: 16,
                      color: colors.accent,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _FollowDevice(
                  title: 'PC',
                  week: pcWeek,
                  job: pcJob,
                  titleFont: pcFont,
                  colors: colors,
                  font: font,
                  pcChrome: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FollowDevice extends StatelessWidget {
  const _FollowDevice({
    required this.title,
    required this.week,
    required this.job,
    required this.titleFont,
    required this.colors,
    required this.font,
    this.pcChrome = false,
  });

  final String title;
  final double week;
  final double job;
  final double titleFont;
  final AppColors colors;
  final String? font;
  final bool pcChrome;

  @override
  Widget build(BuildContext context) {
    const labels = [
      AppStrings.homeShowToday,
      AppStrings.homeShowTomorrow,
      AppStrings.homeShowWeek,
    ];
    final on = [1.0, 1.0, week];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(colors.card, colors.tint(colors.accent, 0.16), job),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pcChrome)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: const [
                    _WindowDot(Color(0xFFFF5F57)),
                    SizedBox(width: 3),
                    _WindowDot(Color(0xFFFEBC2E)),
                    SizedBox(width: 3),
                    _WindowDot(Color(0xFF28C840)),
                  ],
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: titleFont > 0.5 ? AppFonts.jalnan : font,
                fontSize: titleFont > 0.5 ? 13 : 11,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(
                      on[i] > 0.5
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 15,
                      color: Color.lerp(colors.border, colors.accent, on[i]),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.jobMode,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                Transform.scale(scale: 0.78, child: _FakeSwitch(on: job)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPaintDemo extends StatelessWidget {
  const _LoginPaintDemo();

  static const _theme = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 6400,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final login = 1 - Curves.easeInCubic.transform(_gate(t, 0.28, 0.40));
        final home = Curves.easeOutCubic.transform(_gate(t, 0.36, 0.48));
        final photo = Curves.easeOutCubic.transform(_gate(t, 0.62, 0.80));
        final tap = _pulse(t, 0.16, 0.24, 0.36);
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(colors.card, const Color(0xFFFCE7F3), home),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                children: [
                  if (login > 0)
                    Opacity(
                      opacity: login,
                      child: _PaintLogin(colors: colors, font: font),
                    ),
                  if (home > 0)
                    Opacity(
                      opacity: home,
                      child: Transform.scale(
                        scale: 0.96 + 0.04 * home,
                        child: _PaintHome(
                          colors: colors,
                          font: font,
                          photo: photo,
                        ),
                      ),
                    ),
                  if (tap > 0 && home < 0.2)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 118,
                      child: Center(child: _Finger(pressed: 1)),
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

class _PaintLogin extends StatelessWidget {
  const _PaintLogin({required this.colors, required this.font});

  final AppColors colors;
  final String? font;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppAssetImage(asset: AppIcons.plutoLogo, width: 32, height: 32),
          const SizedBox(height: 6),
          Text(
            AppStrings.webLoginBrand,
            style: TextStyle(
              fontFamily: AppFonts.jalnan,
              fontSize: 16,
              height: 1.1,
              letterSpacing: 0.5,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PcProviderDot(
                asset: AppIcons.kakaoLogo,
                background: Color(0xFFFEE500),
              ),
              SizedBox(width: 12),
              _PcProviderDot(
                asset: AppIcons.googleLogo,
                background: Colors.white,
                bordered: true,
              ),
              SizedBox(width: 12),
              _PcProviderDot(
                asset: AppIcons.appleLogo,
                background: Color(0xFF111111),
                tint: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaintHome extends StatelessWidget {
  const _PaintHome({
    required this.colors,
    required this.font,
    required this.photo,
  });

  final AppColors colors;
  final String? font;
  final double photo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontFamily: AppFonts.jalnan,
              fontSize: 15,
              height: 1.1,
              color: _LoginPaintDemo._theme,
            ),
          ),
          const SizedBox(height: 10),
          for (final label in [
            AppStrings.homeShowToday,
            AppStrings.homeShowTomorrow,
            AppStrings.homeShowWeek,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_box_rounded,
                        size: 14,
                        color: _LoginPaintDemo._theme,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.selected,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SizedBox.expand(),
                ),
                Opacity(
                  opacity: photo,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF9A8D4), Color(0xFFFB7185)],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                if (photo < 0.85)
                  Center(
                    child: Opacity(
                      opacity: (1 - photo).clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: colors.muted,
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
  }
}

class _FeatureIntroStayDemo extends StatelessWidget {
  const _FeatureIntroStayDemo();

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 6200,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final login = t < 0.78
            ? Curves.easeOutCubic.transform(_gate(t, 0.18, 0.34))
            : 1 - Curves.easeInCubic.transform(_gate(t, 0.78, 0.92));
        final tapLogin = _pulse(t, 0.10, 0.18, 0.30);
        final tapClose = _pulse(t, 0.58, 0.66, 0.78);
        return ClipRect(
          child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: _IntroSheetFrame(
                colors: colors,
                font: font,
                selected: 1,
                features: _FeatureIntroDemo._features,
              ),
            ),
            if (tapLogin > 0 && login < 0.25)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(child: _Finger(pressed: 1)),
              ),
            if (login > 0)
              Opacity(
                opacity: login,
                child: ColoredBox(
                  color: const Color(0x66000000),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionalTranslation(
                      translation: Offset(0, 1 - login),
                      child: _StayLoginSheet(colors: colors, font: font),
                    ),
                  ),
                ),
              ),
            if (tapClose > 0 && login > 0.6)
              const Positioned(
                right: 28,
                top: 28,
                child: _Finger(pressed: 1),
              ),
          ],
          ),
        );
      },
    );
  }
}

class _StayLoginSheet extends StatelessWidget {
  const _StayLoginSheet({required this.colors, required this.font});

  final AppColors colors;
  final String? font;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                Icon(Icons.close_rounded, size: 18, color: colors.muted),
              ],
            ),
            const AppAssetImage(
              asset: AppIcons.plutoLogo,
              width: 30,
              height: 30,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.webLoginBrand,
              style: TextStyle(
                fontFamily: AppFonts.jalnan,
                fontSize: 16,
                height: 1.1,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PcProviderDot(
                  asset: AppIcons.kakaoLogo,
                  background: Color(0xFFFEE500),
                ),
                SizedBox(width: 12),
                _PcProviderDot(
                  asset: AppIcons.googleLogo,
                  background: Colors.white,
                  bordered: true,
                ),
                SizedBox(width: 12),
                _PcProviderDot(
                  asset: AppIcons.appleLogo,
                  background: Color(0xFF111111),
                  tint: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FriendsAddDemo extends StatelessWidget {
  const _FriendsAddDemo();

  static const _id = 'minji';

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 7200,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final typed = (_id.length * _gate(t, 0.08, 0.30)).round();
        final shown = _id.substring(0, typed);
        final caretOn = typed < _id.length && (t * 12).floor().isEven;
        final sendTap = _pulse(t, 0.34, 0.44, 0.56);
        final press = sendTap * 0.08;
        final reveal = Curves.easeOutCubic.transform(_gate(t, 0.46, 0.62));
        final hide = Curves.easeInCubic.transform(_gate(t, 0.88, 1.0));
        final list = (reveal - hide).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: shown.isEmpty
                                      ? AppStrings.friendsCodeHint
                                      : shown,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: shown.isEmpty
                                        ? colors.hint
                                        : colors.text,
                                  ),
                                ),
                                if (shown.isNotEmpty && caretOn)
                                  TextSpan(
                                    text: '|',
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 15,
                                      color: colors.accent,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Transform.scale(
                        scale: 1 - press,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.tint(colors.accent, 0.16 + sendTap * 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            height: 34,
                            child: Center(
                              child: Text(
                                AppStrings.friendsSend,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 13,
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
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: list,
                  child: Opacity(
                    opacity: list,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 2, 6),
                            child: Text(
                              AppStrings.friendsOutgoing,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.text,
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                              child: Row(
                                children: [
                                  _FriendAvatar(
                                    name: '민지',
                                    color: _FriendsMiniCalDemo._minji,
                                    size: 28,
                                    colors: colors,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '민지',
                                          style: TextStyle(
                                            fontFamily: font,
                                            fontSize: 13,
                                            color: colors.text,
                                          ),
                                        ),
                                        Text(
                                          _id,
                                          style: TextStyle(
                                            fontFamily: font,
                                            fontSize: 11,
                                            color: colors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    AppStrings.friendsCancel,
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
                          ),
                        ],
                      ),
                    ),
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

class _PcEnterSaveDemo extends StatelessWidget {
  const _PcEnterSaveDemo();

  static const _title = '헬스장가기';
  static const _accent = Color(0xFF3B82F6);
  static final _date = DateTime(2026, 9, 15);

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 6400,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final typed = (_title.length * _gate(t, 0.08, 0.36)).round();
        final shown = _title.substring(0, typed);
        final caretOn = typed < _title.length && (t * 12).floor().isEven;
        final enterLit = Curves.easeOutCubic.transform(_gate(t, 0.42, 0.52));
        final press = _pulse(t, 0.50, 0.58, 0.70);
        final saved = Curves.easeOutCubic.transform(_gate(t, 0.58, 0.72));
        void noop() {}
        return Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tint(_accent, 0.14),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                        TextSpan(
                          text: shown.isEmpty
                              ? AppStrings.eventTitleHint
                              : shown,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: shown.isEmpty ? colors.hint : colors.text,
                          ),
                        ),
                        if (shown.isNotEmpty && caretOn)
                          TextSpan(
                            text: '|',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: _accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            children: [
                              EventCategoryChip(
                                name: '운동',
                                color: _accent,
                                onPressed: noop,
                              ),
                              const SizedBox(width: 4),
                              EventDateChip(
                                date: _date,
                                color: _accent,
                                onPressed: noop,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: enterLit,
                        child: Transform.translate(
                          offset: Offset(0, (1 - enterLit) * 8),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _EnterKey(
                              lit: press,
                              font: font,
                              colors: colors,
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 1 - press * 0.12,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SaveCompanyButton(onPressed: noop, color: _accent),
                            if (saved > 0.2)
                              Opacity(
                                opacity: saved,
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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

class _EnterKey extends StatelessWidget {
  const _EnterKey({
    required this.lit,
    required this.font,
    required this.colors,
  });

  final double lit;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final fill = Color.lerp(colors.card, colors.accent, 0.12 + lit * 0.28)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color.lerp(colors.border, colors.accent, lit)!,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.18 * lit),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'Enter',
          style: TextStyle(
            fontFamily: font,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color.lerp(colors.muted, colors.accent, lit),
          ),
        ),
      ),
    );
  }
}

class _JobCategorySlideDemo extends StatelessWidget {
  const _JobCategorySlideDemo();

  static const _jobs = [
    (title: '플루토', subtitle: '개발 · 서버', badge: '서류', color: Color(0xFF5B8DEF)),
    (title: '플루토', subtitle: '개발 · 클라', badge: '면접', color: Color(0xFFA855F7)),
    (title: '아틀리에', subtitle: '디자인', badge: '서류', color: Color(0xFFFB7185)),
  ];

  @override
  Widget build(BuildContext context) {
    return _Loop(
      ms: 6800,
      boxHeight: 220,
      builder: (context, t) {
        final colors = AppColors.of(context);
        final font = AppFonts.of(context);
        final grouped = Curves.easeInOutCubic.transform(
          t < 0.58 ? _gate(t, 0.22, 0.48) : 1 - _gate(t, 0.78, 0.96),
        );
        final tap = _pulse(t, 0.12, 0.22, 0.36);
        const cardH = 40.0;
        const gap = 8.0;
        const headerH = 18.0;
        const headerGap = 10.0;
        const top = 38.0;
        final allYs = [top, top + cardH + gap, top + (cardH + gap) * 2];
        final groupYs = [
          top + headerH + 4,
          top + headerH + 4 + cardH + gap,
          top + headerH + 4 + (cardH + gap) * 2 + headerH + headerGap,
        ];
        final header1Y = top;
        final header2Y = top + headerH + 4 + (cardH + gap) * 2 + 4;
        double yOf(int i) => allYs[i] + (groupYs[i] - allYs[i]) * grouped;
        return Stack(
          children: [
            Positioned(
              left: 16,
              right: 16,
              top: 8,
              child: Row(
                children: [
                  _ViewChip(
                    label: '전체',
                    selected: grouped < 0.5,
                    font: font,
                    colors: colors,
                  ),
                  const SizedBox(width: 6),
                  _SyncTapChip(
                    tap: tap,
                    child: _ViewChip(
                      label: '카테고리별',
                      selected: grouped >= 0.5,
                      font: font,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              top: header1Y,
              child: Opacity(
                opacity: grouped,
                child: _CategoryHeader(
                  name: '개발',
                  color: const Color(0xFF5B8DEF),
                  font: font,
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: header2Y,
              child: Opacity(
                opacity: grouped,
                child: _CategoryHeader(
                  name: '디자인',
                  color: const Color(0xFFFB7185),
                  font: font,
                ),
              ),
            ),
            for (var i = 0; i < _jobs.length; i++)
              Positioned(
                left: 16,
                right: 16,
                top: yOf(i),
                child: _eventLabel(
                  colors: colors,
                  font: font,
                  title: _jobs[i].title,
                  subtitle: _jobs[i].subtitle,
                  accent: _jobs[i].color,
                  badge: _jobs[i].badge,
                  open: 0,
                  compact: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.label,
    required this.selected,
    required this.font,
    required this.colors,
  });

  final String label;
  final bool selected;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? colors.accent.withValues(alpha: 0.16) : colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: font,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: selected ? colors.accent : colors.muted,
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.name,
    required this.color,
    required this.font,
  });

  final String name;
  final Color color;
  final String? font;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 7),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: TextStyle(
            fontFamily: font,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
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
