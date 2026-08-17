import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/delete_cover_letter_dialog.dart';

class CoverLetterField extends StatelessWidget {
  const CoverLetterField({
    super.key,
    required this.fileName,
    required this.onPicked,
    this.onCleared,
  });

  final String? fileName;
  final ValueChanged<({String path, String name})?> onPicked;
  final VoidCallback? onCleared;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'hwp', 'txt'],
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
    );
    if (confirmed) onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: PressBounce(
        onPressed: _pick,
        onLongPressed: hasFile ? () => _confirmDelete(context) : null,
        color: Colors.white,
        pressedColor: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Icon(
                hasFile ? Icons.description_outlined : Icons.attach_file,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasFile ? fileName! : AppStrings.attachFile,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: hasFile
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
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
