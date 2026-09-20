import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/presentation/widgets/app_bar_icon_group.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class FriendStarButton extends StatelessWidget {
  const FriendStarButton({
    super.key,
    required this.favorited,
    required this.onPressed,
  });

  final bool favorited;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppBarIconSlot(
      onPressed: onPressed,
      child: SizedBox(
        width: 19,
        height: 19,
        child: Center(
          child: AppAssetImage(
            asset: favorited ? AppIcons.heartFilled : AppIcons.heart,
            width: 17,
            height: 17,
            color: colors.muted,
            semanticLabel: AppStrings.friendsFavorite,
          ),
        ),
      ),
    );
  }
}
