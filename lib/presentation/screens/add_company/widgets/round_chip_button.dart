import 'package:flutter/material.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_chip.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_editor_sheet.dart';

class RoundChipButton extends StatelessWidget {
  const RoundChipButton({
    super.key,
    required this.label,
    required this.round,
    required this.applyStatus,
    required this.onChanged,
  });

  final String label;
  final ApplicationRound round;
  final String applyStatus;
  final ValueChanged<ApplicationRound> onChanged;

  Future<void> _open(BuildContext context) async {
    final result = await showRoundEditor(
      context,
      title: label,
      initial: round,
      applyStatus: applyStatus,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = round.name.trim();
    return PressBounce(
      color: round.isEmpty ? colors.pressed : colors.border,
      pressedColor: colors.border,
      borderRadius: BorderRadius.circular(999),
      onPressed: () => _open(context),
      child: ApplyStatusChip(label: name.isEmpty ? label : name),
    );
  }
}
