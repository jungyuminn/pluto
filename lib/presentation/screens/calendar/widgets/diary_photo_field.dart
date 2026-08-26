import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_fonts.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/press_bounce.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/diary_draw_sheet.dart';

class DiaryPhotoField extends StatefulWidget {
  const DiaryPhotoField({
    super.key,
    required this.path,
    required this.onPicked,
    this.onCleared,
  });

  final String? path;
  final ValueChanged<({String path, String name})> onPicked;
  final VoidCallback? onCleared;

  @override
  State<DiaryPhotoField> createState() => _DiaryPhotoFieldState();
}

class _DiaryPhotoFieldState extends State<DiaryPhotoField> {
  var _actionsOpen = false;

  static const _actionsAnim = Duration(milliseconds: 280);

  @override
  void didUpdateWidget(DiaryPhotoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _actionsOpen = false;
  }

  Future<void> _pick() async {
    setState(() => _actionsOpen = false);
    final file = await FilePicker.pickFile(type: FileType.image);
    final pickedPath = file?.path;
    if (file == null || pickedPath == null) return;
    widget.onPicked((path: pickedPath, name: file.name));
  }

  Future<void> _draw() async {
    setState(() => _actionsOpen = false);
    final result = await showDiaryDrawSheet(
      context,
      backgroundPath: widget.path,
    );
    if (!mounted) return;
    if (result == null) return;
    if (result.cleared) {
      widget.onCleared?.call();
      return;
    }
    final drawnPath = result.path;
    final name = result.name;
    if (drawnPath == null || name == null) return;
    widget.onPicked((path: drawnPath, name: name));
  }

  Future<void> _confirmDelete() async {
    final path = widget.path;
    if (path == null || path.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteDiaryPhotoDialog(),
    );
    if (confirmed == true && mounted) widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final photoPath = widget.path;
    if (photoPath != null && photoPath.isNotEmpty) {
      final drawing = DiaryPhotoSlot.isDrawingPath(photoPath);
      return Stack(
        children: [
          PressBounce(
            onPressed: () => setState(() => _actionsOpen = !_actionsOpen),
            onLongPressed: _confirmDelete,
            color: Colors.transparent,
            pressedColor: colors.pressed,
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: drawing
                  ? SizedBox(
                      height: DiaryPhotoSlot.height,
                      width: double.infinity,
                      child: Padding(
                        padding: DiaryPhotoSlot.imagePad,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(photoPath),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.expand(child: _EmptyPhoto()),
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: DiaryPhotoSlot.imagePad,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.sizeOf(context).height * 0.32,
                          ),
                          child: Image.file(
                            File(photoPath),
                            width: double.infinity,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: _EmptyPhoto(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned.fill(
            child: _ExistingPhotoActions(
              visible: _actionsOpen,
              drawing: drawing,
              onDismiss: () => setState(() => _actionsOpen = false),
              onChange: _pick,
              onDraw: _draw,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: DiaryPhotoSlot.height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            const Expanded(child: _EmptyPhoto()),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _PhotoChoice(
                      label: AppStrings.diaryPhotoPick,
                      onPressed: _pick,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PhotoChoice(
                      label: AppStrings.diaryPhotoDraw,
                      onPressed: _draw,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExistingPhotoActions extends StatelessWidget {
  const _ExistingPhotoActions({
    required this.visible,
    required this.drawing,
    required this.onDismiss,
    required this.onChange,
    required this.onDraw,
  });

  final bool visible;
  final bool drawing;
  final VoidCallback onDismiss;
  final VoidCallback onChange;
  final VoidCallback onDraw;

  static const _anim = _DiaryPhotoFieldState._actionsAnim;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: _anim,
        curve: Curves.easeOutCubic,
        opacity: visible ? 1 : 0,
        child: GestureDetector(
          onTap: onDismiss,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.32),
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: AnimatedSlide(
                  duration: _anim,
                  curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
                  offset: visible ? Offset.zero : const Offset(0, 0.28),
                  child: AnimatedScale(
                    duration: _anim,
                    curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
                    scale: visible ? 1 : 0.86,
                    child: GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Expanded(
                            child: _PhotoChoice(
                              label: AppStrings.diaryPhotoChange,
                              onPressed: onChange,
                              onPhoto: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PhotoChoice(
                              label: drawing
                                  ? AppStrings.diaryDrawEdit
                                  : AppStrings.diaryPhotoDrawOn,
                              onPressed: onDraw,
                              onPhoto: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoChoice extends StatelessWidget {
  const _PhotoChoice({
    required this.label,
    required this.onPressed,
    this.onPhoto = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final chip = PressBounce(
      onPressed: onPressed,
      color: onPhoto ? colors.card : colors.selected,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.of(context),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
        ),
      ),
    );
    if (!onPhoto) return chip;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: chip,
    );
  }
}

class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Text(
        AppStrings.diaryPhotoHint,
        style: TextStyle(
          fontFamily: AppFonts.of(context),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: colors.muted,
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
