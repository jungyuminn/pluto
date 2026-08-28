import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

Future<String?> showDayEmojiSheet(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    useRootNavigator: true,
    builder: (context) => SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: DayEmojiSheet(selected: selected),
    ),
  );
}

class StickerPack {
  const StickerPack({required this.id, required this.assets});

  final String id;
  final List<String> assets;

  String get cover => assets.first;
}

class DayStickers {
  DayStickers._();

  static const prefix = 'assets/stickers/';

  static bool isAsset(String? value) {
    final path = value?.trim() ?? '';
    return path.startsWith(prefix) &&
        !path.startsWith('${prefix}university_cat/');
  }

  static Future<List<String>> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return [
      for (final key in manifest.listAssets())
        if (key.startsWith(prefix) &&
            (key.endsWith('.png') ||
                key.endsWith('.webp') ||
                key.endsWith('.jpg') ||
                key.endsWith('.jpeg')))
          key,
    ]..sort();
  }

  static Future<List<StickerPack>> loadPacks() async {
    final grouped = <String, List<String>>{};
    for (final path in await load()) {
      final rest = path.substring(prefix.length);
      final slash = rest.indexOf('/');
      final id = slash < 0 ? 'default' : rest.substring(0, slash);
      (grouped[id] ??= []).add(path);
    }
    return [
      for (final id in grouped.keys)
        if (grouped[id]!.isNotEmpty) StickerPack(id: id, assets: grouped[id]!),
    ];
  }
}

class DayEmojiSheet extends StatefulWidget {
  const DayEmojiSheet({super.key, this.selected});

  final String? selected;

  @override
  State<DayEmojiSheet> createState() => _DayEmojiSheetState();
}

class _DayEmojiSheetState extends State<DayEmojiSheet> {
  var _packs = <StickerPack>[];
  var _packIndex = 0;
  var _loading = true;

  static const _columns = 5;
  static const _tabSize = 56.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final packs = await DayStickers.loadPacks();
    if (!mounted) return;
    final current = widget.selected?.trim();
    var packIndex = 0;
    if (DayStickers.isAsset(current)) {
      final found = packs.indexWhere((pack) => pack.assets.contains(current));
      if (found >= 0) packIndex = found;
    }
    setState(() {
      _packs = packs;
      _packIndex = packIndex;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final current = widget.selected?.trim();
    final hasCurrent = DayStickers.isAsset(current);
    final height =
        (MediaQuery.sizeOf(context).height * 0.5).clamp(380.0, 540.0);
    final pack = _packs.isEmpty ? null : _packs[_packIndex.clamp(0, _packs.length - 1)];
    final stickers = pack?.assets ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: height,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.muted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const SizedBox(width: 36, height: 4),
                  ),
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: _tabSize,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _packs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final selected = index == _packIndex;
                        return PressBounce(
                          onPressed: () => setState(() => _packIndex = index),
                          color: selected
                              ? colors.accentBright
                              : colors.groupedBackground,
                          pressedColor: selected
                              ? Color.lerp(colors.accentBright, Colors.black, 0.08)!
                              : colors.pressed,
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: _tabSize,
                            height: _tabSize,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                _packs[index].cover,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: stickers.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final sticker = stickers[index];
                        final selected = sticker == current;
                        return PressBounce(
                          onPressed: () => Navigator.of(context).pop(sticker),
                          color: selected
                              ? colors.tint(colors.accent, 0.16)
                              : Colors.transparent,
                          pressedColor: colors.pressed,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              sticker,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressBounce(
                    onPressed: hasCurrent
                        ? () => Navigator.of(context).pop('')
                        : null,
                    color: colors.tint(colors.accent, 0.18),
                    pressedColor: colors.tint(colors.accent, 0.28),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Text(
                        AppStrings.emojiClear,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: hasCurrent
                              ? colors.accent
                              : colors.accent.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
