import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/core/utils/plain_text_editing_controller.dart';
import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/domain/entities/apply_status.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/apply_status_picker.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/company_name_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/cover_letter_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/missing_fields_dialog.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/position_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_chip_row.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/presentation/theme/apply_status_colors.dart';

class AddCompanyForm extends StatefulWidget {
  const AddCompanyForm({super.key, this.initial});

  final JobApplication? initial;

  @override
  State<AddCompanyForm> createState() => _AddCompanyFormViewState();
}

class _AddCompanyFormViewState extends State<AddCompanyForm> {
  late final PlainTextEditingController _companyName;
  final _companyNameFocus = FocusNode();
  late final PlainTextEditingController _position;

  late var _applyStatusChipValue = ApplyStatus.documentSubmitted;
  late final List<ApplicationRound> _rounds;
  String? _coverLetterPath;
  String? _coverLetterFileName;
  var _saving = false;
  Animation<double>? _sheetAnimation;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _companyName = PlainTextEditingController(text: initial?.companyName ?? '');
    _position = PlainTextEditingController(text: initial?.position ?? '');
    _applyStatusChipValue = (initial?.applyStatus.isNotEmpty ?? false)
        ? initial!.applyStatus
        : ApplyStatus.documentSubmitted;
    _rounds = [...JobApplication.normalizeRounds(initial?.rounds)];
    _coverLetterPath = initial?.coverLetterPath;
    _coverLetterFileName = initial?.coverLetterFileName;

    if (_isEditing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sheetAnimation = ModalRoute.of(context)?.animation;
      final animation = _sheetAnimation;
      if (animation == null || animation.isCompleted) {
        _companyNameFocus.requestFocus();
        return;
      }
      animation.addStatusListener(_onSheetOpened);
    });
  }

  void _onSheetOpened(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    if (mounted) _companyNameFocus.requestFocus();
  }

  @override
  void dispose() {
    _sheetAnimation?.removeStatusListener(_onSheetOpened);
    _companyNameFocus.dispose();
    _companyName.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _companyName.text.trim();
    final position = _position.text.trim();
    if (name.isEmpty || position.isEmpty) {
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
      position: position,
      appliedDate: initial?.appliedDate,
      deadline: initial?.deadline,
      rounds: _rounds,
      status: initial?.status ?? '',
      coverLetterPath: _coverLetterPath,
      coverLetterFileName: _coverLetterFileName,
      sortOrder: initial?.sortOrder ?? 0,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ApplyStatusColors.sheetOf(
          _applyStatusChipValue,
          base: AppColors.of(context).card,
        ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CompanyNameField(
                    controller: _companyName,
                    focusNode: _companyNameFocus,
                    autofocus: !_isEditing,
                  ),
                ),
                const SizedBox(width: 8),
                ApplyStatusPicker(
                  value: _applyStatusChipValue,
                  options: ApplyStatus.values,
                  onChanged: (value) =>
                      setState(() => _applyStatusChipValue = value),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PositionField(controller: _position),
            const SizedBox(height: 12),
            RoundChipRow(
              rounds: _rounds,
              applyStatus: _applyStatusChipValue,
              onRoundChanged: (index, round) {
                setState(() => _rounds[index] = round);
              },
              onAddRound: () {
                if (_rounds.length >= JobApplication.maxRoundCount) return;
                setState(() => _rounds.add(const ApplicationRound()));
              },
              onRemoveRound: () {
                if (_rounds.length <= JobApplication.minRoundCount) return;
                setState(() => _rounds.removeLast());
              },
            ),
            const SizedBox(height: 20),
            const Text(
              AppStrings.colCoverLetter,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                SaveCompanyButton(
                  onPressed: _saving ? () {} : _save,
                  color: ApplyStatusColors.of(_applyStatusChipValue) ??
                      const Color(0xFF3B82F6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
