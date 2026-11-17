import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/friend_favorite_preference.dart';
import 'package:pluto/data/datasources/friend_home_preference.dart';
import 'package:pluto/data/datasources/friend_order_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/group_calendar_service.dart';
import 'package:pluto/data/datasources/home_row_order_preference.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/domain/entities/group_calendar.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';
import 'package:pluto/presentation/screens/friends/friend_calendar_screen.dart';
import 'package:pluto/presentation/screens/friends/friends_screen.dart';
import 'package:pluto/presentation/screens/friends/group_calendar_screen.dart';
import 'package:pluto/presentation/screens/settings/widgets/login_page.dart';

const _avatarSize = 56.0;
const _cellWidth = 72.0;
const _rowHeight = 86.0;

class HomeFriendsRow extends StatefulWidget {
  const HomeFriendsRow({super.key});

  @override
  State<HomeFriendsRow> createState() => _HomeFriendsRowState();
}

class _HomeFriendsRowState extends State<HomeFriendsRow> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(FriendService.instance.bootstrap());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AppAuthService.instance.authState,
      initialData: AppAuthService.instance.user,
      builder: (context, auth) {
        if (auth.data == null) return const SizedBox.shrink();
        return ValueListenableBuilder<FriendProfile?>(
          valueListenable: FriendService.instance.profile,
          builder: (context, me, _) {
            return StreamBuilder<List<FriendProfile>>(
              stream: FriendService.instance.friends(),
              initialData: FriendService.instance.lastFriends,
              builder: (context, snapshot) {
                final friends = snapshot.data ?? const <FriendProfile>[];
                return ListenableBuilder(
                  listenable: Listenable.merge([
                    FriendHomePreference.instance.listenable,
                    FriendFavoritePreference.instance.listenable,
                    FriendOrderPreference.instance.listenable,
                    HomeRowOrderPreference.instance.listenable,
                  ]),
                  builder: (context, _) {
                    return StreamBuilder<int>(
                      stream: FriendService.instance.incomingRequestCount(),
                      initialData:
                          FriendService.instance.lastIncoming.length,
                      builder: (context, requestSnap) {
                        return StreamBuilder<int>(
                          stream: FriendService.instance.incomingTodoCount(),
                          initialData:
                              FriendService.instance.lastIncomingTodos.length,
                          builder: (context, todoSnap) {
                            return StreamBuilder<List<GroupCalendar>>(
                              stream: GroupCalendarService.instance.calendars(),
                              initialData:
                                  GroupCalendarService.instance.lastCalendars,
                              builder: (context, calendarSnap) {
                                return StreamBuilder<List<GroupCalendarInvite>>(
                                  stream: GroupCalendarService.instance
                                      .incomingInvites(),
                                  initialData: GroupCalendarService
                                      .instance.lastInvites,
                                  builder: (context, inviteSnap) {
                                    return _row(
                                      context,
                                      me: me,
                                      friends: FriendFavoritePreference
                                          .instance
                                          .apply(
                                        FriendOrderPreference.instance.apply(
                                          FriendHomePreference.instance
                                              .onHome(friends),
                                        ),
                                      ),
                                      calendars: calendarSnap.data ??
                                          const <GroupCalendar>[],
                                      requests: requestSnap.data ?? 0,
                                      invites: inviteSnap.data?.length ?? 0,
                                      todos: todoSnap.data ?? 0,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _row(
    BuildContext context, {
    required FriendProfile? me,
    required List<FriendProfile> friends,
    required List<GroupCalendar> calendars,
    required int requests,
    required int invites,
    required int todos,
  }) {
    final favorites = [
      for (final friend in friends)
        if (FriendFavoritePreference.instance.contains(friend.uid)) friend,
    ];
    final regulars = [
      for (final friend in friends)
        if (!FriendFavoritePreference.instance.contains(friend.uid)) friend,
    ];
    final homeFriends = [...favorites, ...regulars];
    final friendsById = {
      for (final friend in homeFriends) friend.uid: friend,
    };
    final calendarsById = {
      for (final calendar in calendars) calendar.id: calendar,
    };
    final rowKeys = _rowKeys(
      favorites: favorites,
      homeFriends: homeFriends,
      calendars: calendars,
    );
    final meCell = _MeCell(
      profile: me,
      requests: requests + invites,
      todos: todos,
      onPressed: () => _openFriends(context),
      onAdd: () => _openAdd(context),
    );
    final empty = homeFriends.isEmpty && calendars.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRect(
        child: SizedBox(
          width: double.infinity,
          height: _rowHeight,
          child: empty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: meCell,
                  ),
                )
              : HorizontalWheelScroll(
                  controller: _scroll,
                  child: ScrollConfiguration(
                    behavior: const MouseDragScrollBehavior(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) => notification.depth == 0,
                      child: ReorderableListView(
                        scrollController: _scroll,
                        scrollDirection: Axis.horizontal,
                        physics: const _FriendsRowPhysics(),
                        dragStartBehavior: DragStartBehavior.down,
                        clipBehavior: Clip.hardEdge,
                        cacheExtent: _cellWidth * 8,
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        header: meCell,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final t = Curves.easeOutBack
                                  .transform(animation.value);
                              return Transform.scale(
                                scale: 1 + 0.06 * t,
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                        onReorderStart: (_) => HapticFeedback.mediumImpact(),
                        onReorder: (oldIndex, newIndex) {
                          unawaited(
                            _reorderRow(
                              rowKeys,
                              friends: homeFriends,
                              calendars: calendars,
                              oldIndex: oldIndex,
                              newIndex: newIndex,
                            ),
                          );
                        },
                        children: [
                          for (var i = 0; i < rowKeys.length; i++)
                            ReorderableDelayedDragStartListener(
                              key: ValueKey(rowKeys[i]),
                              index: i,
                              child: _cellFor(
                                context,
                                rowKeys[i],
                                friendsById: friendsById,
                                calendarsById: calendarsById,
                                me: me,
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
  }

  Widget _cellFor(
    BuildContext context,
    String key, {
    required Map<String, FriendProfile> friendsById,
    required Map<String, GroupCalendar> calendarsById,
    required FriendProfile? me,
  }) {
    const prefix = HomeRowOrderPreference.calendarPrefix;
    if (key.startsWith(prefix)) {
      final calendar = calendarsById[key.substring(prefix.length)];
      if (calendar == null) return const SizedBox.shrink();
      return _GroupCell(
        calendar: calendar,
        me: me,
        onPressed: () => _openGroup(context, calendar),
      );
    }
    final friend = friendsById[
        key.substring(HomeRowOrderPreference.friendPrefix.length)];
    if (friend == null) return const SizedBox.shrink();
    return _FriendCell(
      friend: friend,
      onPressed: () => _openCalendar(context, friend),
    );
  }

  List<String> _rowKeys({
    required List<FriendProfile> favorites,
    required List<FriendProfile> homeFriends,
    required List<GroupCalendar> calendars,
  }) {
    final mixed = HomeRowOrderPreference.instance.apply(
      calendarIds: [for (final calendar in calendars) calendar.id],
      friendUids: [for (final friend in homeFriends) friend.uid],
    );
    if (favorites.isEmpty) return mixed;
    const prefix = HomeRowOrderPreference.friendPrefix;
    final favIds = {for (final friend in favorites) friend.uid};
    return [
      for (final friend in favorites)
        HomeRowOrderPreference.friendKey(friend.uid),
      for (final key in mixed)
        if (!key.startsWith(prefix) ||
            !favIds.contains(key.substring(prefix.length)))
          key,
    ];
  }

  Future<void> _reorderRow(
    List<String> rowKeys, {
    required List<FriendProfile> friends,
    required List<GroupCalendar> calendars,
    required int oldIndex,
    required int newIndex,
  }) {
    final favCount = FriendFavoritePreference.instance.countIn(friends);
    final mixed = calendars.isNotEmpty ||
        HomeRowOrderPreference.instance.keys.isNotEmpty;
    if (!mixed) {
      return FriendService.instance.reorderHomeFriends(
        friends,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
    }
    if (oldIndex < favCount) {
      return FriendService.instance.reorderFavorites(
        [
          for (final friend in friends)
            if (FriendFavoritePreference.instance.contains(friend.uid)) friend,
        ],
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
    }
    final rest = [...rowKeys.skip(favCount)];
    var restOld = oldIndex - favCount;
    var restNew = newIndex - favCount;
    if (restOld < 0 || restOld >= rest.length) return Future.value();
    if (restNew > restOld) restNew -= 1;
    if (restNew < 0) restNew = 0;
    if (restNew > rest.length - 1) restNew = rest.length - 1;
    if (restNew == restOld) return Future.value();
    final moved = rest.removeAt(restOld);
    rest.insert(restNew, moved);
    return HomeRowOrderPreference.instance.setOrder([
      ...rowKeys.take(favCount),
      ...rest,
    ]);
  }

  Future<void> _openFriends(BuildContext context) async {
    if (AppAuthService.instance.user == null) {
      await openLoginPage(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: FriendsScreen.routeName),
        builder: (context) => const FriendsScreen(),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    if (AppAuthService.instance.user == null) {
      await openLoginPage(context);
      return;
    }
    await showAddFriendSheet(context);
  }

  Future<void> _openCalendar(BuildContext context, FriendProfile friend) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FriendCalendarScreen(friend: friend),
      ),
    );
  }

  Future<void> _openGroup(BuildContext context, GroupCalendar calendar) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupCalendarScreen(calendar: calendar),
      ),
    );
  }
}

class _MeCell extends StatelessWidget {
  const _MeCell({
    required this.profile,
    required this.requests,
    required this.todos,
    required this.onPressed,
    required this.onAdd,
  });

  final FriendProfile? profile;
  final int requests;
  final int todos;
  final VoidCallback onPressed;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final label = profile?.label.trim();
    final name = (label == null || label.isEmpty)
        ? AppStrings.friendsHomeMe
        : label;
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      child: SizedBox(
        width: _cellWidth,
        child: Column(
          children: [
            SizedBox(
              width: _avatarSize,
              height: _avatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  FriendAvatar(
                    size: _avatarSize,
                    profile: profile,
                    showFavorite: false,
                  ),
                  if (todos > 0)
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: IgnorePointer(child: _InboxDot()),
                    ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: _AddBadge(
                      requests: requests,
                      onPressed: onAdd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBadge extends StatelessWidget {
  const _AddBadge({required this.requests, required this.onPressed});

  final int requests;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      child: Tooltip(
        message: AppStrings.friendsHomeAdd,
        child: Semantics(
          button: true,
          label: AppStrings.friendsHomeAdd,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FriendAvatar.accentOf(context),
                    border: Border.all(color: colors.pageBackground, width: 2.5),
                  ),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (requests > 0)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: IgnorePointer(child: _InboxDot()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InboxDot extends StatelessWidget {
  const _InboxDot();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.danger,
        shape: BoxShape.circle,
        border: Border.all(color: colors.pageBackground, width: 2),
      ),
      child: const SizedBox(width: 12, height: 12),
    );
  }
}

class _GroupCell extends StatelessWidget {
  const _GroupCell({
    required this.calendar,
    required this.me,
    required this.onPressed,
  });

  final GroupCalendar calendar;
  final FriendProfile? me;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      onPressed: onPressed,
      label: calendar.name,
      child: _GroupAvatar(calendar: calendar, me: me),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.calendar, required this.me});

  final GroupCalendar calendar;
  final FriendProfile? me;

  List<FriendProfile> _faces() {
    final friends = FriendService.instance.lastFriends;
    final byUid = <String, FriendProfile>{
      for (final friend in friends) friend.uid: friend,
    };
    final mine = me;
    if (mine != null && mine.uid.isNotEmpty) {
      byUid[mine.uid] = mine;
    }
    final others = <FriendProfile>[];
    FriendProfile? self;
    for (final uid in calendar.memberUids) {
      final profile = byUid[uid];
      if (profile == null) continue;
      if (uid == mine?.uid) {
        self = profile;
      } else {
        others.add(profile);
      }
    }
    return [
      ...others,
      if (self != null) self,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final faces = _faces();
    if (faces.length <= 1) {
      return FriendAvatar(
        size: _avatarSize,
        profile: faces.isEmpty ? me : faces.first,
        showFavorite: false,
      );
    }
    final colors = AppColors.of(context);
    final shown = faces.take(2).toList();
    const face = 40.0;
    return SizedBox(
      width: _avatarSize,
      height: _avatarSize,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 2,
            child: FriendAvatar(
              size: face,
              profile: shown[0],
              showFavorite: false,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.pageBackground, width: 2),
              ),
              child: FriendAvatar(
                size: face,
                profile: shown[1],
                showFavorite: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCell extends StatelessWidget {
  const _FriendCell({
    required this.friend,
    required this.onPressed,
  });

  final FriendProfile friend;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      onPressed: onPressed,
      label: friend.label,
      child: FriendAvatar(size: _avatarSize, profile: friend),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.onPressed,
    required this.label,
    required this.child,
    this.width = _cellWidth,
  });

  final VoidCallback onPressed;
  final String label;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            child,
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsRowPhysics extends BouncingScrollPhysics {
  const _FriendsRowPhysics({super.parent});

  @override
  _FriendsRowPhysics applyTo(ScrollPhysics? ancestor) {
    return _FriendsRowPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    if (velocity.abs() < tolerance.velocity && !position.outOfRange) {
      return null;
    }
    return BouncingScrollSimulation(
      spring: spring,
      position: position.pixels,
      velocity: position.outOfRange ? velocity : velocity * 0.75,
      leadingExtent: position.minScrollExtent,
      trailingExtent: position.maxScrollExtent,
      tolerance: tolerance,
    );
  }
}
