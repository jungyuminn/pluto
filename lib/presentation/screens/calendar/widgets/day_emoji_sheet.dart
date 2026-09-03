import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/fade_in.dart';
import 'package:pluto/core/utils/press_bounce.dart';

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

  /// 고양이 → 토끼 → 강아지 → 심플캣, 그 안에서 데일리 → 유니버시티 → 컴패니.
  static const defaultPackOrder = [
    'university_cat',
    'company_cat',
    'daily_rabbit',
    'university_rabbit',
    'company_rabbit',
    'travel_hamster',
    'daily_dog',
    'simple_cat',
    'simple_cat2',
    'simple_cat3',
  ];

  static final _stickerFile = RegExp(
    r'^\d{2}_.+\.(png|webp|jpe?g)$',
    caseSensitive: false,
  );

  static bool isAsset(String? value) {
    final path = value?.trim() ?? '';
    if (!path.startsWith(prefix)) return false;
    return _stickerFile.hasMatch(path.split('/').last);
  }

  static Future<List<String>> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return [
      for (final key in manifest.listAssets())
        if (key.startsWith(prefix) &&
            _stickerFile.hasMatch(key.split('/').last))
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
    return orderedPacks([
      for (final id in grouped.keys)
        if (grouped[id]!.isNotEmpty) StickerPack(id: id, assets: grouped[id]!),
    ]);
  }

  static List<StickerPack> orderedPacks(
    List<StickerPack> packs, [
    List<String> saved = const [],
  ]) {
    if (packs.length <= 1) return packs;
    final byId = {for (final pack in packs) pack.id: pack};
    final seen = <String>{};
    final ordered = <StickerPack>[];
    void add(String id) {
      final pack = byId[id];
      if (pack == null || seen.contains(id)) return;
      ordered.add(pack);
      seen.add(id);
    }

    for (final id in saved) {
      add(id);
    }
    for (final id in defaultPackOrder) {
      add(id);
    }
    for (final pack in packs) {
      add(pack.id);
    }
    return ordered;
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
    final ordered = DayStickers.orderedPacks(
      packs,
      AppScope.of(context).dayEmojiStore.packOrder,
    );
    final current = widget.selected?.trim();
    var packIndex = 0;
    if (DayStickers.isAsset(current)) {
      final found =
          ordered.indexWhere((pack) => pack.assets.contains(current));
      if (found >= 0) packIndex = found;
    }
    setState(() {
      _packs = ordered;
      _packIndex = packIndex;
      _loading = false;
    });
  }

  Future<void> _reorderPacks(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final selectedId = _packs[_packIndex.clamp(0, _packs.length - 1)].id;
    setState(() {
      final item = _packs.removeAt(oldIndex);
      _packs.insert(newIndex, item);
      final next = _packs.indexWhere((pack) => pack.id == selectedId);
      _packIndex = next < 0 ? 0 : next;
    });
    await AppScope.of(context).dayEmojiStore.setPackOrder([
      for (final pack in _packs) pack.id,
    ]);
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
      child: Material(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final n = _packs.length;
                        final contentWidth =
                            n * _tabSize + (n > 1 ? (n - 1) * 10 : 0);
                        final pad = ((constraints.maxWidth - contentWidth) / 2)
                            .clamp(0.0, double.infinity);
                        return SizedBox(
                          width: constraints.maxWidth,
                          child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          primary: false,
                          buildDefaultDragHandles: false,
                          clipBehavior: Clip.hardEdge,
                          physics: pad > 0.5
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: pad),
                          itemCount: _packs.length,
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final t = Curves.easeOutBack.transform(
                                  animation.value,
                                );
                                return Transform.scale(
                                  scale: 1 + 0.06 * t,
                                  child: child,
                                );
                              },
                              child: child,
                            );
                          },
                          onReorderStart: (_) {
                            HapticFeedback.mediumImpact();
                          },
                          onReorderItem: _reorderPacks,
                          itemBuilder: (context, index) {
                            final selected = index == _packIndex;
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(_packs[index].id),
                              index: index,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == _packs.length - 1 ? 0 : 10,
                                ),
                                child: PressBounce(
                                  passthrough: true,
                                  color: selected
                                      ? Color.lerp(
                                          colors.groupedBackground,
                                          colors.accentBright,
                                          0.15,
                                        )!
                                      : colors.groupedBackground,
                                  pressedColor: selected
                                      ? Color.lerp(
                                          colors.groupedBackground,
                                          colors.accentBright,
                                          0.58,
                                        )!
                                      : colors.pressed,
                                  borderRadius: BorderRadius.circular(16),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        setState(() => _packIndex = index),
                                    child: SizedBox(
                                      width: _tabSize,
                                      height: _tabSize,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Image.asset(
                                          _packs[index].cover,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.medium,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FadeIn(
                      key: ValueKey(pack?.id ?? 'empty'),
                      duration: const Duration(milliseconds: 320),
                      offset: const Offset(0, 10),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: stickers.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columns,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final sticker = stickers[index];
                          return PressBounce(
                            onPressed: () =>
                                Navigator.of(context).pop(sticker),
                            color: Colors.transparent,
                            pressedColor: colors.pressed,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Image.asset(
                                sticker,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (context, error, stack) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          );
                        },
                      ),
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
