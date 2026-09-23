import 'package:flutter/material.dart';

class DropSettle {
  String? id;
  Offset from = Offset.zero;
  var gen = 0;

  bool of(String? itemId) => itemId != null && itemId == id;

  void arm(String? itemId, Offset delta) {
    if (itemId != null && delta.distanceSquared > 4) {
      id = itemId;
      from = delta;
      gen++;
    } else {
      id = null;
    }
  }

  void clear() => id = null;

  Widget wrap({
    required String? itemId,
    required Widget child,
    required VoidCallback onDone,
    bool clipOthers = false,
  }) {
    final settling = of(itemId);
    final body = clipOthers && !settling ? ClipRect(child: child) : child;
    if (!settling) return body;
    return DropIn(
      key: ValueKey(gen),
      from: from,
      onDone: onDone,
      child: body,
    );
  }
}

class DropIn extends StatefulWidget {
  const DropIn({
    super.key,
    required this.from,
    required this.child,
    this.onDone,
  });

  final Offset from;
  final Widget child;
  final VoidCallback? onDone;

  @override
  State<DropIn> createState() => _DropInState();
}

class _DropInState extends State<DropIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _offset = Tween<Offset>(begin: widget.from, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone?.call();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        return Transform.translate(
          offset: _offset.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
