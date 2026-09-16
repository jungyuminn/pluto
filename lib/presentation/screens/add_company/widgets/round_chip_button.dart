import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/application_round.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/presentation/screens/add_company/widgets/round_editor_sheet.dart';

class RoundChipButton extends StatelessWidget {
  const RoundChipButton({
    super.key,
    required this.round,
    required this.accent,
    required this.onChanged,
  });

  final ApplicationRound round;
  final Color accent;
  final ValueChanged<ApplicationRound> onChanged;

  static const height = 78.0;

  String get _label {
    final date = round.date;
    if (date == null) return AppStrings.roundChipLabel;
    return '${date.month}. ${date.day}.';
  }

  Future<void> _open(BuildContext context) async {
    final result = await showRoundEditor(
      context,
      title: AppStrings.roundChipLabel,
      initial: round,
      accent: accent,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final filled = !round.isEmpty;
    final name = round.name.trim();
    final radius = BorderRadius.circular(16);
    final ink = EventCategory.labelOf(accent);

    return Semantics(
      button: true,
      label: _label,
      child: PressBounce(
        color: filled ? colors.tint(accent, 0.18) : colors.card,
        pressedColor: filled ? colors.tint(accent, 0.3) : colors.pressed,
        borderRadius: radius,
        onPressed: () => _open(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: filled ? accent : colors.border,
              width: filled ? 1.4 : 1,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: 0,
                        color: filled ? ink : colors.muted,
                      ),
                    ),
                  ),
                  if (name.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.of(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: filled ? colors.text : colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
