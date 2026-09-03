import 'package:flutter/material.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_form.dart';

Future<bool> showAddEventSheet(
  BuildContext context, {
  required DateTime date,
  DateTime? rangeEnd,
  CalendarEvent? event,
  bool someday = false,
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
    builder: (context) => AddEventSheet(
      date: date,
      rangeEnd: rangeEnd,
      event: event,
      someday: someday,
    ),
  );
  return saved == true;
}

class AddEventSheet extends StatelessWidget {
  const AddEventSheet({
    super.key,
    required this.date,
    this.rangeEnd,
    this.event,
    this.someday = false,
  });

  final DateTime date;
  final DateTime? rangeEnd;
  final CalendarEvent? event;
  final bool someday;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        width: double.infinity,
        child: AddEventForm(
          date: date,
          rangeEnd: rangeEnd,
          initial: event,
          someday: someday,
        ),
      ),
    );
  }
}
