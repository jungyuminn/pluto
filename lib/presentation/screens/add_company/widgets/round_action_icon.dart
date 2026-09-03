import 'package:flutter/material.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class RoundActionIcon extends StatelessWidget {
  const RoundActionIcon({
    super.key,
    required this.asset,
    required this.onPressed,
  });

  final String asset;
  final VoidCallback onPressed;

  static const _size = 26.0;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      onPressed: onPressed,
      pressedColor: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ThemedAsset(asset: asset, width: _size, height: _size),
      ),
    );
  }
}
