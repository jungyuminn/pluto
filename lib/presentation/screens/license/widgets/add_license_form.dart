import 'package:flutter/material.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_fonts.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/core/theme/app_theme.dart';
import 'package:pluto/core/utils/plain_text_editing_controller.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/presentation/screens/add_company/widgets/company_name_field.dart';
import 'package:pluto/presentation/screens/add_company/widgets/cover_letter_field.dart';
import 'package:pluto/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:pluto/presentation/screens/add_company/widgets/round_date_field.dart';
import 'package:pluto/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:pluto/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_category_chip.dart';
import 'package:pluto/presentation/screens/calendar/widgets/event_memo_field.dart';
import 'package:pluto/presentation/widgets/themed_asset.dart';

class AddLicenseForm extends StatefulWidget {
  const AddLicenseForm({super.key, this.initial});

  final License? initial;

  @override
  State<AddLicenseForm> createState() => _AddLicenseFormState();
}

class _AddLicenseFormState extends State<AddLicenseForm>
    with TickerProviderStateMixin {
  late final PlainTextEditingController _name;
  late final PlainTextEditingController _issuer;
  late final PlainTextEditingController _grade;
  late final PlainTextEditingController _number;
  late final PlainTextEditingController _memo;
  final _nameFocus = FocusNode();
  late final AnimationController _memoAnimation;
  late final CurvedAnimation _memoFade;
  late final AnimationController _fileAnimation;
  late final CurvedAnimation _fileFade;
  DateTime? _acquiredAt;
  DateTime? _expiresAt;
  String? _categoryId;
  String? _categoryName;
  int? _categoryColor;
  String? _filePath;
  String? _fileName;
  var _memoOpen = false;
  var _fileOpen = true;
  var _fileToggling = false;
  var _saving = false;

  bool get _isEditing => widget.initial != null;

  bool get _hasCategory =>
      (_categoryId?.isNotEmpty ?? false) &&
      (_categoryName?.trim().isNotEmpty ?? false);

  Color get _accent {
    final color = _categoryColor;
    if (color != null) return Color(color);
    return const Color(0xFF3B82F6);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = PlainTextEditingController(text: initial?.name ?? '');
    _issuer = PlainTextEditingController(text: initial?.issuer ?? '');
    _grade = PlainTextEditingController(text: initial?.grade ?? '');
    _number = PlainTextEditingController(text: initial?.number ?? '');
    _memo = PlainTextEditingController(text: initial?.memo ?? '');
    _acquiredAt = initial?.acquiredAt;
    _expiresAt = initial?.expiresAt;
    _categoryId = initial?.categoryId;
    _categoryName = initial?.hasCategory == true ? initial!.categoryName : null;
    _categoryColor = initial?.categoryColor;
    _filePath = initial?.filePath;
    _fileName = initial?.fileName;
    _memoOpen = (initial?.memo ?? '').isNotEmpty;
    _memoAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
      value: _memoOpen ? 1 : 0,
    );
    _memoFade = CurvedAnimation(
      parent: _memoAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fileAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      value: _fileOpen ? 1 : 0,
    );
    _fileFade = CurvedAnimation(
      parent: _fileAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (_isEditing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLastCategory();
    });
  }

  Future<void> _loadLastCategory() async {
    if (widget.initial != null) return;
    final scope = AppScope.of(context);
    final licenses = await scope.getLicenses();
    final categories = await scope.fetchCategories(CategoryKind.license);
    if (!mounted) return;
    EventCategory? last;
    License? newest;
    for (final license in licenses) {
      if (!license.hasCategory) continue;
      if (newest == null || license.id.compareTo(newest.id) >= 0) {
        newest = license;
      }
    }
    if (newest != null) {
      for (final category in categories) {
        if (category.id == newest.categoryId) {
          last = category;
          break;
        }
      }
    }
    last ??= categories.isNotEmpty
        ? categories.first
        : EventCategory.licensePresets.first;
    setState(() {
      _categoryId = last!.id;
      _categoryName = last.name;
      _categoryColor = last.color;
    });
  }

  @override
  void dispose() {
    _memoFade.dispose();
    _memoAnimation.dispose();
    _fileFade.dispose();
    _fileAnimation.dispose();
    _nameFocus.dispose();
    _name.dispose();
    _issuer.dispose();
    _grade.dispose();
    _number.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _toggleMemo() async {
    if (_memoOpen) {
      setState(() => _memoOpen = false);
      await _memoAnimation.reverse();
      return;
    }
    setState(() => _memoOpen = true);
    await _memoAnimation.forward();
  }

  Future<void> _toggleFile() async {
    if (_fileToggling) return;
    _fileToggling = true;
    if (_fileOpen) {
      setState(() => _fileOpen = false);
      await _fileAnimation.reverse();
    } else {
      setState(() => _fileOpen = true);
      await _fileAnimation.forward();
    }
    if (!mounted) return;
    _fileToggling = false;
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
      kind: CategoryKind.license,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _categoryId = picked.id;
      _categoryName = picked.name;
      _categoryColor = picked.color;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || !_hasCategory) {
      await showMissingFieldsDialog(
        context,
        body: AppStrings.missingLicenseBody,
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final initial = widget.initial;
    final license = License(
      id: initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      issuer: _issuer.text.trim(),
      grade: _grade.text.trim(),
      number: _number.text.trim(),
      acquiredAt: _acquiredAt,
      expiresAt: _expiresAt,
      memo: _memo.text.trim(),
      filePath: _filePath,
      fileName: _fileName,
      sortOrder: initial?.sortOrder ?? 0,
      categoryId: _categoryId,
      categoryName: _categoryName ?? '',
      categoryColor: _categoryColor,
    );
    final scope = AppScope.of(context);
    if (initial == null) {
      await scope.addLicense(license);
    } else {
      await scope.updateLicense(license);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  InputDecoration _fieldDecoration(
    AppColors colors,
    String? font,
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: font,
        color: colors.hint,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      filled: true,
      fillColor: colors.card.withValues(alpha: 0.55),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = _accent;
    final font = AppFonts.of(context);
    final fieldStyle = TextStyle(
      fontFamily: font,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );
    return AccentSelectionTheme(
      color: accent,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.tint(accent, 0.14),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CompanyNameField(
              controller: _name,
              focusNode: _nameFocus,
              autofocus: !_isEditing,
              hintText: AppStrings.licenseNameHint,
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _memoFade,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _memoFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: IgnorePointer(
                      ignoring: !_memoOpen,
                      child: EventMemoField(
                        controller: _memo,
                        hintText: AppStrings.eventMemoHint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        EventCategoryChip(
                          name: _categoryName ?? AppStrings.categoryAction,
                          color: _hasCategory ? accent : colors.muted,
                          selected: _hasCategory,
                          onPressed: _pickCategory,
                        ),
                        const SizedBox(width: 4),
                        RoundDateField(
                          date: _acquiredAt,
                          onPicked: (date) =>
                              setState(() => _acquiredAt = date),
                          color: accent,
                          filledIcon: true,
                          emptyLabel: AppStrings.licenseAcquired,
                        ),
                        const SizedBox(width: 4),
                        RoundDateField(
                          date: _expiresAt,
                          onPicked: (date) =>
                              setState(() => _expiresAt = date),
                          color: accent,
                          filledIcon: true,
                          emptyLabel: AppStrings.licenseExpires,
                        ),
                        const SizedBox(width: 4),
                        EventActionIcon(
                          label: AppStrings.memoAction,
                          color: accent,
                          selected: _memoOpen,
                          onPressed: _toggleMemo,
                          child: AppAssetImage(
                            asset: _memoOpen
                                ? AppIcons.memo
                                : AppIcons.memoOutlined,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        EventActionIcon(
                          label: AppStrings.attachLicenseFile,
                          color: accent,
                          selected: _fileOpen,
                          onPressed: _toggleFile,
                          child: AppAssetImage(
                            asset: _fileOpen
                                ? AppIcons.resume
                                : AppIcons.resumeOutlined,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SaveCompanyButton(
                  onPressed: _saving ? () {} : _save,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _issuer,
                    textInputAction: TextInputAction.next,
                    style: fieldStyle,
                    decoration: _fieldDecoration(
                      colors,
                      font,
                      AppStrings.licenseIssuerHint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: _grade,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                    style: fieldStyle,
                    decoration: _fieldDecoration(
                      colors,
                      font,
                      AppStrings.licenseGradeHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _number,
              textInputAction: TextInputAction.next,
              style: fieldStyle,
              decoration: _fieldDecoration(
                colors,
                font,
                AppStrings.licenseNumberHint,
              ),
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _fileFade,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _fileFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IgnorePointer(
                      ignoring: !_fileOpen,
                      child: CoverLetterField(
                        fileName: _fileName,
                        emptyLabel: AppStrings.attachLicenseFile,
                        deleteTitle: AppStrings.deleteLicenseFileTitle,
                        matchTextField: true,
                        allowedExtensions: const [
                          'pdf',
                          'png',
                          'jpg',
                          'jpeg',
                          'webp',
                          'heic',
                          'doc',
                          'docx',
                          'hwp',
                          'txt',
                        ],
                        onPicked: (file) {
                          setState(() {
                            _filePath = file?.path;
                            _fileName = file?.name;
                          });
                        },
                        onCleared: () {
                          setState(() {
                            _filePath = null;
                            _fileName = null;
                          });
                        },
                      ),
                    ),
                  ),
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
