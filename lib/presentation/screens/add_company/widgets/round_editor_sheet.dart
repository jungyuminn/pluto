import 'package:flutter/material.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/domain/entities/application_round.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_action_icon.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_date_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_name_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/round_note_field.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/theme/apply_status_colors.dart';

Future<ApplicationRound?> showRoundEditor(
  BuildContext context, {
  required String title,
  required ApplicationRound initial,
  required String applyStatus,
}) {
  return showModalBottomSheet<ApplicationRound>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x33000000),
    elevation: 0,
    builder: (context) => RoundEditorSheet(
      title: title,
      initial: initial,
      applyStatus: applyStatus,
    ),
  );
}

class RoundEditorSheet extends StatefulWidget {
  const RoundEditorSheet({
    super.key,
    required this.title,
    required this.initial,
    required this.applyStatus,
  });

  final String title;
  final ApplicationRound initial;
  final String applyStatus;

  @override
  State<RoundEditorSheet> createState() => _RoundEditorSheetState();
}

class _RoundEditorSheetState extends State<RoundEditorSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _name;
  late final TextEditingController _note;
  final _nameFocus = FocusNode();
  final _noteFocus = FocusNode();
  late final AnimationController _noteAnimation;
  late final CurvedAnimation _noteFade;
  DateTime? _date;
  late var _noteOpen = widget.initial.note.isNotEmpty;
  var _noteToggling = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name);
    _note = TextEditingController(text: widget.initial.note);
    _date = widget.initial.date;
    _noteAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
      value: _noteOpen ? 1 : 0,
    );
    _noteFade = CurvedAnimation(
      parent: _noteAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _noteFade.dispose();
    _noteAnimation.dispose();
    _nameFocus.dispose();
    _noteFocus.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _toggleNote() async {
    if (_noteToggling) return;
    _noteToggling = true;
    if (_noteOpen) {
      _nameFocus.requestFocus();
      await _noteAnimation.reverse();
      if (!mounted) return;
      setState(() => _noteOpen = false);
    } else {
      setState(() => _noteOpen = true);
      await _noteAnimation.forward();
      if (!mounted) return;
      _noteFocus.requestFocus();
    }
    _noteToggling = false;
  }

  void _save() {
    Navigator.of(context).pop(
      ApplicationRound(
        name: _name.text.trim(),
        date: _date,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final accent = ApplyStatusColors.of(widget.applyStatus) ??
        const Color(0xFF3B82F6);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Material(
        color: ApplyStatusColors.sheetOf(widget.applyStatus),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        shadowColor: const Color(0x33000000),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Semantics(
            label: widget.title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundNameField(
                  controller: _name,
                  focusNode: _nameFocus,
                ),
                ClipRect(
                  child: SizeTransition(
                    sizeFactor: _noteFade,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: _noteFade,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: IgnorePointer(
                          ignoring: !_noteOpen,
                          child: RoundNoteField(
                            controller: _note,
                            focusNode: _noteFocus,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (_date != null)
                      Flexible(
                        child: RoundDateField(
                          date: _date,
                          color: accent,
                          onPicked: (value) => setState(() => _date = value),
                        ),
                      )
                    else
                      RoundDateField(
                        date: _date,
                        color: accent,
                        onPicked: (value) => setState(() => _date = value),
                      ),
                    RoundActionIcon(
                      asset: AppIcons.memo,
                      onPressed: _toggleNote,
                    ),
                    const Spacer(),
                    SaveCompanyButton(onPressed: _save, color: accent),
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
