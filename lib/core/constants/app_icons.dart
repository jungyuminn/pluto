import 'package:pluto/domain/entities/long_goal.dart';

class AppIcons {
  AppIcons._();

  static const home = 'assets/icons/home.svg';
  static const homeOutlined = 'assets/icons/home_outlined.svg';
  static const calendar = 'assets/icons/calendar.svg';
  static const calendarOutlined = 'assets/icons/calendar_outlined.svg';
  static const cursor = 'assets/icons/cursor.png';
  static const memo = 'assets/icons/memo.png';
  static const memoOutlined = 'assets/icons/memo_outlined.png';
  static const wallet = 'assets/icons/wallet.png';
  static const walletOutlined = 'assets/icons/wallet_outlined.png';
  static const quickView = 'assets/icons/quick_view.png';
  static const detailView = 'assets/icons/detail_view.png';
  static const search = 'assets/icons/search.png';
  static const more = 'assets/icons/more.png';
  static const pen = 'assets/icons/pen.png';
  static const penOutlined = 'assets/icons/pen_outlined.png';
  static const paintBrush = 'assets/icons/paint_brush.png';
  static const paintBrushOutlined = 'assets/icons/paint_brush_outlined.png';
  static const erase = 'assets/icons/erase.png';
  static const eraseOutlined = 'assets/icons/eraser_outlined.png';
  static const circle = 'assets/icons/circle.png';
  static const circleOutlined = 'assets/icons/circle_outlined.png';
  static const square = 'assets/icons/square.png';
  static const squareOutlined = 'assets/icons/square_outlined.png';
  static const line = 'assets/icons/line.png';
  static const lineOutlined = 'assets/icons/line_outlined.png';
  static const zoomIn = 'assets/icons/zoom_in.png';
  static const zoomInOutlined = 'assets/icons/zoom_in_outlined.png';
  static const zoomOut = 'assets/icons/zoom_out.png';
  static const zoomOutOutlined = 'assets/icons/zoom_out_outlined.png';
  static const maximizeOutlined = 'assets/icons/maximize_outlined.png';
  static const minimizeOutlined = 'assets/icons/minimize_outlined.png';
  static const logo = 'assets/images/logo.png';
  static const plutoLogo = 'assets/images/pluto_logo.png';
  static const notebook = 'assets/images/notebook.png';
  static const tablet = 'assets/images/tablet.png';
  static const statistics = 'assets/icons/statistics.png';
  static const statisticsOutlined = 'assets/icons/statistics_outlined.png';
  static const planet = 'assets/icons/planet.svg';
  static const planetOutlined = 'assets/icons/planet_outlined.svg';
  static const office = 'assets/icons/office.png';
  static const officeOutlined = 'assets/icons/office_outlined.png';
  static const calendarList = 'assets/icons/calendar_list.png';
  static const time = 'assets/icons/time.png';
  static const clock = 'assets/icons/clock.png';
  static const clockOutlined = 'assets/icons/clock_outlined.png';
  static const clockRemove = 'assets/icons/clock_remove.png';
  static const setting = 'assets/icons/setting.png';
  static const resume = 'assets/icons/resume.png';
  static const resumeOutlined = 'assets/icons/resume_outlined.png';
  static const folderOutlined = 'assets/icons/folder_outlined.png';
  static const status = 'assets/icons/status.png';
  static const statusOutlined = 'assets/icons/status_outlined.png';
  static const trashCan = 'assets/icons/trash_can.png';
  static const editOutlined = 'assets/icons/edit_outlined.png';
  static const emoji = 'assets/icons/emoji.png';
  static const googleLogo = 'assets/icons/google_logo.png';
  static const kakaoLogo = 'assets/icons/kakao_logo.png';
  static const appleLogo = 'assets/icons/apple_logo.svg';
  static const diary = 'assets/icons/diary.png';
  static const diaryOutlined = 'assets/icons/diary_outlined.png';
  static const longGoalMeasure = 'assets/icons/value.png';
  static const longGoalMeasureOutlined = 'assets/icons/value_outlined.png';
  static const longGoalSum = 'assets/icons/stack.png';
  static const longGoalSumOutlined = 'assets/icons/stack_outlined.png';
  static const longGoalDaily = 'assets/icons/everyday.png';
  static const longGoalDailyOutlined = 'assets/icons/everyday_outlined.png';
  static const longGoalStreak = 'assets/icons/sequence.png';
  static const longGoalStreakOutlined = 'assets/icons/sequence_outlined.png';

  static String longGoalKind(LongGoalKind kind, {required bool filled}) {
    return switch (kind) {
      LongGoalKind.measure =>
        filled ? longGoalMeasure : longGoalMeasureOutlined,
      LongGoalKind.sum => filled ? longGoalSum : longGoalSumOutlined,
      LongGoalKind.daily => filled ? longGoalDaily : longGoalDailyOutlined,
      LongGoalKind.streak => filled ? longGoalStreak : longGoalStreakOutlined,
    };
  }
}
