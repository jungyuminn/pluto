import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/usecases/update_calendar_event.dart';

CalendarEvent pinSomedayCompleteToToday(CalendarEvent event) {
  if (!event.someday || event.isJob) return event;
  final markingDone = event.isShared ? !event.sharedMine : !event.completed;
  if (!markingDone) return event;
  final now = DateTime.now();
  return event.copyWith(
    date: DateTime(now.year, now.month, now.day),
    someday: false,
  );
}

Future<CalendarEvent> saveCompleteToggle({
  required UpdateCalendarEvent updater,
  required CalendarEvent event,
}) async {
  final source = pinSomedayCompleteToToday(event);
  final next = await FriendService.instance.toggleComplete(source);
  if (event.isRepeat || (event.isShared && !event.isRange)) {
    await updater.instance(next);
  } else {
    await updater(next);
  }
  return next;
}

String? sharedCompleteToast(CalendarEvent before, CalendarEvent next) {
  if (!next.isShared) return null;
  if (next.completed && !before.completed) {
    return AppStrings.friendsSharedTodoDone;
  }
  if (next.isSharedWaiting && !before.sharedMine) {
    return AppStrings.friendsSharedTodoWaiting;
  }
  return null;
}
