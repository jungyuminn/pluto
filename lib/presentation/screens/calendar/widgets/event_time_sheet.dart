import 'dart:async';

import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/widgets/flat_snap_picker.dart';

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
  var _editStart = true;
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
      EventTimePickResult(startMinutes: _startMinutes, endMinutes: _endMinutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tint(widget.color, 0.14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 4 + bottom),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: SaveCompanyButton.size,
                          height: SaveCompanyButton.size,
                          child: PressBounce(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop(const EventTimePickResult());
                            },
                            color: colors.card,
                            pressedColor: Color.lerp(
                              colors.card,
                              Colors.black,
                              0.08,
                            )!,
                            borderRadius: BorderRadius.circular(999),
                            expand: true,
                            child: Center(
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  colors.danger,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  AppIcons.clockRemove,
                                  width: SaveCompanyButton.size / 2,
                                  height: SaveCompanyButton.size / 2,
                                  semanticLabel: AppStrings.timeClear,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SaveCompanyButton(onPressed: _save, color: widget.color),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeCard(
                          label: AppStrings.timeStartLabel,
                          minutes: _startMinutes,
                          color: widget.color,
                          selected: _editStart,
                          onPressed: () {
                            if (_editStart) return;
                            setState(() => _editStart = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TimeCard(
                          label: AppStrings.timeEndLabel,
                          minutes: _endMinutes,
                          color: widget.color,
                          selected: !_editStart,
                          onPressed: () {
                            if (!_editStart) return;
                            setState(() => _editStart = false);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: SizedBox(
                        height: _FlatWheel.extent * 5,
                        child: _TimeWheels(
                          minutes: _editStart ? _startMinutes : _endMinutes,
                          selectedColor: widget.color,
                          onChanged: (value) {
                            setState(() {
                              if (_editStart) {
                                _startMinutes = value;
                              } else {
                                _endMinutes = value;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
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
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.minutes,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final int minutes;
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: colors.card,
      pressedColor: Color.lerp(colors.card, Colors.black, 0.08)!,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : colors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(minutes),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: selected ? color : colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(int minutes) {
  final hour24 = (minutes ~/ 60).clamp(0, 23);
  final minute = (minutes % 60).clamp(0, 59);
  final period = hour24 < 12 ? AppStrings.amLabel : AppStrings.pmLabel;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$period $hour12:${minute.toString().padLeft(2, '0')}';
}

class _TimeWheels extends StatefulWidget {
  const _TimeWheels({
    super.key,
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
    _applyMinutes(widget.minutes);
  }

  @override
  void didUpdateWidget(_TimeWheels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minutes == oldWidget.minutes) return;
    if (widget.minutes == _currentMinutes()) return;
    setState(() => _applyMinutes(widget.minutes));
  }

  void _applyMinutes(int minutes) {
    _pm = (minutes ~/ 60) >= 12;
    _hour12 = _toHour12(minutes ~/ 60);
    _minuteValue = minutes % 60;
  }

  int _toHour12(int hour24) {
    final hour = hour24 % 12;
    return hour == 0 ? 12 : hour;
  }

  int _currentMinutes() {
    final hour = _hour12 % 12 + (_pm ? 12 : 0);
    return hour * 60 + _minuteValue;
  }

  void _emit() {
    widget.onChanged(_currentMinutes());
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          stops: [0, 0.18, 0.82, 1],
        ).createShader(rect);
      },
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: _FlatWheel(
              selectedColor: widget.selectedColor,
              itemCount: 2,
              index: _pm ? 1 : 0,
              labelAt: (index) =>
                  index == 0 ? AppStrings.amLabel : AppStrings.pmLabel,
              onChanged: (index) {
                _pm = index == 1;
                _emit();
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: _FlatWheel(
              selectedColor: widget.selectedColor,
              itemCount: 12,
              index: _hour12 - 1,
              loop: true,
              labelAt: (index) => '${index + 1}',
              onChanged: (index) {
                _hour12 = index + 1;
                _emit();
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: _FlatWheel(
              selectedColor: widget.selectedColor,
              itemCount: 60 ~/ _interval,
              index: _minuteValue ~/ _interval,
              loop: true,
              labelAt: (index) =>
                  (index * _interval).toString().padLeft(2, '0'),
              onChanged: (index) {
                _minuteValue = index * _interval;
                _emit();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatWheel extends StatelessWidget {
  const _FlatWheel({
    required this.itemCount,
    required this.index,
    required this.labelAt,
    required this.onChanged,
    required this.selectedColor,
    this.loop = false,
  });

  static const extent = 36.0;
  static const highlightWidth = 52.0;
  static const highlightHeight = 32.0;

  final int itemCount;
  final int index;
  final String Function(int index) labelAt;
  final ValueChanged<int> onChanged;
  final Color selectedColor;
  final bool loop;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).muted;
    return FlatSnapPicker(
      itemCount: itemCount,
      index: index,
      itemExtent: extent,
      loop: loop,
      onChanged: onChanged,
      itemBuilder: (context, itemIndex, selected) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: highlightWidth,
            height: highlightHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? selectedColor.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: selected ? 18 : 15,
                fontWeight: FontWeight.w600,
                height: 1,
                color: selected
                    ? selectedColor
                    : muted.withValues(alpha: 0.7),
              ),
              child: Text(labelAt(itemIndex)),
            ),
          ),
        );
      },
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
