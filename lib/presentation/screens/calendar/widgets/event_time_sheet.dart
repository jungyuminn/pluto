import 'dart:async';

import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
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
  Timer? _hintTimer;
  var _hintVisible = false;

  static const _interval = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final hourStart = now.hour * 60;
    _startMinutes = _snap(widget.startMinutes ?? hourStart);
    _endMinutes = _snap(widget.endMinutes ?? _startMinutes + 60);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  int _snap(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60 - _interval);
    return (clamped / _interval).round() * _interval;
  }

  void _showInvalidHint() {
    _hintTimer?.cancel();
    setState(() => _hintVisible = true);
    _hintTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() => _hintVisible = false);
    });
  }

  void _save() {
    if (_endMinutes <= _startMinutes) {
      _showInvalidHint();
      return;
    }
    Navigator.of(context).pop(
      EventTimePickResult(
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.of(context).tint(widget.color),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12 + bottom),
          child: Stack(
            children: [
              Column(
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
                    pressedColor: AppColors.of(context).tint(
                      AppColors.of(context).danger,
                      0.22,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(
                        AppStrings.timeClear,
                        style: TextStyle(
                          fontFamily: AppFonts.of(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).danger,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SaveCompanyButton(
                    onPressed: _save,
                    color: widget.color,
                  ),
                ],
              ),
            ],
          ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 56,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    curve: _hintVisible ? Curves.easeOut : Curves.easeIn,
                    opacity: _hintVisible ? 1 : 0,
                    child: const _TimeHintToast(),
                  ),
                ),
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
        fontFamily: AppFonts.of(context),
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
  static const _interval = 1;

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

  final int itemCount;
  final int initialIndex;
  final String Function(int index) labelAt;
  final ValueChanged<int> onChanged;
  final Color selectedColor;

  @override
  State<_FlatWheel> createState() => _FlatWheelState();
}

class _FlatWheelState extends State<_FlatWheel> {
  late final FixedExtentScrollController _controller;

  static const _extent = _FlatWheel.extent;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.initialIndex.clamp(0, widget.itemCount - 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.selectedColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(height: _extent, width: double.infinity),
              ),
            ),
          ),
        ),
        ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: _extent,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 8,
          perspective: 0.0001,
          overAndUnderCenterOpacity: 0.45,
          onSelectedItemChanged: widget.onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.itemCount,
            builder: (context, index) {
              return Center(
                child: Text(
                  widget.labelAt(index),
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: widget.selectedColor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimeHintToast extends StatelessWidget {
  const _TimeHintToast();

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
          AppStrings.timeOrderInvalid,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.of(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}
