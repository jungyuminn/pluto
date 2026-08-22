import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';

class DiaryPhotoField extends StatelessWidget {
  const DiaryPhotoField({
    super.key,
    required this.path,
    required this.onPicked,
    this.onCleared,
    this.accent,
  });

  final String? path;
  final ValueChanged<({String path, String name})> onPicked;
  final VoidCallback? onCleared;
  final Color? accent;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    final pickedPath = file?.path;
    if (file == null || pickedPath == null) return;
    onPicked((path: pickedPath, name: file.name));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (path == null || path!.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteDiaryPhotoDialog(),
    );
    if (confirmed == true) onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = accent ?? colors.accentBright;
    final photoPath = path;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;

    return PressBounce(
      onPressed: _pick,
      onLongPressed: hasPhoto ? () => _confirmDelete(context) : null,
      color: colors.card,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hasPhoto
            ? ColoredBox(
                color: colors.card,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                  ),
                  child: Image.file(
                    File(photoPath),
                    width: double.infinity,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => SizedBox(
                      height: 168,
                      width: double.infinity,
                      child: _EmptyPhoto(color: color),
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: 168,
                width: double.infinity,
                child: _EmptyPhoto(color: color),
              ),
      ),
    );
  }
}

class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.card,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              AppStrings.diaryPhotoHint,
              style: TextStyle(
                fontFamily: AppFonts.of(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteDiaryPhotoDialog extends StatelessWidget {
  const _DeleteDiaryPhotoDialog();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.deleteDiaryPhotoTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.deleteDiaryPhotoBody,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(false),
                  color: colors.border,
                  pressedColor: Color.lerp(colors.border, Colors.black, 0.12)!,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(true),
                  color: colors.danger,
                  pressedColor: Color.lerp(colors.danger, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.delete,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
