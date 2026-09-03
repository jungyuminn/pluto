import 'package:flutter/material.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/data/datasources/app_backup_service.dart';
import 'package:pluto/presentation/screens/settings/widgets/dots_loading_dialog.dart';

Future<T> showBackupLoading<T>(
  BuildContext context,
  Future<T> Function() task,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: const Color(0x4D000000),
    builder: (context) => const DotsLoadingDialog(),
  );
  try {
    return await task();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

Future<void> showBackupMessageDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => BackupMessageDialog(title: title, body: body),
  );
}

class BackupMessageDialog extends StatelessWidget {
  const BackupMessageDialog({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
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
            body,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          PressBounce(
            onPressed: () => Navigator.of(context).pop(),
            color: colors.accentBright,
            pressedColor: Color.lerp(colors.accentBright, Colors.black, 0.16)!,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  AppStrings.confirm,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showRestoreConfirmDialog(
  BuildContext context, {
  bool cloudWarning = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => RestoreConfirmDialog(cloudWarning: cloudWarning),
  );
  return confirmed == true;
}

class RestoreConfirmDialog extends StatelessWidget {
  const RestoreConfirmDialog({super.key, this.cloudWarning = false});

  final bool cloudWarning;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.restoreConfirmTitle,
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
            AppStrings.restoreConfirmBody,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          if (cloudWarning) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.restoreConfirmCloudBody,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
          ],
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
                  color: colors.accentBright,
                  pressedColor:
                      Color.lerp(colors.accentBright, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.restoreAction,
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

class RestoreChoice {
  const RestoreChoice.item(this.item) : pickOther = false;
  const RestoreChoice.other() : item = null, pickOther = true;

  final BackupListItem? item;
  final bool pickOther;
}

Future<RestoreChoice?> showRestoreSourceDialog(
  BuildContext context,
  List<BackupListItem> items, {
  bool pickOther = true,
  bool cloudWarning = false,
}) {
  return showDialog<RestoreChoice>(
    context: context,
    builder: (context) => RestoreSourceDialog(
      items: items,
      pickOther: pickOther,
      cloudWarning: cloudWarning,
    ),
  );
}

class RestoreSourceDialog extends StatefulWidget {
  const RestoreSourceDialog({
    super.key,
    required this.items,
    this.pickOther = true,
    this.cloudWarning = false,
  });

  final List<BackupListItem> items;
  final bool pickOther;
  final bool cloudWarning;

  @override
  State<RestoreSourceDialog> createState() => _RestoreSourceDialogState();
}

class _RestoreSourceDialogState extends State<RestoreSourceDialog> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        AppStrings.restoreConfirmTitle,
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
            AppStrings.restoreConfirmBody,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.secondary,
            ),
          ),
          if (widget.cloudWarning) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.restoreConfirmCloudBody,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < widget.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _BackupChoiceTile(
              label: widget.items[i].label,
              latest: i == 0,
              selected: _selected == i,
              onPressed: () => setState(() => _selected = i),
            ),
          ],
          if (widget.pickOther) ...[
            const SizedBox(height: 8),
            PressBounce(
              onPressed: () {
                Navigator.of(context).pop(const RestoreChoice.other());
              },
              pressedColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppStrings.restorePickOther,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.accentBright,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PressBounce(
                  onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: () => Navigator.of(context).pop(
                    RestoreChoice.item(widget.items[_selected]),
                  ),
                  color: colors.accentBright,
                  pressedColor:
                      Color.lerp(colors.accentBright, Colors.black, 0.16)!,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        AppStrings.restoreAction,
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

class _BackupChoiceTile extends StatelessWidget {
  const _BackupChoiceTile({
    required this.label,
    required this.latest,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool latest;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PressBounce(
      onPressed: onPressed,
      color: selected ? colors.selected : colors.groupedBackground,
      pressedColor: colors.pressed,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 22,
              color: selected ? colors.accentBright : colors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
            if (latest)
              Text(
                AppStrings.restoreLatest,
                style: TextStyle(
                  fontSize: 12,
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
