import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';

class EventTimePickResult {
  const EventTimePickResult({this.startMinutes, this.endMinutes});

  final int? startMinutes;
  final int? endMinutes;

  bool get isCleared => startMinutes == null && endMinutes == null;
}

Future<EventTimePickResult?> showEventTimeSheet(
  BuildContext context, {
  int? startMinutes,
  int? endMinutes,
  Color color = const Color(0xFF3B82F6),
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<EventTimePickResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => EventTimeSheet(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      color: color,
    ),
  );
}

class EventTimeSheet extends StatefulWidget {
  const EventTimeSheet({
    super.key,
    this.startMinutes,
    this.endMinutes,
    required this.color,
  });

  final int? startMinutes;
  final int? endMinutes;
  final Color color;

  @override
  State<EventTimeSheet> createState() => _EventTimeSheetState();
}

class _EventTimeSheetState extends State<EventTimeSheet> {
  late int _startMinutes;
  late int _endMinutes;

  static const _interval = 5;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final rounded = _snap(now.hour * 60 + now.minute);
    _startMinutes = _snap(widget.startMinutes ?? rounded);
    _endMinutes = _snap(widget.endMinutes ?? (_startMinutes + 60) % (24 * 60));
  }

  int _snap(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60 - _interval);
    return (clamped / _interval).round() * _interval;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFFFFFFF), widget.color, 0.28)!,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _columnLabel(AppStrings.timeStartLabel)),
                  Expanded(child: _columnLabel(AppStrings.timeEndLabel)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _FlatWheel.extent * 5,
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeWheels(
                        minutes: _startMinutes,
                        selectedColor: widget.color,
                        onChanged: (value) => _startMinutes = value,
                      ),
                    ),
                    Expanded(
                      child: _TimeWheels(
                        minutes: _endMinutes,
                        selectedColor: widget.color,
                        onChanged: (value) => _endMinutes = value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  PressBounce(
                    onPressed: () {
                      Navigator.of(context).pop(const EventTimePickResult());
                    },
                    color: Colors.transparent,
                    pressedColor: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(
                        AppStrings.timeClear,
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SaveCompanyButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        EventTimePickResult(
                          startMinutes: _startMinutes,
                          endMinutes: _endMinutes,
                        ),
                      );
                    },
                    color: widget.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _columnLabel(String label) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.pretendard,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: widget.color,
      ),
    );
  }
}

class _TimeWheels extends StatefulWidget {
  const _TimeWheels({
    required this.minutes,
    required this.selectedColor,
    required this.onChanged,
  });

  final int minutes;
  final Color selectedColor;
  final ValueChanged<int> onChanged;

  @override
  State<_TimeWheels> createState() => _TimeWheelsState();
}

class _TimeWheelsState extends State<_TimeWheels> {
  static const _interval = 5;

  late bool _pm;
  late int _hour12;
  late int _minuteValue;

  @override
  void initState() {
    super.initState();
    _pm = (widget.minutes ~/ 60) >= 12;
    _hour12 = _toHour12(widget.minutes ~/ 60);
    _minuteValue = widget.minutes % 60;
  }

  int _toHour12(int hour24) {
    final hour = hour24 % 12;
    return hour == 0 ? 12 : hour;
  }

  void _emit() {
    final hour = _hour12 % 12 + (_pm ? 12 : 0);
    widget.onChanged(hour * 60 + _minuteValue);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _FlatWheel(
            selectedColor: widget.selectedColor,
            itemCount: 2,
            initialIndex: _pm ? 1 : 0,
            labelAt: (index) =>
                index == 0 ? AppStrings.amLabel : AppStrings.pmLabel,
            onChanged: (index) {
              _pm = index == 1;
              _emit();
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: _FlatWheel(
            selectedColor: widget.selectedColor,
            itemCount: 12,
            initialIndex: _hour12 - 1,
            labelAt: (index) => '${index + 1}',
            onChanged: (index) {
              _hour12 = index + 1;
              _emit();
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: _FlatWheel(
            selectedColor: widget.selectedColor,
            itemCount: 60 ~/ _interval,
            initialIndex: _minuteValue ~/ _interval,
            labelAt: (index) => (index * _interval).toString().padLeft(2, '0'),
            onChanged: (index) {
              _minuteValue = index * _interval;
              _emit();
            },
          ),
        ),
      ],
    );
  }
}

class _FlatWheel extends StatefulWidget {
  const _FlatWheel({
    required this.itemCount,
    required this.initialIndex,
    required this.labelAt,
    required this.onChanged,
    required this.selectedColor,
  });

  static const extent = 40.0;
  static const visible = 5;

  final int itemCount;
  final int initialIndex;
  final String Function(int index) labelAt;
  final ValueChanged<int> onChanged;
  final Color selectedColor;

  @override
  State<_FlatWheel> createState() => _FlatWheelState();
}

class _FlatWheelState extends State<_FlatWheel> {
  late final ScrollController _controller;
  late int _selected;

  static const _extent = _FlatWheel.extent;
  static const _pad = _extent * ((_FlatWheel.visible - 1) / 2);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex.clamp(0, widget.itemCount - 1);
    _controller = ScrollController(initialScrollOffset: _selected * _extent);
    _controller.addListener(_syncSelected);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncSelected);
    _controller.dispose();
    super.dispose();
  }

  void _syncSelected() {
    if (!_controller.hasClients) return;
    final index = (_controller.offset / _extent)
        .round()
        .clamp(0, widget.itemCount - 1);
    if (index == _selected) return;
    setState(() => _selected = index);
    widget.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemExtent: _extent,
      itemCount: widget.itemCount,
      padding: const EdgeInsets.symmetric(vertical: _pad),
      physics: const _SnapScrollPhysics(itemExtent: _extent),
      itemBuilder: (context, index) {
        final selected = index == _selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? widget.selectedColor.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                height: 1,
                color: selected
                    ? widget.selectedColor
                    : const Color(0xFF9CA3AF),
              ),
              child: Text(widget.labelAt(index)),
            ),
          ),
        );
      },
    );
  }
}

class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({super.parent, required this.itemExtent});

  final double itemExtent;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      parent: buildParent(ancestor),
      itemExtent: itemExtent,
    );
  }

  double _targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    var item = position.pixels / itemExtent;
    if (velocity < -tolerance.velocity) {
      item -= 0.45;
    } else if (velocity > tolerance.velocity) {
      item += 0.45;
    }
    return item.roundToDouble() * itemExtent;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final snapTolerance = toleranceFor(position);
    final target = _targetPixels(position, snapTolerance, velocity);
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: snapTolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
