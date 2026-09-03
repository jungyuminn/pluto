import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/stats/planet_stages.dart';
import 'package:job_planner/presentation/screens/stats/widgets/planet_fill.dart';

Future<DateTime?> showCollectedPlanetSheet(
  BuildContext context, {
  required List<CollectedPlanet> collected,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    elevation: 0,
    builder: (context) => _CollectedPlanetSheet(collected: collected),
  );
}

class _CollectedPlanetSheet extends StatelessWidget {
  const _CollectedPlanetSheet({required this.collected});

  final List<CollectedPlanet> collected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    final nowYear = DateTime.now().year;
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
                      AppStrings.statsCollectedTitle,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collected.isEmpty
                          ? AppStrings.statsCollectedEmpty
                          : AppStrings.statsCollectedBody,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: collected.isEmpty
                          ? const SizedBox.shrink()
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                const minTile = 96.0;
                                const gap = 12.0;
                                final width = constraints.maxWidth;
                                final columns = ((width + gap) /
                                        (minTile + gap))
                                    .floor()
                                    .clamp(1, 99);
                                final tileW =
                                    (width - gap * (columns - 1)) / columns;
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Wrap(
                                    spacing: gap,
                                    runSpacing: 8,
                                    children: [
                                      for (final planet in collected)
                                        _CollectedPlanetTile(
                                          planet: planet,
                                          width: tileW,
                                          nowYear: nowYear,
                                          font: font,
                                          colors: colors,
                                        ),
                                    ],
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

class _CollectedPlanetTile extends StatelessWidget {
  const _CollectedPlanetTile({
    required this.planet,
    required this.width,
    required this.nowYear,
    required this.font,
    required this.colors,
  });

  final CollectedPlanet planet;
  final double width;
  final int nowYear;
  final String? font;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final label = AppStrings.statsCollectedMonth(
      planet.month,
      nowYear: nowYear,
    );
    return PressBounce(
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(planet.month);
      },
      pressedScale: 0.96,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: PlanetFill(
                key: ValueKey(planet.month),
                level: planet.isMax ? PlanetStage.maxLevel : planet.level,
                wave: 0.1,
                phase: (planet.month.year * 12 + planet.month.month) * 0.17 % 1,
                outline: colors.icon,
                empty: colors.card,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    planet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
