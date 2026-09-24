import 'package:flutter/material.dart';
import 'package:pluto/core/layout/compose_sheet.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/presentation/screens/calendar/widgets/add_event_form.dart';
import 'package:pluto/presentation/tutorial/tutorial_controller.dart';

Future<bool> showAddEventSheet(
  BuildContext context, {
  required DateTime date,
  DateTime? rangeEnd,
  CalendarEvent? event,
  bool someday = false,
  FriendProfile? shareWith,
}) async {
  final tutorial = TutorialController.find(context);
  tutorial?.noteAddOpened();
  final saved = await showComposeSheet<bool>(
    context,
    builder: (context) => AddEventSheet(
      date: date,
      rangeEnd: rangeEnd,
      event: event,
      someday: someday,
      shareWith: shareWith,
    ),
  );
  tutorial?.noteAddClosed(saved: saved == true);
  return saved == true;
}

class AddEventSheet extends StatelessWidget {
  const AddEventSheet({
    super.key,
    required this.date,
    this.rangeEnd,
    this.event,
    this.someday = false,
    this.shareWith,
  });

  final DateTime date;
  final DateTime? rangeEnd;
  final CalendarEvent? event;
  final bool someday;
  final FriendProfile? shareWith;

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
          shareWith: shareWith,
        ),
      ),
    );
  }
}
