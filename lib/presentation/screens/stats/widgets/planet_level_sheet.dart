import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/stats/planet_stages.dart';
import 'package:job_planner/presentation/screens/stats/widgets/planet_fill.dart';

const _planetDeep = Color(0xFFD9898A);

Future<void> showPlanetLevelSheet(
  BuildContext context, {
  required int level,
  required bool isMax,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => _PlanetLevelSheet(
      level: isMax ? PlanetStage.maxLevel : level,
    ),
  );
}

Future<void> showPlanetPreviewDialog(
  BuildContext context,
  PlanetStage stage, {
  String? caption,
}) {
  HapticFeedback.selectionClick();
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x4D000000),
    builder: (context) => _PlanetPreviewDialog(
      stage: stage,
      caption: caption,
    ),
  );
}

class _PlanetLevelSheet extends StatefulWidget {
  const _PlanetLevelSheet({required this.level});

  final int level;

  @override
  State<_PlanetLevelSheet> createState() => _PlanetLevelSheetState();
}

class _PlanetLevelSheetState extends State<_PlanetLevelSheet> {
  static const _rowHeight = 84.0;
  static const _rowGap = 8.0;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    if (!mounted || !_scroll.hasClients) return;
    if (_scroll.position.maxScrollExtent <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _animateToCurrent();
      });
      return;
    }
    _animateToCurrent();
  }

  void _animateToCurrent() {
    if (!_scroll.hasClients) return;
    final stride = _rowHeight + _rowGap;
    final index = (widget.level - 1).clamp(0, PlanetStage.all.length - 1);
    final viewport = _scroll.position.viewportDimension;
    final target = (index * stride - (viewport - _rowHeight) / 2)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 8 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const SizedBox(width: 36, height: 4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.statsLevelGuideTitle,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.statsLevelGuideBody,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: PlanetStage.all.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: _rowGap),
                        itemBuilder: (context, i) {
                          final stage = PlanetStage.all[i];
                          return SizedBox(
                            height: _rowHeight,
                            child: _StageRow(
                              stage: stage,
                              current: stage.level == widget.level,
                              onPressed: () =>
                                  showPlanetPreviewDialog(context, stage),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.current,
    required this.onPressed,
  });

  final PlanetStage stage;
  final bool current;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    return PressBounce(
      onPressed: onPressed,
      pressedScale: 0.98,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.groupedBackground,
        borderRadius: BorderRadius.circular(18),
        border: current
            ? Border.all(color: _planetDeep.withValues(alpha: 0.7), width: 1.6)
            : Border.all(color: Colors.transparent, width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: PlanetFill(
                level: stage.level,
                wave: 0.12,
                outline: colors.icon,
                empty: colors.card,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.statsPlanetStage(stage.level),
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage.name,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              stage.need == 0
                  ? AppStrings.statsLevelStart
                  : AppStrings.statsLevelNeed(stage.need),
              style: TextStyle(
                fontFamily: font,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PlanetPreviewDialog extends StatefulWidget {
  const _PlanetPreviewDialog({
    required this.stage,
    this.caption,
  });

  final PlanetStage stage;
  final String? caption;

  @override
  State<_PlanetPreviewDialog> createState() => _PlanetPreviewDialogState();
}

class _PlanetPreviewDialogState extends State<_PlanetPreviewDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final stage = widget.stage;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) {
                    return PlanetFill(
                      level: stage.level,
                      wave: _wave.value,
                      outline: colors.icon,
                      empty: colors.card,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.statsPlanetStage(stage.level),
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stage.name,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              if (widget.caption != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.caption!,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
