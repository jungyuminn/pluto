import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_auth_service.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';
import 'package:pluto/presentation/screens/friends/friend_calendar_screen.dart';
import 'package:pluto/presentation/screens/friends/friends_screen.dart';
import 'package:pluto/presentation/screens/settings/widgets/login_page.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

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
        return ValueListenableBuilder<FriendProfile?>(
          valueListenable: FriendService.instance.profile,
          builder: (context, me, _) {
            return StreamBuilder<List<FriendProfile>>(
              stream: FriendService.instance.friends(),
              builder: (context, snapshot) {
                final friends = snapshot.data ?? const <FriendProfile>[];
                return StreamBuilder<int>(
                  stream: FriendService.instance.incomingCount(),
                  builder: (context, requestSnap) {
                    return _row(
                      context,
                      me: me,
                      friends: friends,
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
        height: 86,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          children: [
            _MeCell(
              profile: me,
              onPressed: () => _openFriends(context, add: false),
            ),
            _AddCell(
              requests: requests,
              onPressed: () => _openFriends(context, add: true),
            ),
            for (final friend in friends)
              _FriendCell(
                friend: friend,
                onPressed: () => _openCalendar(context, friend),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFriends(BuildContext context, {required bool add}) async {
    if (AppAuthService.instance.user == null) {
      await openLoginPage(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            add ? const FriendsScreen.add() : const FriendsScreen(),
      ),
    );
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
  const _MeCell({required this.profile, required this.onPressed});

  final FriendProfile? profile;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = profile?.label.trim();
    final name = (label == null || label.isEmpty)
        ? AppStrings.friendsHomeMe
        : label;
    return _Cell(
      onPressed: onPressed,
      label: name,
      child: FriendAvatar(
        size: 54,
        profile: profile,
      ),
    );
  }
}

class _AddCell extends StatelessWidget {
  const _AddCell({required this.requests, required this.onPressed});

  final int requests;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _Cell(
      onPressed: onPressed,
      label: AppStrings.friendsHomeAdd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.tint(colors.accent, 0.14),
            ),
            child: SizedBox(
              width: 54,
              height: 54,
              child: Center(
                child: AppAssetImage(
                  asset: AppIcons.addFriend,
                  width: 22,
                  height: 22,
                  color: colors.accent,
                ),
              ),
            ),
          ),
          if (requests > 0)
            Positioned(
              right: -1,
              top: -1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 2),
                ),
                child: const SizedBox(width: 12, height: 12),
              ),
            ),
        ],
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
      child: FriendAvatar(size: 54, profile: friend),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.onPressed,
    required this.label,
    required this.child,
  });

  final VoidCallback onPressed;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      child: SizedBox(
        width: 72,
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
