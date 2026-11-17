import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/app_dialog.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/group_calendar_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/group_calendar.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_weekday_header.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_events_dialog.dart';
import 'package:pluto/presentation/screens/friends/group_calendar_sheets.dart';
import 'package:pluto/presentation/screens/friends/friends_toast.dart';
import 'package:pluto/presentation/widgets/app_calendar/calendar_zoom_picker.dart';
import 'package:pluto/presentation/widgets/app_calendar/web_calendar_arrow.dart';
import 'package:pluto/presentation/widgets/overlay_app_bar.dart';
import 'package:pluto/presentation/widgets/overflow_menu.dart';

class GroupCalendarScreen extends StatefulWidget {
  const GroupCalendarScreen({super.key, required this.calendar});

  final GroupCalendar calendar;

  @override
  State<GroupCalendarScreen> createState() => _GroupCalendarScreenState();
}

class _GroupCalendarScreenState extends State<GroupCalendarScreen> {
  static const _initialPage = 12000;

  late GroupCalendar _calendar;
  late DateTime _baseMonth;
  late DateTime _month;
  late PageController _pages;
  late final ValueNotifier<DateTime> _monthTick;
  late final ValueNotifier<int> _dataTick;
  final _eventsByMonth = <String, List<CalendarEvent>>{};
  final _failedMonths = <String>{};
  final _monthSubs = <String, StreamSubscription<List<CalendarEvent>>>{};
  StreamSubscription<GroupCalendar?>? _calendarSub;
  var _hint = '';
  var _hintVisible = false;
  var _zoom = CalendarZoomLevel.days;
  var _closing = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _calendar = widget.calendar;
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _month = _baseMonth;
    _monthTick = ValueNotifier(_baseMonth);
    _dataTick = ValueNotifier(0);
    _pages = PageController(initialPage: _initialPage);
    _calendarSub = GroupCalendarService.instance.watch(_calendar.id).listen(
      (next) {
        if (!mounted || _closing) return;
        if (next == null) {
          _popOut();
          return;
        }
        setState(() => _calendar = next);
      },
      onError: (_) {
        if (_closing) return;
        _popOut();
      },
    );
    _watch(_month);
    _watch(_monthAt(_initialPage - 1));
    _watch(_monthAt(_initialPage + 1));
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _calendarSub?.cancel();
    for (final sub in _monthSubs.values) {
      sub.cancel();
    }
    _monthTick.dispose();
    _dataTick.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _popOut() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  void _toast(String text) {
    _hintTimer?.cancel();
    setState(() {
      _hint = text;
      _hintVisible = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  String _monthKey(DateTime month) => '${month.year}-${month.month}';

  DateTime _monthAt(int page) {
    return DateTime(_baseMonth.year, _baseMonth.month + (page - _initialPage));
  }

  int _pageOf(DateTime month) {
    final delta =
        (month.year - _baseMonth.year) * 12 + (month.month - _baseMonth.month);
    return _initialPage + delta;
  }

  void _onTitlePressed() {
    if (_zoom == CalendarZoomLevel.years) {
      unawaited(_showDays());
      return;
    }
    setState(() => _zoom = CalendarZoom.next(_zoom));
  }

  void _rememberMonth(DateTime month) {
    final next = DateTime(month.year, month.month);
    _month = next;
    if (_monthTick.value.year != next.year ||
        _monthTick.value.month != next.month) {
      _monthTick.value = next;
    }
  }

  bool get _loadingCurrent {
    final key = _monthKey(_month);
    return !_eventsByMonth.containsKey(key) && !_failedMonths.contains(key);
  }

  String? get _errorCurrent {
    final key = _monthKey(_month);
    return _failedMonths.contains(key)
        ? AppStrings.groupCalendarDenied
        : null;
  }

  void _pickYear(int year) {
    _rememberMonth(DateTime(year, _month.month));
    setState(() => _zoom = CalendarZoomLevel.months);
  }

  Future<void> _pickMonth(DateTime month) async {
    await _showDays(month);
  }

  Future<void> _showDays([DateTime? month]) async {
    final target = DateTime(
      (month ?? _month).year,
      (month ?? _month).month,
    );
    _rememberMonth(target);
    setState(() => _zoom = CalendarZoomLevel.days);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (_pages.hasClients) {
      final page = _pageOf(target);
      if ((_pages.page?.round() ?? _initialPage) != page) {
        _pages.jumpToPage(page);
      }
    }
    _watch(target);
    _watch(DateTime(target.year, target.month - 1));
    _watch(DateTime(target.year, target.month + 1));
  }

  void _stepCalendar(int direction) {
    final next = switch (_zoom) {
      CalendarZoomLevel.days => DateTime(_month.year, _month.month + direction),
      CalendarZoomLevel.months =>
        DateTime(_month.year + direction, _month.month),
      CalendarZoomLevel.years =>
        DateTime(_month.year + 10 * direction, _month.month),
    };
    if (_zoom == CalendarZoomLevel.days) {
      unawaited(_goToMonth(next));
      return;
    }
    _rememberMonth(next);
    setState(() {});
  }

  Future<void> _goToMonth(DateTime month) async {
    final target = DateTime(month.year, month.month);
    if (!_pages.hasClients) {
      _rememberMonth(target);
      return;
    }
    final page = _pageOf(target);
    final current = _pages.page?.round() ?? _initialPage;
    if (current == page) {
      _rememberMonth(target);
      return;
    }
    final distance = (page - current).abs();
    if (distance > 18) {
      _pages.jumpToPage(page);
      _rememberMonth(target);
      return;
    }
    final ms = (200 + distance * 45).clamp(240, 560);
    await _pages.animateToPage(
      page,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    _rememberMonth(target);
  }

  void _watch(DateTime month) {
    final key = _monthKey(month);
    if (_monthSubs.containsKey(key)) return;
    _monthSubs[key] = GroupCalendarService.instance
        .eventsInMonth(calendarId: _calendar.id, month: month)
        .listen(
      (events) {
        _eventsByMonth[key] = events;
        _failedMonths.remove(key);
        _dataTick.value++;
      },
      onError: (_) {
        _failedMonths.add(key);
        _dataTick.value++;
      },
    );
  }

  void _onPageChanged(int page) {
    final month = _monthAt(page);
    _rememberMonth(month);
    _watch(month);
    _watch(_monthAt(page - 1));
    _watch(_monthAt(page + 1));
  }

  List<CalendarEvent> _eventsOn(DateTime date) {
    final events = _eventsByMonth[_monthKey(date)] ?? const [];
    return [
      for (final event in events)
        if (event.day.year == date.year &&
            event.day.month == date.month &&
            event.day.day == date.day)
          event,
    ];
  }

  String _memberLine() {
    final me = FriendService.instance.profile.value?.uid ?? '';
    final friends = FriendService.instance.lastFriends;
    final names = <String>[];
    for (final uid in _calendar.memberUids) {
      if (uid == me) {
        names.add(AppStrings.friendsHomeMe);
        continue;
      }
      FriendProfileMatch? match;
      for (final friend in friends) {
        if (friend.uid == uid) {
          match = FriendProfileMatch(friend.label);
          break;
        }
      }
      names.add(match?.label ?? '');
    }
    return names.where((name) => name.isNotEmpty).join(', ');
  }

  Future<void> _openDay(DateTime date, Rect? origin) async {
    await showDayEventsDialog(
      context,
      date: date,
      events: _eventsOn(date),
      origin: origin,
      groupCalendarId: _calendar.id,
      eventsForDate: (day) async => _eventsOn(day),
      onEventsChanged: () => _dataTick.value++,
    );
  }

  Future<void> _invite() async {
    await showInviteGroupCalendarSheet(context, calendar: _calendar);
  }

  Future<void> _rename() async {
    final ok = await showRenameGroupCalendarSheet(
      context,
      calendar: _calendar,
    );
    if (!ok || !mounted) return;
    _toast(AppStrings.groupCalendarRenamed);
  }

  Future<void> _leaveOrDelete() async {
    final me = FriendService.instance.profile.value?.uid ?? '';
    final owner = _calendar.isOwner(me);
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: owner
            ? AppStrings.groupCalendarDeleteTitle
            : AppStrings.groupCalendarLeaveTitle,
        body: owner
            ? AppStrings.groupCalendarDeleteBody
            : AppStrings.groupCalendarLeaveBody,
        action: owner
            ? AppStrings.groupCalendarDelete
            : AppStrings.groupCalendarLeave,
      ),
    );
    if (ok != true || !mounted) return;
    final service = GroupCalendarService.instance;
    _closing = true;
    await _calendarSub?.cancel();
    _calendarSub = null;
    try {
      if (owner) {
        await service.delete(_calendar.id);
      } else {
        await service.leave(_calendar.id);
      }
      if (!mounted) return;
      showFriendsToast(
        context,
        owner
            ? AppStrings.groupCalendarDeleted
            : AppStrings.groupCalendarLeft,
      );
      Navigator.of(context).pop();
    } catch (error) {
      _closing = false;
      if (!mounted) return;
      await showMissingFieldsDialog(
        context,
        title: owner
            ? AppStrings.groupCalendarDelete
            : AppStrings.groupCalendarLeave,
        body: service.messageOf(error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final startMonday = AppScope.of(context).calendarPreference.startMonday;
    final top = MediaQuery.paddingOf(context).top;
    final me = FriendService.instance.profile.value?.uid ?? '';
    return Scaffold(
      backgroundColor: colors.pageBackground,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: _Bar(onBack: () => Navigator.pop(context)),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 56, 16, 12),
            child: Column(
              children: [
                _card(
                  colors,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _calendar.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFonts.of(context),
                                  fontSize: 16,
                                  color: colors.text,
                                ),
                              ),
                              Text(
                                _memberLine().isEmpty
                                    ? AppStrings.groupCalendarMemberCount(
                                        _calendar.memberUids.length,
                                      )
                                    : _memberLine(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFonts.of(context),
                                  fontSize: 13,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OverflowMenuButton(
                          actions: [
                            OverflowMenuAction(
                              label: AppStrings.groupCalendarInvite,
                              leadingAsset: AppIcons.addFriend,
                              onPressed: _invite,
                            ),
                            if (_calendar.isOwner(me))
                              OverflowMenuAction(
                                label: AppStrings.groupCalendarRename,
                                leadingAsset: AppIcons.edit,
                                onPressed: _rename,
                              ),
                            OverflowMenuAction(
                              label: _calendar.isOwner(me)
                                  ? AppStrings.groupCalendarDelete
                                  : AppStrings.groupCalendarLeave,
                              leadingAsset: AppIcons.trashCan,
                              color: colors.danger,
                              onPressed: _leaveOrDelete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _card(
                    colors,
                    child: WebCalendarArrowHost(
                      onPrevious: () => _stepCalendar(-1),
                      onNext: () => _stepCalendar(1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _zoom == CalendarZoomLevel.days
                                  ? CalendarPagerTitle(
                                      controller: _pages,
                                      initialPage: _initialPage,
                                      monthAt: _monthAt,
                                      hideCurrentYear: true,
                                      fontSize: 20,
                                      onPressed: _onTitlePressed,
                                    )
                                  : CalendarZoomTitle(
                                      text: CalendarZoom.title(
                                        _zoom,
                                        _month,
                                        hideCurrentYear: true,
                                      ),
                                      fontSize: 20,
                                      onPressed: _onTitlePressed,
                                    ),
                            ),
                          ),
                          Expanded(
                            child: RepaintBoundary(
                              child: CalendarZoomTransition(
                                level: _zoom,
                                child: switch (_zoom) {
                                  CalendarZoomLevel.days => Column(
                                    children: [
                                      CalendarWeekdayHeader(
                                        startMonday: startMonday,
                                      ),
                                      Expanded(
                                        child: MouseDragScroll(
                                          controller: _pages,
                                          child: PageView.builder(
                                            controller: _pages,
                                            physics:
                                                const CalendarPagePhysics(),
                                            onPageChanged: _onPageChanged,
                                            itemBuilder: (context, page) {
                                              final month = _monthAt(page);
                                              return ListenableBuilder(
                                                listenable: _dataTick,
                                                builder: (context, _) {
                                                  return CalendarMonthGrid(
                                                    month: month,
                                                    tutorial: false,
                                                    startMonday: startMonday,
                                                    eventsOf: _eventsOn,
                                                    onDayPressed: _openDay,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  CalendarZoomLevel.months =>
                                    CalendarMonthZoomView(
                                      focused: _month,
                                      accent: colors.accentBright,
                                      onFocusedChanged: (month) {
                                        _rememberMonth(month);
                                        setState(() {});
                                      },
                                      onMonthPressed: _pickMonth,
                                    ),
                                  CalendarZoomLevel.years =>
                                    CalendarYearZoomView(
                                      focused: _month,
                                      accent: colors.accentBright,
                                      onFocusedChanged: (month) {
                                        _rememberMonth(month);
                                        setState(() {});
                                      },
                                      onYearPressed: _pickYear,
                                    ),
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([_monthTick, _dataTick]),
                  builder: (context, _) {
                    final error = _errorCurrent;
                    if (error != null) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 14,
                            color: colors.muted,
                          ),
                        ),
                      );
                    }
                    if (_loadingCurrent && _zoom == CalendarZoomLevel.days) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          PcLayout.pinBottomToast(
            bottom: 20 + MediaQuery.paddingOf(context).bottom,
            child: AnimatedFriendsToast(
              text: _hint,
              visible: _hintVisible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(AppColors colors, {required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

class FriendProfileMatch {
  const FriendProfileMatch(this.label);
  final String label;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: font,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: font,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.pop(context, false),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.groupedBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      AppStrings.friendsCancel,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.pop(context, true),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.danger,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      action,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar({required this.onBack});

  final VoidCallback onBack;

  static const _toolbarHeight = 48.0;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const FrostedAppBarFill(),
        AppBar(
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
        ),
      ],
    );
  }
}
