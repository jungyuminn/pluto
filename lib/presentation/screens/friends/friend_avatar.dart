import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/data/datasources/friend_favorite_preference.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.size,
    this.profile,
    this.preview,
    this.showFavorite = true,
  });

  final double size;
  final FriendProfile? profile;
  final Uint8List? preview;
  final bool showFavorite;

  static const classicAccent = Color(0xFF7CB7FE);

  static Color accentOf(BuildContext context) {
    final theme = AppScope.maybeOf(context)?.themePreference;
    final classic = (theme?.skin ?? AppSkin.classic) == AppSkin.classic &&
        !(theme?.usesCustom ?? false);
    return classic ? classicAccent : AppColors.of(context).accent;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: FriendService.instance.avatarTick,
      builder: (context, _, __) {
        final avatar = _body(context);
        final uid = profile?.uid.trim() ?? '';
        if (!showFavorite || uid.isEmpty) return avatar;
        return ListenableBuilder(
          listenable: FriendFavoritePreference.instance.listenable,
          builder: (context, _) {
            final favorited =
                FriendFavoritePreference.instance.contains(uid);
            final scale = size / 60;
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  avatar,
                  Positioned(
                    right: -3 * scale,
                    bottom: -3 * scale,
                    child: IgnorePointer(
                      child: AnimatedScale(
                        scale: favorited ? 1 : 0.72,
                        duration: Duration(
                          milliseconds: favorited ? 220 : 160,
                        ),
                        curve: favorited
                            ? Curves.easeOutCubic
                            : Curves.easeInCubic,
                        child: AnimatedOpacity(
                          opacity: favorited ? 1 : 0,
                          duration: Duration(
                            milliseconds: favorited ? 180 : 140,
                          ),
                          curve: favorited
                              ? Curves.easeOut
                              : Curves.easeIn,
                          child: _FavoriteBadge(scale: scale),
                        ),
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

  Widget _body(BuildContext context) {
    final url = profile?.hasAppPhoto == true ? profile!.photoURL : '';
    final bytes = preview ??
        (url.isEmpty ? null : FriendService.instance.avatarBytes(profile?.uid));
    final ImageProvider? image = bytes != null
        ? MemoryImage(bytes)
        : (url.isEmpty ? null : NetworkImage(url));
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.of(context).border, width: 1),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: image == null
            ? _logo(context)
            : ClipOval(
                child: Image(
                  image: image,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  gaplessPlayback: true,
                  loadingBuilder: (context, child, loading) {
                    if (loading == null) return child;
                    return _logo(context);
                  },
                  errorBuilder: (context, error, stack) => _logo(context),
                ),
              ),
      ),
    );
  }

  Widget _logo(BuildContext context) {
    final logoSize = size * 0.78;
    return Center(
      child: AppAssetImage(
        asset: AppIcons.plutoLogo,
        width: logoSize,
        height: logoSize,
        color: FriendAvatar.accentOf(context),
      ),
    );
  }
}

class _FavoriteBadge extends StatelessWidget {
  const _FavoriteBadge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 28 * scale,
      height: 28 * scale,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FriendAvatar.accentOf(context),
            border: Border.all(color: colors.background, width: 2.5 * scale),
          ),
          child: SizedBox(
            width: 22 * scale,
            height: 22 * scale,
            child: Center(
              child: AppAssetImage(
                asset: AppIcons.heartFilled,
                width: 10 * scale,
                height: 10 * scale,
                color: Colors.white,
                semanticLabel: AppStrings.friendsFavorite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
