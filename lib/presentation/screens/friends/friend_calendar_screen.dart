import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/day_emoji_store.dart';
import 'package:pluto/data/datasources/friend_favorite_preference.dart';
import 'package:pluto/data/datasources/friend_home_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_month_grid.dart';
import 'package:pluto/presentation/screens/calendar/widgets/calendar_weekday_header.dart';
import 'package:pluto/presentation/widgets/app_calendar/calendar_zoom_picker.dart';
import 'package:pluto/presentation/widgets/app_calendar/web_calendar_arrow.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_events_dialog.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';
import 'package:pluto/presentation/screens/friends/friend_photo_peek.dart';
import 'package:pluto/presentation/screens/friends/friend_star_button.dart';
import 'package:pluto/presentation/screens/friends/friends_toast.dart';
import 'package:pluto/presentation/widgets/overflow_menu.dart';

Future<bool> confirmRemoveFriend(
  BuildContext context,
  FriendProfile friend,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => _RemoveFriendDialog(friend: friend),
  );
  return ok == true;
}

class _RemoveFriendDialog extends StatelessWidget {
  const _RemoveFriendDialog({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final code = friend.friendCode.trim();
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FriendAvatar(
            size: 68,
            profile: friend,
            showFavorite: false,
          ),
          const SizedBox(height: 12),
          Text(
            friend.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: font,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              code,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: font,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            AppStrings.friendsRemoveTitle,
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
            AppStrings.friendsRemoveBody,
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
                  color: colors.border,
                  pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontFamily: font,
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
                  onPressed: () => Navigator.pop(context, true),
                  color: colors.danger,
                  pressedColor: Color.lerp(colors.danger, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.friendsRemove,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
  var _hint = '';
  var _hintVisible = false;
  var _zoom = CalendarZoomLevel.days;
  Timer? _hintTimer;

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
    _hintTimer?.cancel();
    _pages.dispose();
    super.dispose();
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

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

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

  void _pickYear(int year) {
    setState(() {
      _month = DateTime(year, _month.month);
      _zoom = CalendarZoomLevel.months;
    });
  }

  Future<void> _pickMonth(DateTime month) async {
    await _showDays(month);
  }

  Future<void> _showDays([DateTime? month]) async {
    final target = DateTime(
      (month ?? _month).year,
      (month ?? _month).month,
    );
    setState(() {
      _zoom = CalendarZoomLevel.days;
      _month = target;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _goToMonth(target);
    _load(target);
    _load(DateTime(target.year, target.month - 1));
    _load(DateTime(target.year, target.month + 1));
  }

  void _stepCalendar(int direction) {
    final next = switch (_zoom) {
      CalendarZoomLevel.days => DateTime(_month.year, _month.month + direction),
      CalendarZoomLevel.months => DateTime(_month.year + direction, _month.month),
      CalendarZoomLevel.years => DateTime(_month.year + 10 * direction, _month.month),
    };
    if (_zoom == CalendarZoomLevel.days) {
      unawaited(_goToMonth(next));
      return;
    }
    setState(() => _month = next);
  }

  Future<void> _goToMonth(DateTime month) async {
    final target = DateTime(month.year, month.month);
    if (!_pages.hasClients) {
      if (mounted) setState(() => _month = target);
      return;
    }
    final page = _pageOf(target);
    final current = _pages.page?.round() ?? _initialPage;
    if (current == page) {
      if (!_sameMonth(_month, target)) {
        setState(() => _month = target);
      }
      return;
    }
    final distance = (page - current).abs();
    if (distance > 18) {
      _pages.jumpToPage(page);
      if (mounted) setState(() => _month = target);
      return;
    }
    final ms = (200 + distance * 45).clamp(240, 560);
    await _pages.animateToPage(
      page,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    if (!_sameMonth(_month, target)) {
      setState(() => _month = target);
    }
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
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: _FriendsAppBar(
        title: '',
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
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
                  child: Stack(
                    children: [
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CalendarZoomTitle(
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
                                      onPageChanged: _onPageChanged,
                                      itemBuilder: (context, page) {
                                        final month = _monthAt(page);
                                        return CalendarMonthGrid(
                                          month: month,
                                          startMonday: startMonday,
                                          eventsOf: (date) =>
                                              _eventsOn(month, date),
                                          emojisOf: (date) =>
                                              _emojiOn(month, date),
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
                            CalendarZoomLevel.months => CalendarMonthZoomView(
                              focused: _month,
                              accent: colors.accentBright,
                              onFocusedChanged: (month) {
                                setState(() => _month = month);
                              },
                              onMonthPressed: _pickMonth,
                            ),
                            CalendarZoomLevel.years => CalendarYearZoomView(
                              focused: _month,
                              accent: colors.accentBright,
                              onFocusedChanged: (month) {
                                setState(() => _month = month);
                              },
                              onYearPressed: _pickYear,
                            ),
                          },
                        ),
                      ),
                    ],
                      ),
                      if (PcLayout.isPc) ...[
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: WebCalendarArrow(
                              left: true,
                              visible: PcLayout.showCalendarArrowsOf(
                                MediaQuery.sizeOf(context).width,
                              ),
                              onPressed: () => _stepCalendar(-1),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: WebCalendarArrow(
                              left: false,
                              visible: PcLayout.showCalendarArrowsOf(
                                MediaQuery.sizeOf(context).width,
                              ),
                              onPressed: () => _stepCalendar(1),
                            ),
                          ),
                        ),
                      ],
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
              else if (_loading && _zoom == CalendarZoomLevel.days)
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

  Future<void> _addSharedTodo() async {
    final sent = await showAddEventSheet(
      context,
      date: DateTime.now(),
      shareWith: widget.friend,
    );
    if (!mounted || !sent) return;
    _toast(AppStrings.friendsSharedTodoSent(widget.friend.label));
  }

  Future<void> _removeFriend() async {
    final ok = await confirmRemoveFriend(context, widget.friend);
    if (!ok || !mounted) return;
    try {
      await FriendService.instance.remove(widget.friend.uid);
      if (!mounted) return;
      showFriendsToast(
        context,
        AppStrings.friendsUnfriended(widget.friend.label),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await showMissingFieldsDialog(
        context,
        title: AppStrings.friendsRemove,
        body: FriendService.instance.messageOf(error),
      );
    }
  }

  Widget _profileHeader(AppColors colors) {
    final friend = widget.friend;
    final name = friend.label;
    final id = friend.friendCode.trim();
    final showId = id.isNotEmpty && id != name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          FriendPhotoPeekTarget(size: 48, profile: friend),
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
          ListenableBuilder(
            listenable: Listenable.merge([
              FriendHomePreference.instance.listenable,
              FriendFavoritePreference.instance.listenable,
            ]),
            builder: (context, _) {
              final pinned =
                  FriendHomePreference.instance.contains(friend.uid);
              final favorited =
                  FriendFavoritePreference.instance.contains(friend.uid);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FriendStarButton(
                    favorited: favorited,
                    onPressed: () {
                      final next = !favorited;
                      FriendFavoritePreference.instance.setFavorite(
                        friend.uid,
                        next,
                      );
                      _toast(
                        next
                            ? AppStrings.friendsFavoriteAdded
                            : AppStrings.friendsFavoriteRemoved,
                      );
                    },
                  ),
                  OverflowMenuButton(
                    actions: [
                      OverflowMenuAction(
                        label: pinned
                            ? AppStrings.friendsHomeUnpin
                            : AppStrings.friendsHomePin,
                        leadingAsset:
                            pinned ? AppIcons.removeHome : AppIcons.addHome,
                        leadingFlipX: true,
                        onPressed: () {
                          final next = !pinned;
                          FriendHomePreference.instance.setPinned(
                            friend.uid,
                            next,
                          );
                          _toast(
                            next
                                ? AppStrings.friendsHomePinned(friend.label)
                                : AppStrings.friendsHomeUnpinned(friend.label),
                          );
                        },
                      ),
                      OverflowMenuAction(
                        label: AppStrings.friendsSharedTodoAdd,
                        leadingAsset: AppIcons.linkOutlined,
                        onPressed: _addSharedTodo,
                      ),
                      OverflowMenuAction(
                        label: AppStrings.friendsRemove,
                        leadingAsset: AppIcons.trashCan,
                        color: colors.danger,
                        onPressed: _removeFriend,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
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
