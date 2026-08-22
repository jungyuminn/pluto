import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/diary_entry.dart';
import 'package:job_planner/presentation/screens/calendar/widgets/diary_form.dart';

Future<bool> showDiarySheet(
  BuildContext context, {
  required DateTime date,
  DiaryEntry? initial,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DiarySheet(
      date: date,
      initial: initial,
    ),
  );
  return saved == true;
}

class DiarySheet extends StatelessWidget {
  const DiarySheet({
    super.key,
    required this.date,
    this.initial,
  });

  final DateTime date;
  final DiaryEntry? initial;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DiaryForm(
            date: date,
            initial: initial,
          ),
        ),
      ),
    );
  }
}
