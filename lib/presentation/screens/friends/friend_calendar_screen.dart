import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_weekday_header.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_events_dialog.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';

class FriendCalendarScreen extends StatefulWidget {
  const FriendCalendarScreen({super.key, required this.friend});

  final FriendProfile friend;

  @override
  State<FriendCalendarScreen> createState() => _FriendCalendarScreenState();
}

class _FriendCalendarScreenState extends State<FriendCalendarScreen> {
  static const _initialPage = 12000;

  late DateTime _baseMonth;
  late DateTime _month;
  late PageController _pages;
  final _eventsByMonth = <String, List<CalendarEvent>>{};
  final _stickersByMonth = <String, Map<String, String>>{};
  final _failedMonths = <String>{};
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _month = _baseMonth;
    _pages = PageController(initialPage: _initialPage);
    _load(_month);
    _load(_monthAt(_initialPage - 1));
    _load(_monthAt(_initialPage + 1));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String _monthKey(DateTime month) => '${month.year}-${month.month}';

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime _monthAt(int page) {
    return DateTime(_baseMonth.year, _baseMonth.month + (page - _initialPage));
  }

  Future<void> _load(DateTime month) async {
    final key = _monthKey(month);
    if (_eventsByMonth.containsKey(key) || _failedMonths.contains(key)) {
      return;
    }
    if (_sameMonth(month, _month) && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final events = FriendService.instance.eventsInMonth(
        friendUid: widget.friend.uid,
        month: month,
      );
      final stickers = FriendService.instance.stickersInMonth(
        friendUid: widget.friend.uid,
        month: month,
      );
      final loadedEvents = await events;
      var loadedStickers = const <String, String>{};
      try {
        loadedStickers = await stickers;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _eventsByMonth[key] = loadedEvents;
        _stickersByMonth[key] = loadedStickers;
        if (_sameMonth(month, _month)) {
          _loading = false;
          _error = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failedMonths.add(key);
        if (_sameMonth(month, _month)) {
          _loading = false;
          _error = AppStrings.friendsCalendarDenied;
        }
      });
    }
  }

  void _onPageChanged(int page) {
    final month = _monthAt(page);
    final key = _monthKey(month);
    setState(() {
      _month = month;
      _error = _failedMonths.contains(key)
          ? AppStrings.friendsCalendarDenied
          : null;
      _loading = !_eventsByMonth.containsKey(key) &&
          !_failedMonths.contains(key);
    });
    _load(month);
    _load(_monthAt(page - 1));
    _load(_monthAt(page + 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final startMonday =
        AppScope.of(context).calendarPreference.startMonday;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _FriendsAppBar(
        title: '',
        onBack: () => Navigator.pop(context),
      ),
      body: PcLayout.constrainWidth(
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 56, 16, 12),
          child: Column(
            children: [
              _card(
                colors,
                child: _profileHeader(colors),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _card(
                  colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                        child: Text(
                          _monthTitle,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
                        ),
                      ),
                      CalendarWeekdayHeader(startMonday: startMonday),
                      Expanded(
                        child: MouseDragScroll(
                          controller: _pages,
                          child: PageView.builder(
                            controller: _pages,
                            onPageChanged: _onPageChanged,
                            itemBuilder: (context, page) {
                              final month = _monthAt(page);
                              return CalendarMonthGrid(
                                month: month,
                                startMonday: startMonday,
                                eventsOf: (date) => _eventsOn(month, date),
                                emojisOf: (date) => _emojiOn(month, date),
                                onDayPressed: (date, origin) {
                                  showDayEventsDialog(
                                    context,
                                    date: date,
                                    events: _eventsOn(month, date),
                                    origin: origin,
                                    readOnly: true,
                                    sticker: _emojiOn(month, date),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 14,
                      color: colors.muted,
                    ),
                  ),
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
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

  Widget _profileHeader(AppColors colors) {
    final friend = widget.friend;
    final name = friend.label;
    final id = friend.friendCode.trim();
    final showId = id.isNotEmpty && id != name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          FriendAvatar(size: 48, profile: friend),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                if (showId)
                  Text(
                    id,
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
        ],
      ),
    );
  }

  String get _monthTitle {
    final now = DateTime.now();
    final monthLabel = '${_month.month}${AppStrings.monthSuffix}';
    if (_month.year == now.year) return monthLabel;
    return '${_month.year}${AppStrings.yearSuffix} $monthLabel';
  }

  String? _emojiOn(DateTime month, DateTime date) {
    return _stickersByMonth[_monthKey(month)]?[DayEmojiStore.stampOf(date)];
  }

  List<CalendarEvent> _eventsOn(DateTime month, DateTime date) {
    final events = _eventsByMonth[_monthKey(month)] ?? const [];
    return [
      for (final event in events)
        if (event.day.year == date.year &&
            event.day.month == date.month &&
            event.day.day == date.day)
          event,
    ];
  }
}

class _FriendsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _FriendsAppBar({required this.title, required this.onBack});

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
