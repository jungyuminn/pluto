import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/domain/entities/apply_status.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/domain/entities/event_category.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_picker.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/company_name_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/cover_letter_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_memo_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_chip_row.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/category_picker_sheet.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_action_icon.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/event_category_chip.dart';

class AddCompanyForm extends StatefulWidget {
  const AddCompanyForm({super.key, this.initial});

  final JobApplication? initial;

  @override
  State<AddCompanyForm> createState() => _AddCompanyFormViewState();
}

class _AddCompanyFormViewState extends State<AddCompanyForm>
    with TickerProviderStateMixin {
  late final PlainTextEditingController _companyName;
  final _companyNameFocus = FocusNode();
  late final PlainTextEditingController _position;
  final _positionFocus = FocusNode();
  late final AnimationController _positionAnimation;
  late final CurvedAnimation _positionFade;
  late final AnimationController _roundsAnimation;
  late final CurvedAnimation _roundsFade;
  late final AnimationController _coverLetterAnimation;
  late final CurvedAnimation _coverLetterFade;

  late var _applyStatusChipValue = ApplyStatus.documentSubmitted;
  late List<ApplicationRound> _rounds;
  String? _coverLetterPath;
  String? _coverLetterFileName;
  String? _categoryId;
  String? _categoryName;
  int? _categoryColor;
  var _positionOpen = true;
  var _roundsOpen = true;
  var _coverLetterOpen = true;
  var _positionToggling = false;
  var _roundsToggling = false;
  var _coverLetterToggling = false;
  var _saving = false;
  Animation<double>? _sheetAnimation;

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
    _companyName = PlainTextEditingController(text: initial?.companyName ?? '');
    _position = PlainTextEditingController(text: initial?.position ?? '');
    _positionAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      value: _positionOpen ? 1 : 0,
    );
    _positionFade = CurvedAnimation(
      parent: _positionAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _applyStatusChipValue = (initial?.applyStatus.isNotEmpty ?? false)
        ? initial!.applyStatus
        : ApplyStatus.documentSubmitted;
    _rounds = [...JobApplication.normalizeRounds(initial?.rounds)];
    _roundsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      value: _roundsOpen ? 1 : 0,
    );
    _roundsFade = CurvedAnimation(
      parent: _roundsAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _coverLetterAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      value: _coverLetterOpen ? 1 : 0,
    );
    _coverLetterFade = CurvedAnimation(
      parent: _coverLetterAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _coverLetterPath = initial?.coverLetterPath;
    _coverLetterFileName = initial?.coverLetterFileName;
    _categoryId = initial?.categoryId;
    _categoryName = initial?.hasCategory == true ? initial!.categoryName : null;
    _categoryColor = initial?.categoryColor;

    if (_isEditing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sheetAnimation = ModalRoute.of(context)?.animation;
      final animation = _sheetAnimation;
      if (animation == null || animation.isCompleted) {
        _companyNameFocus.requestFocus();
      } else {
        animation.addStatusListener(_onSheetOpened);
      }
      _loadLastCategory();
    });
  }

  void _onSheetOpened(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    if (mounted) _companyNameFocus.requestFocus();
  }

  Future<void> _loadLastCategory() async {
    if (widget.initial != null) return;
    final scope = AppScope.of(context);
    final jobs = await scope.getJobApplications();
    final categories = await scope.fetchCategories(CategoryKind.company);
    if (!mounted) return;

    EventCategory? last;
    JobApplication? newest;
    for (final job in jobs) {
      if (!job.hasCategory) continue;
      if (newest == null || job.id.compareTo(newest.id) >= 0) newest = job;
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
        : EventCategory.companyPresets.first;
    final selected = last;

    if (_categoryId == selected.id &&
        _categoryName == selected.name &&
        _categoryColor == selected.color) {
      return;
    }
    setState(() {
      _categoryId = selected.id;
      _categoryName = selected.name;
      _categoryColor = selected.color;
    });
  }

  @override
  void dispose() {
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    _positionFade.dispose();
    _positionAnimation.dispose();
    _roundsFade.dispose();
    _roundsAnimation.dispose();
    _coverLetterFade.dispose();
    _coverLetterAnimation.dispose();
    _companyNameFocus.dispose();
    _positionFocus.dispose();
    _companyName.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _companyName.text.trim();
    if (name.isEmpty || !_hasCategory) {
      await showMissingFieldsDialog(context);
      return;
    }
    if (_saving) return;

    setState(() => _saving = true);
    final initial = widget.initial;
    final application = JobApplication(
      id: initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      companyName: name,
      applyStatus: _applyStatusChipValue,
      position: _position.text.trim(),
      appliedDate: initial?.appliedDate,
      deadline: initial?.deadline,
      rounds: _rounds,
      status: initial?.status ?? '',
      coverLetterPath: _coverLetterPath,
      coverLetterFileName: _coverLetterFileName,
      sortOrder: initial?.sortOrder ?? 0,
      categoryId: _hasCategory ? _categoryId : null,
      categoryName: _hasCategory ? (_categoryName ?? '') : '',
      categoryColor: _hasCategory ? _categoryColor : null,
    );

    final scope = AppScope.of(context);
    if (initial == null) {
      await scope.addJobApplication(application);
    } else {
      await scope.updateJobApplication(application);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
      kind: CategoryKind.company,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _categoryId = picked.id;
      _categoryName = picked.name;
      _categoryColor = picked.color;
    });
  }

  Future<void> _togglePosition() async {
    if (_positionToggling) return;
    _positionToggling = true;
    if (_positionOpen) {
      _companyNameFocus.requestFocus();
      setState(() => _positionOpen = false);
      await _positionAnimation.reverse();
    } else {
      setState(() => _positionOpen = true);
      await _positionAnimation.forward();
      if (!mounted) return;
      _positionFocus.requestFocus();
    }
    if (!mounted) return;
    _positionToggling = false;
  }

  Future<void> _toggleRounds() async {
    if (_roundsToggling) return;
    _roundsToggling = true;
    if (_roundsOpen) {
      setState(() => _roundsOpen = false);
      await _roundsAnimation.reverse();
    } else {
      setState(() => _roundsOpen = true);
      await _roundsAnimation.forward();
    }
    if (!mounted) return;
    _roundsToggling = false;
  }

  Future<void> _toggleCoverLetter() async {
    if (_coverLetterToggling) return;
    _coverLetterToggling = true;
    if (_coverLetterOpen) {
      setState(() => _coverLetterOpen = false);
      await _coverLetterAnimation.reverse();
    } else {
      setState(() => _coverLetterOpen = true);
      await _coverLetterAnimation.forward();
    }
    if (!mounted) return;
    _coverLetterToggling = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.of(context).tint(_accent, 0.14),
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
              controller: _companyName,
              focusNode: _companyNameFocus,
              autofocus: !_isEditing,
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _positionFade,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _positionFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: IgnorePointer(
                      ignoring: !_positionOpen,
                      child: EventMemoField(
                        controller: _position,
                        focusNode: _positionFocus,
                        hintText: AppStrings.positionHint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        EventCategoryChip(
                          name: _categoryName ?? AppStrings.categoryAction,
                          color: _hasCategory
                              ? _accent
                              : AppColors.of(context).muted,
                          selected: _hasCategory,
                          onPressed: _pickCategory,
                        ),
                        const SizedBox(width: 4),
                        EventActionIcon(
                          label: AppStrings.roundAction,
                          color: _accent,
                          selected: _roundsOpen,
                          onPressed: _toggleRounds,
                          child: Image.asset(
                            _roundsOpen
                                ? AppIcons.calendar
                                : AppIcons.calendarOutlined,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        EventActionIcon(
                          label: AppStrings.colPosition,
                          color: _accent,
                          selected: _positionOpen,
                          onPressed: _togglePosition,
                          child: Image.asset(
                            _positionOpen
                                ? AppIcons.memo
                                : AppIcons.memoOutlined,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        EventActionIcon(
                          label: AppStrings.colCoverLetter,
                          color: _accent,
                          selected: _coverLetterOpen,
                          onPressed: _toggleCoverLetter,
                          child: Image.asset(
                            _coverLetterOpen
                                ? AppIcons.resume
                                : AppIcons.resumeOutlined,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ApplyStatusPicker(
                          value: _applyStatusChipValue,
                          options: ApplyStatus.values,
                          color: _accent,
                          onChanged: (value) =>
                              setState(() => _applyStatusChipValue = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SaveCompanyButton(
                  onPressed: _saving ? () {} : _save,
                  color: _accent,
                ),
              ],
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _roundsFade,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _roundsFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IgnorePointer(
                      ignoring: !_roundsOpen,
                      child: RoundChipRow(
                        rounds: _rounds,
                        accent: _accent,
                        onRoundChanged: (index, round) {
                          setState(() => _rounds[index] = round);
                        },
                        onReordered: (rounds) {
                          setState(() => _rounds = rounds);
                        },
                        onAddRound: () {
                          if (_rounds.length >= JobApplication.maxRoundCount) {
                            return;
                          }
                          setState(
                            () => _rounds = [
                              ..._rounds,
                              const ApplicationRound(),
                            ],
                          );
                        },
                        onRemoveRound: () {
                          if (_rounds.length <= JobApplication.minRoundCount) {
                            return;
                          }
                          setState(
                            () => _rounds = _rounds.sublist(0, _rounds.length - 1),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _coverLetterFade,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _coverLetterFade,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IgnorePointer(
                      ignoring: !_coverLetterOpen,
                      child: CoverLetterField(
                        fileName: _coverLetterFileName,
                        onPicked: (file) {
                          setState(() {
                            _coverLetterPath = file?.path;
                            _coverLetterFileName = file?.name;
                          });
                        },
                        onCleared: () {
                          setState(() {
                            _coverLetterPath = null;
                            _coverLetterFileName = null;
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
    );
  }
}
