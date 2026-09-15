import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/theme/app_colors.dart';
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
  });

  final double size;
  final FriendProfile? profile;
  final Uint8List? preview;

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
      builder: (context, _, __) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final bytes = preview ?? FriendService.instance.avatarBytes(profile?.uid);
    final url = profile?.photoURL ?? '';
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
