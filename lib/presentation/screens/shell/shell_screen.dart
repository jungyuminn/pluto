import 'package:flutter/material.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_screen.dart';
import 'package:job_planner/presentation/screens/home/home_screen.dart';
import 'package:job_planner/presentation/screens/job/job_screen.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_bottom_nav.dart';
import 'package:job_planner/presentation/screens/shell/widgets/sliding_nav_indicator.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen>
    with SingleTickerProviderStateMixin {
  Widget _tabAt(int index) {
    switch (index) {
      case 0:
        return HomeScreen(visible: _index == 0);
      case 1:
        return CalendarScreen(visible: _index == 1);
      default:
        return const JobScreen();
    }
  }

  int _index = 1;
  int _previousIndex = 1;
  late final AnimationController _controller;
  late Animation<Offset> _incoming;
  late Animation<Offset> _outgoing;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SlidingNavIndicator.duration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _previousIndex = _index);
        }
      });
    _incoming = const AlwaysStoppedAnimation(Offset.zero);
    _outgoing = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _index) return;
    final fromLeft = index < _index;
    final dx = fromLeft ? -1.0 : 1.0;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _incoming = Tween<Offset>(
      begin: Offset(dx, 0),
      end: Offset.zero,
    ).animate(curve);
    _outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-dx, 0),
    ).animate(curve);
    setState(() {
      _previousIndex = _index;
      _index = index;
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            _TabSlot(
              key: ValueKey(i),
              visible: i == _index ||
                  (i == _previousIndex && _controller.isAnimating),
              offset: i == _index ? _incoming : _outgoing,
              absorbing: i != _index,
              child: _tabAt(i),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PillBottomNav(
              currentIndex: _index,
              onChanged: _onTabChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSlot extends StatelessWidget {
  const _TabSlot({
    super.key,
    required this.visible,
    required this.offset,
    required this.absorbing,
    required this.child,
  });

  final bool visible;
  final Animation<Offset> offset;
  final bool absorbing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: SlideTransition(
          position: offset,
          child: IgnorePointer(
            ignoring: absorbing,
            child: child,
          ),
        ),
      ),
    );
  }
}
