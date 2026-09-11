import 'package:pluto/domain/entities/long_goal.dart';

class AppIcons {
  AppIcons._();

  static const home = 'assets/icons/home.svg';
  static const homeOutlined = 'assets/icons/home_outlined.svg';
  static const calendar = 'assets/icons/calendar.svg';
  static const calendarOutlined = 'assets/icons/calendar_outlined.svg';
  static const cursor = 'assets/icons/cursor.svg';
  static const memo = 'assets/icons/memo.svg';
  static const memoOutlined = 'assets/icons/memo_outlined.svg';
  static const wallet = 'assets/icons/wallet.svg';
  static const walletOutlined = 'assets/icons/wallet_outlined.svg';
  static const quickView = 'assets/icons/quick_view.svg';
  static const detailView = 'assets/icons/detail_view.svg';
  static const search = 'assets/icons/search.svg';
  static const stars = 'assets/icons/stars.svg';
  static const addFriend = 'assets/icons/add_friend.svg';
  static const monitor = 'assets/icons/monitor.svg';
  static const link = 'assets/icons/link.svg';
  static const more = 'assets/icons/more.svg';
  static const pen = 'assets/icons/pen.svg';
  static const penOutlined = 'assets/icons/pen_outlined.svg';
  static const paintBrush = 'assets/icons/paint_brush.svg';
  static const paintBrushOutlined = 'assets/icons/paint_brush_outlined.svg';
  static const erase = 'assets/icons/eraser.svg';
  static const eraseOutlined = 'assets/icons/eraser_outlined.svg';
  static const circle = 'assets/icons/circle.svg';
  static const circleOutlined = 'assets/icons/circle_outlined.svg';
  static const square = 'assets/icons/square.svg';
  static const squareOutlined = 'assets/icons/square_outlined.svg';
  static const line = 'assets/icons/line.svg';
  static const lineOutlined = 'assets/icons/line_outlined.svg';
  static const zoomIn = 'assets/icons/zoom_in.svg';
  static const zoomInOutlined = 'assets/icons/zoom_in_outlined.svg';
  static const zoomOut = 'assets/icons/zoom_out.svg';
  static const zoomOutOutlined = 'assets/icons/zoom_out_outlined.svg';
  static const maximizeOutlined = 'assets/icons/maximize_outlined.svg';
  static const logo = 'assets/images/logo.png';
  static const plutoLogo = 'assets/images/pluto_logo_1024.svg';
  static const notebook = 'assets/images/notebook.png';
  static const tablet = 'assets/images/tablet.png';
  static const planet = 'assets/icons/planet.svg';
  static const planetOutlined = 'assets/icons/planet_outlined.svg';
  static const office = 'assets/icons/office.svg';
  static const officeOutlined = 'assets/icons/office_outlined.svg';
  static const calendarList = 'assets/icons/calendar_list.svg';
  static const clock = 'assets/icons/clock.svg';
  static const clockRemove = 'assets/icons/clock_remove.svg';
  static const setting = 'assets/icons/setting.svg';
  static const resume = 'assets/icons/resume.svg';
  static const resumeOutlined = 'assets/icons/resume_outlined.svg';
  static const status = 'assets/icons/status.svg';
  static const trashCan = 'assets/icons/trash_can.svg';
  static const editOutlined = 'assets/icons/edit_outlined.svg';
  static const emoji = 'assets/icons/emoji.svg';
  static const googleLogo = 'assets/icons/google_logo.svg';
  static const kakaoLogo = 'assets/icons/kakao_logo.svg';
  static const appleLogo = 'assets/icons/apple_logo.svg';
  static const diary = 'assets/icons/diary.svg';
  static const longGoalMeasure = 'assets/icons/value.svg';
  static const longGoalMeasureOutlined = 'assets/icons/value_outlined.svg';
  static const longGoalSum = 'assets/icons/stack.svg';
  static const longGoalSumOutlined = 'assets/icons/stack_outlined.svg';
  static const longGoalDaily = 'assets/icons/everyday.svg';
  static const longGoalDailyOutlined = 'assets/icons/everyday_outlined.svg';
  static const longGoalStreak = 'assets/icons/sequence.svg';
  static const longGoalStreakOutlined = 'assets/icons/sequence_outlined.svg';

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
