import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/drop_in.dart';
import 'package:pluto/core/utils/fade_in.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';
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
    barrierColor: AppColors.barrier,
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

  /// 그림체가 같은 팩을 붙인다. 그 안에서 일상 → 대학 → 회사 → 리액션.
  static const defaultPackOrder = [
    'university_cat',
    'company_cat',
    'daily_rabbit',
    'university_rabbit',
    'company_rabbit',
    'cute_rabbit',
    'pink_rabbit_01',
    'pink_rabbit_02',
    'brown_puppy_01',
    'brown_puppy_02',
    'pink_dog',
    'fat_hamster',
    'white_hamster',
    'cute_hamster',
    'travel_hamster',
    'cute_bear',
    'beige_bear',
    'short_hair_girl',
    'yellow_circle',
    'cream_cat_01',
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

  /// 예전에 저장된 `.png` 경로를 지금 번들 파일로 맞춘다.
  static String resolve(String path) {
    final trimmed = path.trim();
    if (!trimmed.startsWith(prefix)) return trimmed;
    if (trimmed.toLowerCase().endsWith('.png')) {
      return '${trimmed.substring(0, trimmed.length - 4)}.webp';
    }
    return trimmed;
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
  static const _columns = 5;
  static const _tabWidth = 56.0;
  static const _tabHeight = 50.0;
  static const _pcTabWidth = 76.0;
  static const _pcTabHeight = 66.0;
  static const _tabGap = 10.0;
  static const _gridGap = 8.0;
  static const _slotAnim = Duration(milliseconds: 180);

  var _packs = <StickerPack>[];
  var _packIndex = 0;
  var _loading = true;
  final _packScroll = ScrollController();
  final _packRowKey = GlobalKey();
  final _packViewportKey = GlobalKey();
  int? _draggingIndex;
  Offset? _packDragGlobal;
  Timer? _packAutoScroll;
  var _packScrollDir = 0.0;
  var _dragTabWidth = _tabWidth;
  final _drop = DropSettle();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _packAutoScroll?.cancel();
    _packScroll.dispose();
    super.dispose();
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
      final resolved = DayStickers.resolve(current!);
      final found =
          ordered.indexWhere((pack) => pack.assets.contains(resolved));
      if (found >= 0) packIndex = found;
    }
    setState(() {
      _packs = ordered;
      _packIndex = packIndex;
      _loading = false;
    });
  }

  void _onPackDragStarted(int index, double tabWidth) {
    _dragTabWidth = tabWidth;
    setState(() => _draggingIndex = index);
  }

  void _onPackDragUpdate(Offset global, double tabWidth) {
    _packDragGlobal = global;
    _movePackAt(global, tabWidth);
    _syncPackAutoScroll(global);
  }

  void _onPackDragEnded(DraggableDetails details) {
    _stopPackAutoScroll();
    _packDragGlobal = null;
    final index = _draggingIndex;
    final id = index == null ? null : _packs[index].id;
    final origin = id == null ? null : _packSlotOrigin(id);
    final delta = origin == null ? Offset.zero : details.offset - origin;
    setState(() {
      _drop.arm(id, delta);
      _draggingIndex = null;
    });
    unawaited(_savePackOrder());
  }

  Offset? _packSlotOrigin(String id) {
    final index = _packs.indexWhere((pack) => pack.id == id);
    final box = _packRowKey.currentContext?.findRenderObject() as RenderBox?;
    if (index < 0 || box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset(index * (_dragTabWidth + _tabGap), 0));
  }

  Future<void> _savePackOrder() async {
    await AppScope.of(context).dayEmojiStore.setPackOrder([
      for (final pack in _packs) pack.id,
    ]);
  }

  void _movePackAt(Offset global, double tabWidth) {
    final from = _draggingIndex;
    if (from == null) return;
    final box = _packRowKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    final n = _packs.length;
    if (n <= 1) return;
    final stride = tabWidth + _tabGap;
    var to = (local.dx / stride).floor().clamp(0, n - 1);
    final left = from * stride - tabWidth * 0.18;
    if (local.dx >= left && local.dx < left + tabWidth * 1.36) {
      to = from;
    }
    _movePackTo(to);
  }

  void _movePackTo(int to) {
    final from = _draggingIndex;
    if (from == null || from == to) return;
    if (to < 0 || to >= _packs.length) return;
    final selectedId = _packs[_packIndex.clamp(0, _packs.length - 1)].id;
    setState(() {
      final item = _packs.removeAt(from);
      _packs.insert(to, item);
      _draggingIndex = to;
      final next = _packs.indexWhere((pack) => pack.id == selectedId);
      _packIndex = next < 0 ? 0 : next;
    });
    HapticFeedback.selectionClick();
  }

  void _stopPackAutoScroll() {
    _packAutoScroll?.cancel();
    _packAutoScroll = null;
    _packScrollDir = 0;
  }

  void _syncPackAutoScroll(Offset global) {
    if (!_packScroll.hasClients) {
      _stopPackAutoScroll();
      return;
    }
    final box =
        _packViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      _stopPackAutoScroll();
      return;
    }
    final x = box.globalToLocal(global).dx;
    const edge = 36.0;
    var dir = 0.0;
    if (x < edge) {
      dir = -1;
    } else if (x > box.size.width - edge) {
      dir = 1;
    }
    if (dir == 0) {
      _stopPackAutoScroll();
      return;
    }
    if (_packAutoScroll != null && _packScrollDir == dir) return;
    _packScrollDir = dir;
    _packAutoScroll?.cancel();
    _packAutoScroll = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_packScroll.hasClients) {
        _stopPackAutoScroll();
        return;
      }
      final pos = _packScroll.position;
      final next = (pos.pixels + _packScrollDir * 9).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );
      if (next == pos.pixels) return;
      _packScroll.jumpTo(next);
      final pointer = _packDragGlobal;
      if (pointer != null) _movePackAt(pointer, _dragTabWidth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final current = widget.selected?.trim();
    final hasCurrent = DayStickers.isAsset(current);
    final pc = PcLayout.isPc;
    final tabWidth = pc ? _pcTabWidth : _tabWidth;
    final tabHeight = pc ? _pcTabHeight : _tabHeight;
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
                    key: _packViewportKey,
                    height: tabHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final n = _packs.length;
                        final contentWidth =
                            n * tabWidth + (n > 1 ? (n - 1) * _tabGap : 0);
                        final pad = ((constraints.maxWidth - contentWidth) / 2)
                            .clamp(0.0, double.infinity);
                        return SizedBox(
                          width: constraints.maxWidth,
                          child: ScrollConfiguration(
                            behavior: const MouseDragScrollBehavior(),
                            child: HorizontalWheelScroll(
                              controller: _packScroll,
                              child: MouseListDragScroll(
                                controller: _packScroll,
                                enabled:
                                    pad <= 0.5 && _draggingIndex == null,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _packScroll,
                                  primary: false,
                                  clipBehavior:
                                      _draggingIndex == null && _drop.id == null
                                      ? Clip.hardEdge
                                      : Clip.none,
                                  physics: pad > 0.5
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: pad),
                                  child: SizedBox(
                                    width: contentWidth,
                                    height: tabHeight,
                                    child: Stack(
                                      key: _packRowKey,
                                      clipBehavior: Clip.none,
                                      children: [
                                        for (var i = 0; i < n; i++)
                                          _positionedPack(
                                            index: i,
                                            tabWidth: tabWidth,
                                            tabHeight: tabHeight,
                                            colors: colors,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _stickerGrid(
                      colors: colors,
                      packId: pack?.id,
                      stickers: stickers,
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

  Widget _positionedPack({
    required int index,
    required double tabWidth,
    required double tabHeight,
    required AppColors colors,
  }) {
    final packId = _packs[index].id;
    return AnimatedPositioned(
      key: ValueKey(packId),
      duration: _draggingIndex == null && _drop.id == null
          ? Duration.zero
          : _slotAnim,
      curve: Curves.easeOutCubic,
      left: index * (tabWidth + _tabGap),
      width: tabWidth,
      height: tabHeight,
      child: _drop.wrap(
        itemId: packId,
        onDone: () {
          if (!mounted || _drop.id != packId) return;
          setState(_drop.clear);
        },
        child: _packSlot(
          index: index,
          tabWidth: tabWidth,
          tabHeight: tabHeight,
          colors: colors,
        ),
      ),
    );
  }

  Widget _packSlot({
    required int index,
    required double tabWidth,
    required double tabHeight,
    required AppColors colors,
  }) {
    final pack = _packs[index];
    final selected = index == _packIndex;
    final chip = _packTab(
      pack: pack,
      selected: selected,
      width: tabWidth,
      height: tabHeight,
      colors: colors,
    );
    return LongPressDraggable<String>(
      data: pack.id,
      delay: const Duration(milliseconds: 400),
      hapticFeedbackOnStart: true,
      rootOverlay: true,
      maxSimultaneousDrags: _drop.of(pack.id) ? 0 : 1,
      onDragStarted: () => _onPackDragStarted(index, tabWidth),
      onDragUpdate: (details) =>
          _onPackDragUpdate(details.globalPosition, tabWidth),
      onDragEnd: _onPackDragEnded,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.06,
          child: chip,
        ),
      ),
      childWhenDragging: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.pressed,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SizedBox(width: tabWidth, height: tabHeight),
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
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _packIndex = index),
          child: SizedBox(
            width: tabWidth,
            height: tabHeight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                pack.cover,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _packTab({
    required StickerPack pack,
    required bool selected,
    required double width,
    required double height,
    required AppColors colors,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? Color.lerp(
                colors.groupedBackground,
                colors.accentBright,
                0.15,
              )!
            : colors.groupedBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            pack.cover,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _stickerGrid({
    required AppColors colors,
    required String? packId,
    required List<String> stickers,
  }) {
    return FadeIn(
      key: ValueKey(packId ?? 'empty'),
      duration: const Duration(milliseconds: 320),
      offset: const Offset(0, 10),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: stickers.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns,
          mainAxisSpacing: _gridGap,
          crossAxisSpacing: _gridGap,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final sticker = stickers[index];
          return PressBounce(
            onPressed: () => Navigator.of(context).pop(sticker),
            color: Colors.transparent,
            pressedColor: colors.pressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                DayStickers.resolve(sticker),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
