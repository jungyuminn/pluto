import 'dart:async';

import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/presentation/screens/calendar/calendar_screen.dart';
import 'package:job_planner/presentation/screens/home/home_screen.dart';
import 'package:job_planner/presentation/screens/job/job_screen.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_bottom_nav.dart';
import 'package:job_planner/presentation/tutorial/tutorial_controller.dart';
import 'package:job_planner/presentation/tutorial/tutorial_overlay.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen>
    with SingleTickerProviderStateMixin {
  static const _tabDuration = Duration(milliseconds: 340);

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
  late Animation<double> _incomingOpacity;
  late Animation<double> _outgoingOpacity;
  TutorialController? _tutorial;
  var _autoStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _tabDuration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _previousIndex = _index);
        }
      });
    _incoming = const AlwaysStoppedAnimation(Offset.zero);
    _outgoing = const AlwaysStoppedAnimation(Offset.zero);
    _incomingOpacity = const AlwaysStoppedAnimation(1);
    _outgoingOpacity = const AlwaysStoppedAnimation(1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = TutorialController.maybeOf(context);
    if (!identical(next, _tutorial)) {
      _tutorial?.removeListener(_onTutorial);
      _tutorial = next;
      _tutorial?.addListener(_onTutorial);
    }
    if (_autoStarted || next == null) return;
    _autoStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeStartTutorial());
    });
  }

  @override
  void dispose() {
    _tutorial?.removeListener(_onTutorial);
    _controller.dispose();
    super.dispose();
  }

  void _onTutorial() {
    final tutorial = _tutorial;
    if (tutorial == null || !tutorial.active) return;
    _onTabChanged(tutorial.step.tab);
  }

  Future<void> _maybeStartTutorial() async {
    if (!mounted) return;
    final tutorial = _tutorial;
    if (tutorial == null || !tutorial.shouldAutoStart) return;
    final scope = AppScope.of(context);
    final events = await scope.getCalendarEvents();
    final jobs = await scope.getJobApplications();
    final diaries = await scope.getDiaries();
    if (!mounted) return;
    await tutorial.maybeAutoStart(
      hasExistingData:
          events.isNotEmpty || jobs.isNotEmpty || diaries.isNotEmpty,
    );
  }

  void _onTabChanged(int index) {
    if (index == _index) return;
    final fromLeft = index < _index;
    final dx = fromLeft ? -0.18 : 0.18;
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
    _incomingOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );
    _outgoingOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeIn),
      ),
    );
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
              opacity: i == _index ? _incomingOpacity : _outgoingOpacity,
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
          const TutorialOverlay(),
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
    required this.opacity,
    required this.absorbing,
    required this.child,
  });

  final bool visible;
  final Animation<Offset> offset;
  final Animation<double> opacity;
  final bool absorbing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: ExcludeFocus(
          excluding: absorbing,
          child: FadeTransition(
            opacity: opacity,
            child: SlideTransition(
              position: offset,
              child: IgnorePointer(
                ignoring: absorbing,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
