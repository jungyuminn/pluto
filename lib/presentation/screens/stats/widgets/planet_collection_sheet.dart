import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/presentation/screens/stats/planet_stages.dart';
import 'package:pluto/presentation/screens/stats/widgets/planet_fill.dart';

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

class _CollectedPlanetSheet extends StatefulWidget {
  const _CollectedPlanetSheet({required this.collected});

  final List<CollectedPlanet> collected;

  @override
  State<_CollectedPlanetSheet> createState() => _CollectedPlanetSheetState();
}

class _CollectedPlanetSheetState extends State<_CollectedPlanetSheet> {
  static const _minTile = 96.0;
  static const _gap = 12.0;
  static const _runGap = 8.0;

  late final List<int> _years;
  late final Map<int, List<CollectedPlanet>> _byYear;
  late final PageController _pager;
  late final int _nowYear;
  late int _page;

  @override
  void initState() {
    super.initState();
    _nowYear = DateTime.now().year;
    _byYear = {};
    var oldest = _nowYear;
    for (final planet in widget.collected) {
      final year = planet.month.year;
      _byYear.putIfAbsent(year, () => []).add(planet);
      if (year < oldest) oldest = year;
    }
    _years = [for (var year = oldest; year <= _nowYear; year++) year];
    _page = _years.length - 1;
    _pager = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.64;
    final collected = widget.collected;
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
                  mainAxisSize: MainAxisSize.min,
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
                    if (collected.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Flexible(
                        fit: FlexFit.loose,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final columns = ((width + _gap) / (_minTile + _gap))
                                .floor()
                                .clamp(1, 99);
                            final tileW =
                                (width - _gap * (columns - 1)) / columns;
                            final currentCount =
                                _byYear[_nowYear]?.length ?? 0;
                            final rows = ((currentCount < 1 ? 1 : currentCount) /
                                    columns)
                                .ceil()
                                .clamp(1, 99);
                            final gridH = rows * tileW +
                                (rows - 1) * _runGap +
                                8;
                            final dotsH = _years.length > 1 ? 16.0 : 0.0;
                            final height = gridH.clamp(
                              0.0,
                              (constraints.maxHeight - dotsH).clamp(0.0, double.infinity),
                            );
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: height,
                                  child: PageView.builder(
                                controller: _pager,
                                itemCount: _years.length,
                                onPageChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _page = index);
                                },
                                itemBuilder: (context, index) {
                                  final pageYear = _years[index];
                                  final planets = _byYear[pageYear] ?? const [];
                                  if (planets.isEmpty) {
                                    return Center(
                                      child: Text(
                                        AppStrings.statsCollectedYearEmpty,
                                        style: TextStyle(
                                          fontFamily: font,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: colors.muted,
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    children: [
                                      Wrap(
                                        spacing: _gap,
                                        runSpacing: _runGap,
                                        children: [
                                          for (final planet in planets)
                                            _CollectedPlanetTile(
                                              planet: planet,
                                              width: tileW,
                                              nowYear: _nowYear,
                                              font: font,
                                              colors: colors,
                                            ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                                  ),
                                ),
                                if (_years.length > 1) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (var i = 0; i < _years.length; i++) ...[
                                        if (i > 0) const SizedBox(width: 6),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: i == _page
                                                ? colors.accentBright
                                                : colors.muted.withValues(
                                                    alpha: 0.45,
                                                  ),
                                          ),
                                          child: const SizedBox.square(
                                            dimension: 6,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
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
        height: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.groupedBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: PlanetFill(
                      key: ValueKey(planet.month),
                      level:
                          planet.isMax ? PlanetStage.maxLevel : planet.level,
                      wave: 0.1,
                      phase: (planet.month.year * 12 + planet.month.month) *
                          0.17 %
                          1,
                      outline: colors.icon,
                      empty: colors.groupedBackground,
                      pokeable: false,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 11,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: colors.text,
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
