import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';

OverlayEntry? _friendsToastEntry;

void showFriendsToast(BuildContext context, String text) {
  final previous = _friendsToastEntry;
  _friendsToastEntry = null;
  previous?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _FriendsToastOverlay(
      text: text,
      onFinished: () {
        if (entry.mounted) entry.remove();
        if (identical(_friendsToastEntry, entry)) {
          _friendsToastEntry = null;
        }
      },
    ),
  );
  _friendsToastEntry = entry;
  overlay.insert(entry);
}

class AnimatedFriendsToast extends StatefulWidget {
  const AnimatedFriendsToast({
    super.key,
    required this.text,
    required this.visible,
  });

  final String text;
  final bool visible;

  @override
  State<AnimatedFriendsToast> createState() => _AnimatedFriendsToastState();
}

class _AnimatedFriendsToastState extends State<AnimatedFriendsToast> {
  static const _duration = Duration(milliseconds: 280);

  late String _text = widget.text;
  late bool _visible = widget.visible;
  var _token = 0;

  @override
  void didUpdateWidget(covariant AnimatedFriendsToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameToast = widget.visible && _visible && widget.text != _text;
    if (sameToast) {
      _swap(widget.text);
      return;
    }
    setState(() {
      if (widget.text.isNotEmpty) _text = widget.text;
      _visible = widget.visible;
    });
  }

  void _swap(String next) {
    final token = ++_token;
    setState(() => _visible = false);
    Future<void>.delayed(_duration, () {
      if (!mounted || token != _token) return;
      setState(() {
        _text = next;
        _visible = widget.visible;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSlide(
        duration: _duration,
        curve: _visible ? Curves.easeOutCubic : Curves.easeInCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.18),
        child: AnimatedOpacity(
          duration: _duration,
          curve: _visible ? Curves.easeOutCubic : Curves.easeInCubic,
          opacity: _visible ? 1 : 0,
          child: _FriendsToastCard(text: _text),
        ),
      ),
    );
  }
}

class _FriendsToastOverlay extends StatefulWidget {
  const _FriendsToastOverlay({
    required this.text,
    required this.onFinished,
  });

  final String text;
  final VoidCallback onFinished;

  @override
  State<_FriendsToastOverlay> createState() => _FriendsToastOverlayState();
}

class _FriendsToastOverlayState extends State<_FriendsToastOverlay> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _visible = false);
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onFinished();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return IgnorePointer(
      child: Stack(
        children: [
          PcLayout.pinBottomToast(
            bottom: 20 + bottom,
            child: AnimatedFriendsToast(
              text: widget.text,
              visible: _visible,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsToastCard extends StatelessWidget {
  const _FriendsToastCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: colors.text,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
