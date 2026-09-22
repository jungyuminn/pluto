import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/screens/friends/friend_avatar.dart';

Future<void> showFriendPhotoPeek(
  BuildContext context,
  FriendProfile? profile,
) async {
  if (profile == null || !profile.hasAppPhoto) return;
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return;
  final start = box.size.shortestSide;
  if (start < 8) return;
  final bytes = FriendService.instance.avatarBytes(profile.uid);
  final url = profile.photoURL.trim();
  if ((bytes == null || bytes.isEmpty) && url.isEmpty) return;
  HapticFeedback.lightImpact();
  await Navigator.of(context, rootNavigator: true).push(
    _FriendPhotoPeekRoute(
      start: start,
      bytes: bytes,
      url: url,
    ),
  );
}

class FriendPhotoPeekTarget extends StatelessWidget {
  const FriendPhotoPeekTarget({
    super.key,
    required this.size,
    required this.profile,
    this.showFavorite = true,
  });

  final double size;
  final FriendProfile? profile;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final avatar = FriendAvatar(
      size: size,
      profile: profile,
      showFavorite: showFavorite,
    );
    if (profile?.hasAppPhoto != true) return avatar;
    return PressBounce(
      onPressed: () => unawaited(showFriendPhotoPeek(context, profile)),
      pressedColor: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: avatar,
    );
  }
}

class _FriendPhotoPeekRoute extends PopupRoute<void> {
  _FriendPhotoPeekRoute({
    required this.start,
    required this.bytes,
    required this.url,
  });

  final double start;
  final Uint8List? bytes;
  final String url;

  @override
  Color? get barrierColor => const Color(0x66000000);

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => '닫기';

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _FriendPhotoPeekPage(
      start: start,
      bytes: bytes,
      url: url,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class _FriendPhotoPeekPage extends StatelessWidget {
  const _FriendPhotoPeekPage({
    required this.start,
    required this.bytes,
    required this.url,
  });

  final double start;
  final Uint8List? bytes;
  final String url;

  ImageProvider get _image {
    final cached = bytes;
    if (cached != null && cached.isNotEmpty) return MemoryImage(cached);
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return const SizedBox.shrink();
    final screen = MediaQuery.sizeOf(context);
    final destSize = PcLayout.isPc
        ? (screen.shortestSide * 0.42).clamp(320.0, 460.0)
        : (screen.shortestSide * 0.62).clamp(200.0, 300.0);
    final photo = SizedBox(
      width: destSize,
      height: destSize,
      child: ClipOval(
        child: FittedBox(
          fit: BoxFit.cover,
          child: Image(
            image: _image,
            fit: BoxFit.cover,
            width: start,
            height: start,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOut.transform(animation.value);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Opacity(
            opacity: t,
            child: Center(
              child: Transform.scale(
                scale: 0.96 + 0.04 * t,
                filterQuality: FilterQuality.low,
                child: child,
              ),
            ),
          ),
        );
      },
      child: photo,
    );
  }
}
