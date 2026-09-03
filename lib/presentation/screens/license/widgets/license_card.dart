import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/open_local_file.dart';
import 'package:job_planner/domain/entities/license.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/day_event_label.dart';

class LicenseCard extends StatefulWidget {
  const LicenseCard({
    super.key,
    required this.license,
    this.onPressed,
    this.onLongPressed,
    this.compact = false,
  });

  static const compactHeight = 56.0;

  final License license;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final bool compact;

  @override
  State<LicenseCard> createState() => _LicenseCardState();
}

class _LicenseCardState extends State<LicenseCard>
    with SingleTickerProviderStateMixin {
  var _skipCardTap = false;
  late final AnimationController _expand;
  late final CurvedAnimation _expandFade;

  License get license => widget.license;

  bool get _hasDetails {
    return license.issuer.trim().isNotEmpty ||
        license.acquiredAt != null ||
        license.expiresAt != null ||
        license.number.trim().isNotEmpty ||
        license.memo.trim().isNotEmpty ||
        (license.fileName?.trim() ?? '').isNotEmpty;
  }

  String _dateLabel(DateTime date) {
    return '${date.year}. ${date.month}. ${date.day}.';
  }

  Color get _categoryColor {
    return license.categoryColor != null
        ? Color(license.categoryColor!)
        : AppColors.of(context).accent;
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
  void didUpdateWidget(LicenseCard oldWidget) {
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
    final expired = license.isExpired();
    final category = license.categoryName.trim();
    final grade = license.grade.trim();
    return DayEventLabel(
      title: license.name,
      categoryName: category,
      color: accent,
      showCategory: license.hasCategory && category.isNotEmpty,
      trailing: grade.isEmpty ? null : _badge(grade),
      disabled: expired,
      showAccent: !expired,
      height: LicenseCard.compactHeight,
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
                      if (license.acquiredAt != null)
                        _row(
                          AppStrings.licenseAcquired,
                          _dateLabel(license.acquiredAt!),
                        ),
                      if (license.expiresAt != null)
                        _row(
                          AppStrings.licenseExpires,
                          _dateLabel(license.expiresAt!),
                          valueColor: expired
                              ? AppColors.of(context).danger
                              : null,
                        ),
                      if (license.issuer.trim().isNotEmpty)
                        _row(
                          AppStrings.licenseIssuerHint,
                          license.issuer.trim(),
                        ),
                      if (license.number.trim().isNotEmpty)
                        _row(
                          AppStrings.licenseNumberHint,
                          license.number.trim(),
                        ),
                      if (license.memo.trim().isNotEmpty)
                        _row(
                          AppStrings.memoAction,
                          license.memo.trim(),
                          valueColor: AppColors.of(context).muted,
                        ),
                      if ((license.fileName?.trim() ?? '').isNotEmpty)
                        _fileRow(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _badge(String text) {
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
            text,
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

  TableRow _row(String label, String value, {Color? valueColor}) {
    final colors = AppColors.of(context);
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              color: colors.secondary,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? colors.text,
            ),
          ),
        ),
      ],
    );
  }

  TableRow _fileRow() {
    final fileName = license.fileName?.trim() ?? '';
    final path = license.filePath?.trim() ?? '';
    final canOpen = path.isNotEmpty;
    final accent = _categoryColor;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: Text(
            AppStrings.attachLicenseFile,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
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
              onTap: canOpen ? _openFile : null,
              child: Text(
                fileName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.of(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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

  Future<void> _openFile() async {
    _skipCardTap = true;
    final path = license.filePath;
    if (path == null || path.isEmpty) return;

    final result = await openLocalFile(path);
    if (!mounted || result == OpenLocalFileResult.done) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == OpenLocalFileResult.missing
              ? AppStrings.licenseFileNotFound
              : AppStrings.coverLetterOpenFailed,
        ),
      ),
    );
  }
}
