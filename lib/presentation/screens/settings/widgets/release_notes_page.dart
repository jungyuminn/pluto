import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/constants/release_notes.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/screens/settings/widgets/release_note_demos.dart';

class ReleaseNotesPage extends StatefulWidget {
  const ReleaseNotesPage({super.key});

  @override
  State<ReleaseNotesPage> createState() => _ReleaseNotesPageState();
}

class _ReleaseNotesPageState extends State<ReleaseNotesPage> {
  late final _open = {ReleaseNotes.all.first.version};

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final notes = ReleaseNotes.all;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      extendBodyBehindAppBar: true,
      appBar: _Bar(
        title: AppStrings.releaseNotesTitle,
        onBack: () => Navigator.pop(context),
      ),
      body: PcLayout.constrainWidth(
        ListView(
          padding: EdgeInsets.fromLTRB(16, top + 48, 16, 32),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    for (var i = 0; i < notes.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colors.border,
                          ),
                        ),
                      _VersionRow(
                        note: notes[i],
                        open: _open.contains(notes[i].version),
                        onToggle: () {
                          setState(() {
                            final version = notes[i].version;
                            if (_open.contains(version)) {
                              _open.remove(version);
                            } else {
                              _open.add(version);
                            }
                          });
                        },
                        onOpenNote: () => _openShowcase(context, notes[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openShowcase(BuildContext context, ReleaseNote note) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useSafeArea: false,
      showDragHandle: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x4D000000),
      elevation: 0,
      builder: (context) => _ReleaseShowcaseSheet(note: note),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.note,
    required this.open,
    required this.onToggle,
    required this.onOpenNote,
  });

  final ReleaseNote note;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onOpenNote;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        PressBounce(
          onPressed: onToggle,
          pressedScale: 0.98,
          color: colors.card,
          pressedColor: colors.pressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note.version,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colors.text,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        _ExpandBelow(
          open: open,
          child: _NoteBody(note: note, onPressed: onOpenNote),
        ),
      ],
    );
  }
}

class _NoteBody extends StatelessWidget {
  const _NoteBody({required this.note, required this.onPressed});

  final ReleaseNote note;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.98,
      color: colors.card,
      pressedColor: colors.pressed,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note.items.isNotEmpty) ...[
                const _Heading(AppStrings.releaseNotesFeatures),
                for (final item in note.items) _Bullet(item),
              ],
              if (note.fixes.isNotEmpty) ...[
                _Heading(
                  AppStrings.releaseNotesFixes,
                  padTop: note.items.isNotEmpty,
                ),
                for (final item in note.fixes) _Bullet(item),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.padTop = false});

  final String text;
  final bool padTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: padTop ? 8 : 0),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.of(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).muted,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final style = TextStyle(
      fontFamily: AppFonts.of(context),
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: colors.text,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 16, child: Text('·', style: style)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _ExpandBelow extends StatefulWidget {
  const _ExpandBelow({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  State<_ExpandBelow> createState() => _ExpandBelowState();
}

class _ExpandBelowState extends State<_ExpandBelow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
      value: widget.open ? 1 : 0,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _ExpandBelow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) return;
    if (widget.open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _fade,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fade,
          child: IgnorePointer(
            ignoring: !widget.open,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ReleaseShowcaseSheet extends StatelessWidget {
  const _ReleaseShowcaseSheet({required this.note});

  final ReleaseNote note;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final frames = [
      for (final item in note.items)
        (text: item, demo: releaseDemoFor(item, isFix: false)),
      for (final fix in note.fixes)
        (text: fix, demo: releaseDemoFor(fix, isFix: true)),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            maxWidth: PcLayout.isPc
                ? PcLayout.contentMaxWidth
                : double.infinity,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    note.version,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.releaseNotesPreview,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (frames.isEmpty)
                    Text(
                      AppStrings.releaseNotesFeatures,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 14,
                        color: colors.muted,
                      ),
                    )
                  else
                    _ShowcaseCycle(frames: frames),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowcaseCycle extends StatefulWidget {
  const _ShowcaseCycle({required this.frames});

  final List<({String text, ReleaseDemo demo})> frames;

  @override
  State<_ShowcaseCycle> createState() => _ShowcaseCycleState();
}

class _ShowcaseCycleState extends State<_ShowcaseCycle> {
  var _index = 0;
  Timer? _timer;

  bool get _canCycle => widget.frames.length > 1;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_canCycle) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _goTo(_index + 1);
    });
  }

  void _goTo(int next, {bool fromUser = false}) {
    if (!_canCycle) return;
    final index = next % widget.frames.length;
    final wrapped = index < 0 ? index + widget.frames.length : index;
    if (wrapped == _index) return;
    setState(() => _index = wrapped);
    if (fromUser) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[_index];
    final colors = AppColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: !_canCycle
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 180) return;
              _goTo(velocity < 0 ? _index + 1 : _index - 1, fromUser: true);
            },
      child: Column(
        children: [
          Row(
            children: [
              if (_canCycle)
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _goTo(_index - 1, fromUser: true),
                )
              else
                const SizedBox(width: 32),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    child: DecoratedBox(
                      key: ValueKey(frame.text),
                      decoration: BoxDecoration(
                        color: colors.tint(colors.accentBright, 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          frame.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: colors.accentBright,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_canCycle)
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _goTo(_index + 1, fromUser: true),
                )
              else
                const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 480),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(frame.text),
              child: IgnorePointer(child: ReleaseDemoView(demo: frame.demo)),
            ),
          ),
          if (_canCycle) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.frames.length; i++)
                  PressBounce(
                    onPressed: () => _goTo(i, fromUser: true),
                    pressedScale: 0.9,
                    pressedColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: i == _index ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? colors.accentBright
                              : colors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.88,
      pressedColor: Colors.transparent,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 26, color: colors.muted),
      ),
    );
  }
}

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  static const _toolbarHeight = 48.0;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ColoredBox(
          color: colors.groupedBackground.withValues(alpha: 0.08),
          child: AppBar(
            forceMaterialTransparency: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            toolbarHeight: _toolbarHeight,
            centerTitle: true,
            leading: PressBounce(
              onPressed: onBack,
              pressedColor: Colors.transparent,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                  color: colors.text,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
