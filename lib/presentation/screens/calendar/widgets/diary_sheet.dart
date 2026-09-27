import 'package:flutter/material.dart';
import 'package:pluto/core/layout/compose_sheet.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/presentation/screens/calendar/widgets/diary_form.dart';

Future<bool> showDiarySheet(
  BuildContext context, {
  required DateTime date,
  DateTime? rangeEnd,
  DiaryEntry? initial,
}) async {
  final saved = await showComposeSheet<bool>(
    context,
    maxWidth: PcLayout.pcDiaryWidth,
    builder: (context) => DiarySheet(
      date: date,
      rangeEnd: rangeEnd,
      initial: initial,
    ),
  );
  return saved == true;
}

class DiarySheet extends StatelessWidget {
  const DiarySheet({
    super.key,
    required this.date,
    this.rangeEnd,
    this.initial,
  });

  final DateTime date;
  final DateTime? rangeEnd;
  final DiaryEntry? initial;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DiaryForm(
          date: date,
          rangeEnd: rangeEnd,
          initial: initial,
        ),
      ),
    );
  }
}
