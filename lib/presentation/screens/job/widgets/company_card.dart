import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/open_local_file.dart';
import 'package:pluto/domain/entities/application_round.dart';
import 'package:pluto/domain/entities/apply_status.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/presentation/screens/calendar/widgets/day_event_label.dart';

class CompanyCard extends StatefulWidget {
  const CompanyCard({
    super.key,
    required this.application,
    this.onPressed,
    this.onLongPressed,
    this.compact = false,
  });

  static const compactHeight = 56.0;

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
    final accent = _categoryColor;
    final rejected = ApplyStatus.isRejected(application.applyStatus);
    final category = application.categoryName.trim();
    final position = application.position.trim();
    final status = application.applyStatus.trim();
    final dDay = rejected ? null : application.upcomingDDay();
    return DayEventLabel(
      title: application.companyName,
      categoryName: category,
      color: accent,
      memo: position,
      showCategory: application.hasCategory && category.isNotEmpty,
      overline: dDay == null ? null : (dDay == 0 ? 'D-Day' : 'D-$dDay'),
      overlineColor: AppColors.of(context).danger,
      trailing: status.isEmpty ? null : _statusBadge(status),
      disabled: rejected,
      showAccent: !rejected && !application.allSchedulesPast,
      height: CompanyCard.compactHeight,
      onPressed: () {
        if (_skipCardTap) {
          _skipCardTap = false;
          return;
        }
        widget.onPressed?.call();
      },
      onLongPressed: widget.onLongPressed,
      footer: !_hasDetails
          ? null
          : SizeTransition(
              sizeFactor: _expandFade,
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: _expandFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 12, 10),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    children: [
                      for (final round in application.rounds)
                        if (!round.isEmpty) _round(round),
                      if (_hasCoverLetter) _coverLetterRow(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  TableRow _round(ApplicationRound round) {
    final date = round.date;
    final title = date == null
        ? AppStrings.emptyValue
        : '${date.month}. ${date.day}.';
    final name = round.name.trim();
    final note = round.note.trim();
    final value = name.isEmpty
        ? (note.isEmpty ? null : note)
        : (note.isEmpty ? name : '$name ($note)');
    return _row(title, value, struck: round.isPast());
  }

  Color get _categoryColor {
    return application.categoryColor != null
        ? Color(application.categoryColor!)
        : AppColors.of(context).accent;
  }

  Widget _statusBadge(String status) {
    final color = _categoryColor;
    final scale = AppFonts.labelScaleOf(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            status,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 11 * scale,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.2,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  TableRow _coverLetterRow() {
    final fileName = application.coverLetterFileName?.trim() ?? '';
    final path = application.coverLetterPath?.trim() ?? '';
    final canOpen = fileName.isNotEmpty && path.isNotEmpty;
    final accent = _categoryColor;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: Text(
            AppStrings.colCoverLetter,
            style: TextStyle(
              color: AppColors.of(context).secondary,
              fontSize: 13,
            ),
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
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  decoration: TextDecoration.underline,
                  decorationColor: accent,
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
    final text = (value == null || value.isEmpty) ? AppStrings.emptyValue : value;
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
              decoration: struck
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: muted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: empty || struck ? muted : colors.text,
              decoration: struck
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: muted,
            ),
          ),
        ),
      ],
    );
  }
}
