import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/open_local_file.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/domain/entities/apply_status.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_dot.dart';

class CompanyCard extends StatefulWidget {
  const CompanyCard({
    super.key,
    required this.application,
    this.onPressed,
    this.onLongPressed,
    this.compact = false,
  });

  final JobApplication application;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final bool compact;

  @override
  State<CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard>
    with SingleTickerProviderStateMixin {
  var _skipCardTap = false;
  late final AnimationController _expand;
  late final CurvedAnimation _expandFade;

  JobApplication get application => widget.application;

  bool get _hasCoverLetter {
    final fileName = application.coverLetterFileName?.trim() ?? '';
    return fileName.isNotEmpty;
  }

  bool get _hasDetails {
    return _hasCoverLetter || application.rounds.any((round) => !round.isEmpty);
  }

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      value: widget.compact ? 0 : 1,
    );
    _expandFade = CurvedAnimation(
      parent: _expand,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(CompanyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.compact == widget.compact) return;
    if (widget.compact) {
      _expand.reverse();
    } else {
      _expand.forward();
    }
  }

  @override
  void dispose() {
    _expandFade.dispose();
    _expand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = application.categoryColor != null
        ? Color(application.categoryColor!)
        : colors.accent;
    final rejected = ApplyStatus.isRejected(application.applyStatus);
    final dDay = rejected ? null : application.upcomingDDay();
    final compact = widget.compact;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: () {
          if (_skipCardTap) {
            _skipCardTap = false;
            return;
          }
          widget.onPressed?.call();
        },
        onLongPressed: widget.onLongPressed,
        color: rejected ? colors.pressed : colors.card,
        pressedColor: colors.border,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 10 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Opacity(
            opacity: rejected ? 0.48 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dDay != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      dDay == 0 ? 'D-Day' : 'D-$dDay',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.of(context).danger,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _title()),
                    const SizedBox(width: 8),
                    _status(application.applyStatus, accent),
                  ],
                ),
                if (_hasDetails)
                  SizeTransition(
                    sizeFactor: _expandFade,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _expandFade,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Table(
                          columnWidths: const {
                            0: IntrinsicColumnWidth(),
                            1: FlexColumnWidth(),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.top,
                          children: [
                            for (var i = 0; i < application.rounds.length; i++)
                              if (!application.rounds[i].isEmpty)
                                _round(
                                  AppStrings.roundLabel(i + 1),
                                  application.rounds[i],
                                ),
                            if (_hasCoverLetter) _coverLetterRow(),
                          ],
                        ),
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

  Widget _title() {
    final position = application.position.trim();
    final scale = AppFonts.todoScaleOf(context);
    final category = application.categoryName.trim();
    final accent = application.categoryColor != null
        ? Color(application.categoryColor!)
        : AppColors.of(context).accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                application.companyName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (position.isNotEmpty)
              Flexible(
                child: Text(
                  ' ($position)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.of(context),
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).secondary,
                  ),
                ),
              ),
          ],
        ),
        if (application.hasCategory && category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.of(context),
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _status(String status, Color accent) {
    if (status.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ApplyStatusDot(color: accent),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _round(String label, ApplicationRound round) {
    final date = round.date;
    final title = date == null
        ? label
        : '$label(${date.month}.${date.day})';
    final name = round.name.trim();
    final note = round.note.trim();
    final value = name.isEmpty
        ? (note.isEmpty ? null : note)
        : (note.isEmpty ? name : '$name ($note)');
    return _row(title, value, struck: round.isPast());
  }

  TableRow _coverLetterRow() {
    final fileName = application.coverLetterFileName?.trim() ?? '';
    final path = application.coverLetterPath?.trim() ?? '';
    final canOpen = fileName.isNotEmpty && path.isNotEmpty;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: Text(
            AppStrings.colCoverLetter,
            style: TextStyle(color: AppColors.of(context).secondary, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _skipCardTap = true,
              onTapCancel: () => _skipCardTap = false,
              onTap: canOpen ? _openCoverLetter : null,
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).accent,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.of(context).accent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCoverLetter() async {
    _skipCardTap = true;
    final path = application.coverLetterPath;
    if (path == null || path.isEmpty) return;

    final result = await openLocalFile(path);
    if (!mounted || result == OpenLocalFileResult.done) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == OpenLocalFileResult.missing
              ? AppStrings.coverLetterNotFound
              : AppStrings.coverLetterOpenFailed,
        ),
      ),
    );
  }

  TableRow _row(String label, String? value, {bool struck = false}) {
    final text = (value == null || value.isEmpty)
        ? AppStrings.emptyValue
        : value;
    final empty = text == AppStrings.emptyValue;
    final muted = AppColors.of(context).muted;
    final colors = AppColors.of(context);
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: struck ? muted : colors.secondary,
              fontSize: 13,
              decoration: struck ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: muted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: empty || struck ? muted : colors.text,
              decoration: struck ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: muted,
            ),
          ),
        ),
      ],
    );
  }
}
