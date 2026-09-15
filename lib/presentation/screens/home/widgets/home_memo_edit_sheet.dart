import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/core/utils/press_bounce.dart';
import 'package:pluto/domain/entities/home_memo.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/delete_event_dialog.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_memo_field.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

Future<bool> showHomeMemoEditSheet(
  BuildContext context, {
  HomeMemo? initial,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => HomeMemoEditSheet(initial: initial),
  );
  return saved == true;
}

class HomeMemoEditSheet extends StatefulWidget {
  const HomeMemoEditSheet({super.key, this.initial});

  final HomeMemo? initial;

  @override
  State<HomeMemoEditSheet> createState() => _HomeMemoEditSheetState();
}

class _HomeMemoEditSheetState extends State<HomeMemoEditSheet> {
  late final PlainTextEditingController _title;
  late final PlainTextEditingController _body;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _title = PlainTextEditingController(text: widget.initial?.title ?? '');
    _body = PlainTextEditingController(text: widget.initial?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.memoMissingTitle,
      );
      return;
    }
    _saving = true;
    final initial = widget.initial;
    final store = AppScope.of(context).memoStore;
    final memo = HomeMemo(
      id: initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: _body.text.trim(),
      sortOrder: initial?.sortOrder ?? store.memos.length,
    );
    await store.upsert(memo);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final initial = widget.initial;
    if (initial == null) return;
    final confirmed = await showDeleteEventDialog(
      context,
      title: initial.title,
      body: AppStrings.memoDeleteBody,
    );
    if (!confirmed || !mounted) return;
    await AppScope.of(context).memoStore.delete(initial.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = colors.accent;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final font = AppFonts.of(context);
    return AccentSelectionTheme(
      color: accent,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontFamily: font,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: colors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.memoTitleHint,
                    hintStyle: TextStyle(
                      fontFamily: font,
                      color: colors.hint,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 12),
                EventMemoField(
                  controller: _body,
                  hintText: AppStrings.memoBodyHint,
                  minLines: 4,
                  maxLines: 12,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Spacer(),
                    if (widget.initial != null) ...[
                      _DeleteMemoButton(onPressed: _saving ? null : _delete),
                      const SizedBox(width: 8),
                    ],
                    SaveCompanyButton(
                      onPressed: _saving ? () {} : _save,
                      color: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteMemoButton extends StatelessWidget {
  const _DeleteMemoButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressBounce(
        onPressed: onPressed,
        color: colors.card,
        pressedColor: colors.pressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: SaveCompanyButton.size,
          height: SaveCompanyButton.size,
          child: Center(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(colors.danger, BlendMode.srcIn),
              child: AppAssetImage(
                asset: AppIcons.trashCan,
                width: 22,
                height: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
