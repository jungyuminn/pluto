import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/mouse_drag_scroll.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/event_category.dart';

class CategoryColorPicker extends StatefulWidget {
  const CategoryColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.usedColors = const {},
    this.trailing,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final Set<int> usedColors;
  final Widget? trailing;

  @override
  State<CategoryColorPicker> createState() => _CategoryColorPickerState();
}

class _CategoryColorPickerState extends State<CategoryColorPicker> {
  static const _dot = 28.0;
  static const _gap = 14.0;
  static const _columns = 7;
  static const _gridWidth = _columns * _dot + (_columns - 1) * _gap;

  late final PageController _pages;
  late var _pack = EventCategory.packIndexOf(widget.selected);

  double _pageHeight(int count) {
    final rows = count <= 0 ? 1 : ((count + _columns - 1) ~/ _columns);
    return rows * _dot + (rows - 1) * _gap;
  }

  Widget _packGrid(List<int> colors) {
    final rows = colors.isEmpty ? 1 : ((colors.length + _columns - 1) ~/ _columns);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: _gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var col = 0; col < _columns; col++)
                SizedBox(
                  width: _dot,
                  height: _dot,
                  child: _cell(colors, row * _columns + col),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(List<int> colors, int index) {
    if (index >= colors.length) return const SizedBox.shrink();
    final value = colors[index];
    return _ColorDot(
      value: value,
      selected: widget.selected == value,
      used: widget.usedColors.contains(value),
      onPressed: () => widget.onSelected(value),
    );
  }

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _pack);
  }

  @override
  void didUpdateWidget(CategoryColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    final next = EventCategory.packIndexOf(widget.selected);
    if (next == _pack) return;
    setState(() => _pack = next);
    if (_pages.hasClients) {
      _pages.jumpToPage(next);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _pack) return;
    setState(() => _pack = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final packs = EventCategory.colorPacks;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pack = packs[_pack.clamp(0, packs.length - 1)];
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: _pageHeight(pack.colors.length),
                      width: constraints.maxWidth,
                      child: MouseDragScroll(
                        controller: _pages,
                        child: PageView.builder(
                          controller: _pages,
                          onPageChanged: (index) =>
                              setState(() => _pack = index),
                          itemCount: packs.length,
                          itemBuilder: (context, index) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: constraints.maxWidth
                                    .clamp(0.0, _gridWidth)
                                    .toDouble(),
                                child: _packGrid(packs[index].colors),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 12),
              widget.trailing!,
            ],
          ],
        ),
        if (packs.length > 1) ...[
          const SizedBox(height: 16),
          _PackDots(
            count: packs.length,
            index: _pack,
            onSelected: _goTo,
          ),
        ],
      ],
    );
  }
}

class _PackDots extends StatelessWidget {
  const _PackDots({
    required this.count,
    required this.index,
    required this.onSelected,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onSelected(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: i == index ? 8 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? colors.text.withValues(alpha: 0.45) : colors.muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.value,
    required this.selected,
    required this.used,
    required this.onPressed,
  });

  final int value;
  final bool selected;
  final bool used;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.9,
      color: Colors.transparent,
      pressedColor: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Semantics(
        selected: selected,
        label: used ? AppStrings.categoryColorInUse : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(value),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.card : Colors.transparent,
              width: 3,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                    ),
                  ]
                : const [],
          ),
          child: used
              ? const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
