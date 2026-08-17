import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/add_round_chip_button.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_chip_button.dart';

class RoundChipRow extends StatelessWidget {
  const RoundChipRow({
    super.key,
    required this.rounds,
    required this.applyStatus,
    required this.onRoundChanged,
    required this.onAddRound,
    required this.onRemoveRound,
  });

  final List<ApplicationRound> rounds;
  final String applyStatus;
  final void Function(int index, ApplicationRound round) onRoundChanged;
  final VoidCallback onAddRound;
  final VoidCallback onRemoveRound;

  @override
  Widget build(BuildContext context) {
    final count = rounds.length;
    final firstCount = count.clamp(0, JobApplication.firstRowRoundCount);
    final showPlus = count < JobApplication.maxRoundCount;
    final showMinus = count > JobApplication.minRoundCount;
    final controlsOnFirst = count < JobApplication.firstRowRoundCount;
    final showSecond = count > JobApplication.firstRowRoundCount ||
        ((showPlus || showMinus) && !controlsOnFirst);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chipRow(
            start: 0,
            end: firstCount,
            showPlus: showPlus && controlsOnFirst,
            showMinus: showMinus && controlsOnFirst,
          ),
          if (showSecond) ...[
            const SizedBox(height: 8),
            _chipRow(
              start: JobApplication.firstRowRoundCount,
              end: count,
              showPlus: showPlus && !controlsOnFirst,
              showMinus: showMinus && !controlsOnFirst,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipRow({
    required int start,
    required int end,
    required bool showPlus,
    required bool showMinus,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = start; i < end; i++) ...[
            if (i > start) const SizedBox(width: 8),
            RoundChipButton(
              label: AppStrings.roundLabel(i + 1),
              round: rounds[i],
              applyStatus: applyStatus,
              onChanged: (round) => onRoundChanged(i, round),
            ),
          ],
          if (showPlus || showMinus) ...[
            if (end > start) const SizedBox(width: 8),
            if (showPlus)
              AddRoundChipButton(onPressed: onAddRound),
            if (showPlus && showMinus) const SizedBox(width: 8),
            if (showMinus)
              AddRoundChipButton(
                icon: Icons.remove,
                onPressed: onRemoveRound,
              ),
          ],
        ],
      ),
    );
  }
}
