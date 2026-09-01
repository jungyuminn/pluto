import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/delete_cover_letter_dialog.dart';

class CoverLetterField extends StatelessWidget {
  const CoverLetterField({
    super.key,
    required this.fileName,
    required this.onPicked,
    this.onCleared,
    this.emptyLabel = AppStrings.attachFile,
    this.deleteTitle = AppStrings.deleteCoverLetterTitle,
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'hwp', 'txt'],
    this.matchTextField = false,
  });

  final String? fileName;
  final ValueChanged<({String path, String name})?> onPicked;
  final VoidCallback? onCleared;
  final String emptyLabel;
  final String deleteTitle;
  final List<String> allowedExtensions;
  final bool matchTextField;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    final path = file?.path;
    if (file == null || path == null) return;
    onPicked((path: path, name: file.name));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final name = fileName?.trim() ?? '';
    if (name.isEmpty) return;
    final confirmed = await showDeleteCoverLetterDialog(
      context,
      fileName: name,
      title: deleteTitle,
    );
    if (confirmed) onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasFile = fileName != null && fileName!.isNotEmpty;
    final fill = matchTextField
        ? colors.card.withValues(alpha: 0.55)
        : colors.card;
    final labelColor = hasFile
        ? colors.text
        : (matchTextField ? colors.hint : colors.muted);
    final iconColor = matchTextField
        ? (hasFile ? colors.text : colors.hint)
        : colors.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: matchTextField ? null : Border.all(color: colors.border),
      ),
      child: PressBounce(
        onPressed: _pick,
        onLongPressed: hasFile ? () => _confirmDelete(context) : null,
        color: fill,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: matchTextField ? 10 : 16,
          ),
          child: Row(
            children: [
              Icon(
                hasFile ? Icons.description_outlined : Icons.attach_file,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasFile ? fileName! : emptyLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: matchTextField ? AppFonts.of(context) : null,
                    fontWeight: matchTextField ? FontWeight.w600 : FontWeight.w700,
                    fontSize: matchTextField ? 16 : null,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
