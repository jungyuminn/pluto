import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/friend_home_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';
import 'package:pluto/presentation/screens/friends/friend_calendar_screen.dart';
import 'package:pluto/presentation/screens/friends/friends_screen.dart';
import 'package:pluto/presentation/screens/settings/widgets/login_page.dart';

const _avatarSize = 60.0;
const _cellWidth = 76.0;
const _rowHeight = 92.0;

class HomeFriendsRow extends StatefulWidget {
  const HomeFriendsRow({super.key});

  @override
  State<HomeFriendsRow> createState() => _HomeFriendsRowState();
}

class _HomeFriendsRowState extends State<HomeFriendsRow> {
  @override
  void initState() {
    super.initState();
    unawaited(FriendService.instance.bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AppAuthService.instance.authState,
      initialData: AppAuthService.instance.user,
      builder: (context, auth) {
        if (auth.data == null) return const SizedBox.shrink();
        FriendService.instance.hydrateSession();
        unawaited(FriendService.instance.bootstrap());
        return ValueListenableBuilder<FriendProfile?>(
          valueListenable: FriendService.instance.profile,
          builder: (context, me, _) {
            return StreamBuilder<List<FriendProfile>>(
              stream: FriendService.instance.friends(),
              builder: (context, snapshot) {
                final friends = snapshot.data ?? const <FriendProfile>[];
                return ListenableBuilder(
                  listenable: FriendHomePreference.instance.listenable,
                  builder: (context, _) {
                    return StreamBuilder<int>(
                      stream: FriendService.instance.incomingCount(),
                      builder: (context, requestSnap) {
                        return _row(
                          context,
                          me: me,
                          friends: FriendHomePreference.instance.onHome(friends),
                          requests: requestSnap.data ?? 0,
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
    required int requests,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MeCell(
              profile: me,
              requests: requests,
              onPressed: () => _openFriends(context),
              onAdd: () => _openAdd(context),
            ),
            Expanded(
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                clipBehavior: Clip.none,
                padding: EdgeInsets.zero,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final t = Curves.easeOutBack.transform(animation.value);
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
                    FriendService.instance.reorderHomeFriends(
                      friends,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                  );
                },
                children: [
                  for (var i = 0; i < friends.length; i++)
                    ReorderableDelayedDragStartListener(
                      key: ValueKey(friends[i].uid),
                      index: i,
                      child: _FriendCell(
                        friend: friends[i],
                        onPressed: () => _openCalendar(context, friends[i]),
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

  Future<void> _openFriends(BuildContext context) async {
    if (AppAuthService.instance.user == null) {
      await openLoginPage(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
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
}

class _MeCell extends StatelessWidget {
  const _MeCell({
    required this.profile,
    required this.requests,
    required this.onPressed,
    required this.onAdd,
  });

  final FriendProfile? profile;
  final int requests;
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
                  FriendAvatar(size: _avatarSize, profile: profile),
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
                fontWeight: FontWeight.w700,
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
                    border: Border.all(color: colors.background, width: 2.5),
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
                  Positioned(
                    right: 0,
                    top: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.background, width: 2),
                      ),
                      child: const SizedBox(width: 10, height: 10),
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

class _FriendCell extends StatelessWidget {
  const _FriendCell({required this.friend, required this.onPressed});

  final FriendProfile friend;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = friend.label;
    return _Cell(
      onPressed: onPressed,
      label: label,
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
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
