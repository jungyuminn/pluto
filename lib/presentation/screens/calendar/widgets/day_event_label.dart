import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_complete_button.dart';

class DayEventLabel extends StatefulWidget {
  const DayEventLabel({
    super.key,
    required this.title,
    required this.categoryName,
    required this.color,
    this.completed = false,
    this.isRepeat = false,
    this.isRange = false,
    this.isJob = false,
    this.onPressed,
    this.onLongPressed,
    this.onCompletePressed,
    this.showCategory = true,
    this.memo = '',
    this.timeText,
    this.titleWeight = FontWeight.w600,
  });

  final String title;
  final String categoryName;
  final Color color;
  final bool completed;
  final bool isRepeat;
  final bool isRange;
  final bool isJob;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final VoidCallback? onCompletePressed;
  final bool showCategory;
  final String memo;
  final String? timeText;
  final FontWeight titleWeight;

  @override
  State<DayEventLabel> createState() => _DayEventLabelState();
}

class _DayEventLabelState extends State<DayEventLabel> {
  var _skipLabelTap = false;
  late var _completed = widget.completed;

  static const _height = 52.0;

  @override
  void didUpdateWidget(DayEventLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completed != widget.completed) {
      _completed = widget.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = colors.tint(widget.color, 0.22);
    final scale = AppFonts.labelScaleOf(context);
    final height = _height * scale;
    final memoText = widget.memo.trim().replaceAll(RegExp(r'\s+'), ' ');
    final hasMemo = memoText.isNotEmpty;

    return PressBounce(
      onPressed: () {
        if (_skipLabelTap) {
          _skipLabelTap = false;
          return;
        }
        widget.onPressed?.call();
      },
      onLongPressed: () {
        if (_skipLabelTap) {
          _skipLabelTap = false;
          return;
        }
        widget.onLongPressed?.call();
      },
      color: background,
      pressedColor: Color.lerp(background, Colors.black, 0.08)!,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: widget.isJob
              ? Border.all(color: widget.color, width: 1.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: (_completed || widget.isJob) ? 0 : 4,
                  height: height,
                  color: widget.color,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.of(context),
                            fontSize: 12 * scale,
                            fontWeight: widget.titleWeight,
                            height: 1.15,
                            color: colors.text,
                          ),
                        ),
                        if (widget.showCategory ||
                            hasMemo ||
                            widget.timeText != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (widget.showCategory || hasMemo)
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        if (widget.showCategory)
                                          TextSpan(
                                            text: widget.categoryName,
                                            style: TextStyle(
                                              fontFamily: AppFonts.of(context),
                                              fontSize: 10 * scale,
                                              fontWeight: FontWeight.w600,
                                              height: 1.15,
                                              color: colors.hint,
                                            ),
                                          ),
                                        if (widget.showCategory && hasMemo)
                                          TextSpan(
                                            text: '  ·  ',
                                            style: TextStyle(
                                              fontFamily: AppFonts.of(context),
                                              fontSize: 10 * scale,
                                              fontWeight: FontWeight.w600,
                                              height: 1.15,
                                              color: colors.hint,
                                            ),
                                          ),
                                        if (hasMemo)
                                          TextSpan(
                                            text: memoText,
                                            style: TextStyle(
                                              fontFamily: AppFonts.of(context),
                                              fontSize: 10 * scale,
                                              fontWeight: FontWeight.w500,
                                              height: 1.15,
                                              color: colors.hint,
                                            ),
                                          ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else
                                const Spacer(),
                              if (widget.timeText != null) ...[
                                if (widget.showCategory || hasMemo)
                                  const SizedBox(width: 6),
                                Text(
                                  widget.timeText!,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppFonts.of(context),
                                    fontSize: 10 * scale,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: widget.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.isJob)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        widget.color,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        AppIcons.officeOutlined,
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                if (widget.isRange)
                  Padding(
                    padding: EdgeInsets.only(
                      right: widget.onCompletePressed == null && !widget.isRepeat
                          ? 6
                          : 0,
                    ),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        size: 22,
                        color: widget.color,
                      ),
                    ),
                  ),
                if (widget.isRepeat)
                  Padding(
                    padding: EdgeInsets.only(
                      right: widget.onCompletePressed == null ? 6 : 0,
                    ),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.repeat_rounded,
                        size: 22,
                        color: widget.color,
                      ),
                    ),
                  ),
                if (widget.onCompletePressed != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Listener(
                      onPointerDown: (_) => _skipLabelTap = true,
                      child: EventCompleteButton(
                        completed: _completed,
                        color: widget.color,
                        onPressed: () {
                          _skipLabelTap = true;
                          setState(() => _completed = !_completed);
                          widget.onCompletePressed!();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
