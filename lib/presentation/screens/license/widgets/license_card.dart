import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/open_local_file.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/domain/entities/license.dart';

class LicenseCard extends StatefulWidget {
  const LicenseCard({
    super.key,
    required this.license,
    this.onPressed,
    this.onLongPressed,
    this.compact = false,
  });

  final License license;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final bool compact;

  @override
  State<LicenseCard> createState() => _LicenseCardState();
}

class _LicenseCardState extends State<LicenseCard> {
  var _skipCardTap = false;

  License get license => widget.license;

  String _dateLabel(DateTime date) {
    return '${date.year}. ${date.month}. ${date.day}.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final font = AppFonts.of(context);
    final scale = AppFonts.todoScaleOf(context);
    final expired = license.isExpired();
    final issuer = license.issuer.trim();
    final grade = license.grade.trim();
    final number = license.number.trim();
    final memo = license.memo.trim();
    final fileName = license.fileName?.trim() ?? '';
    final acquired = license.acquiredAt;
    final expires = license.expiresAt;
    final compact = widget.compact;
    final accent = license.categoryColor != null
        ? Color(license.categoryColor!)
        : colors.accent;
    final hasTable = !compact &&
        (issuer.isNotEmpty ||
            acquired != null ||
            expires != null ||
            number.isNotEmpty ||
            memo.isNotEmpty ||
            fileName.isNotEmpty);

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
        color: expired ? colors.pressed : colors.card,
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
            opacity: expired ? 0.48 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _title(font, scale, accent)),
                    if (grade.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _pill(grade, colors.accent, font, scale),
                    ],
                    if (!compact && expired) ...[
                      const SizedBox(width: 8),
                      _pill(
                        AppStrings.licenseExpired,
                        colors.danger,
                        font,
                        scale,
                      ),
                    ],
                  ],
                ),
                if (hasTable)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.top,
                      children: [
                        if (acquired != null)
                          _row(
                            AppStrings.licenseAcquired,
                            _dateLabel(acquired),
                            colors,
                            font,
                            scale,
                          ),
                        if (expires != null)
                          _row(
                            AppStrings.licenseExpires,
                            _dateLabel(expires),
                            colors,
                            font,
                            scale,
                            valueColor: expired ? colors.danger : null,
                          ),
                        if (issuer.isNotEmpty)
                          _row(
                            AppStrings.licenseIssuerHint,
                            issuer,
                            colors,
                            font,
                            scale,
                          ),
                        if (number.isNotEmpty)
                          _row(
                            AppStrings.licenseNumberHint,
                            number,
                            colors,
                            font,
                            scale,
                          ),
                        if (memo.isNotEmpty)
                          _row(
                            AppStrings.memoAction,
                            memo,
                            colors,
                            font,
                            scale,
                            valueColor: colors.muted,
                            valueWeight: FontWeight.w600,
                          ),
                        if (fileName.isNotEmpty)
                          _fileRow(fileName, colors, font, scale),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(
    String? font,
    double scale,
    Color accent,
  ) {
    final category = license.categoryName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          license.name,
          style: TextStyle(
            fontFamily: font,
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (license.hasCategory && category.isNotEmpty)
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
                      fontFamily: font,
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

  Widget _pill(String text, Color color, String? font, double scale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: font,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  TableRow _row(
    String label,
    String value,
    AppColors colors,
    String? font,
    double scale, {
    Color? valueColor,
    FontWeight valueWeight = FontWeight.w600,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: font,
              color: colors.secondary,
              fontSize: 13 * scale,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: font,
              fontSize: 13 * scale,
              fontWeight: valueWeight,
              color: valueColor ?? colors.text,
            ),
          ),
        ),
      ],
    );
  }

  TableRow _fileRow(
    String fileName,
    AppColors colors,
    String? font,
    double scale,
  ) {
    final path = license.filePath?.trim() ?? '';
    final canOpen = path.isNotEmpty;
    final theme = colors.accent;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: Text(
            AppStrings.attachLicenseFile,
            style: TextStyle(
              fontFamily: font,
              color: colors.secondary,
              fontSize: 13 * scale,
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
                  fontFamily: font,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                  color: theme,
                  decoration: TextDecoration.underline,
                  decorationColor: theme,
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
