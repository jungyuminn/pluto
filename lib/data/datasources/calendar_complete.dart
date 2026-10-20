import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/usecases/update_calendar_event.dart';
import 'package:pluto/domain/usecases/update_job_application.dart';

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

final _toggleChain = <String, Future<CalendarEvent>>{};

String _toggleKey(CalendarEvent event) {
  final sharedId = event.sharedId?.trim() ?? '';
  if (sharedId.isNotEmpty) return '$sharedId:${event.day}';
  if (event.isRepeat) return '${event.repeatId}:${event.day}';
  return event.id;
}

Future<CalendarEvent> saveCompleteToggle({
  required UpdateCalendarEvent updater,
  required CalendarEvent event,
}) {
  final key = _toggleKey(event);
  final previous = _toggleChain[key];
  late final Future<CalendarEvent> run;
  run = _writeCompleteToggle(
    updater: updater,
    event: event,
    previous: previous,
  );
  _toggleChain[key] = run;
  return run.whenComplete(() {
    if (identical(_toggleChain[key], run)) _toggleChain.remove(key);
  });
}

Future<CalendarEvent> _writeCompleteToggle({
  required UpdateCalendarEvent updater,
  required CalendarEvent event,
  required Future<CalendarEvent>? previous,
}) async {
  var source = event;
  if (previous != null) {
    try {
      source = await previous;
    } catch (_) {}
  }
  source = pinSomedayCompleteToToday(source);
  final next = await FriendService.instance.toggleComplete(source);
  if (source.isRepeat || (source.isShared && !source.isRange)) {
    await updater.instance(next);
  } else {
    await updater(next);
  }
  return next;
}

int? jobRoundIndexOf(CalendarEvent event) {
  final appId = event.jobApplicationId;
  if (appId == null || appId.isEmpty) return null;
  final prefix = 'job:$appId:';
  if (!event.id.startsWith(prefix)) return null;
  return int.tryParse(event.id.substring(prefix.length));
}

Future<CalendarEvent> saveJobCompleteToggle({
  required Future<List<JobApplication>> Function() getApplications,
  required UpdateJobApplication updater,
  required CalendarEvent event,
}) {
  final key = _toggleKey(event);
  final previous = _toggleChain[key];
  late final Future<CalendarEvent> run;
  run = _writeJobCompleteToggle(
    getApplications: getApplications,
    updater: updater,
    event: event,
    previous: previous,
  );
  _toggleChain[key] = run;
  return run.whenComplete(() {
    if (identical(_toggleChain[key], run)) _toggleChain.remove(key);
  });
}

Future<CalendarEvent> _writeJobCompleteToggle({
  required Future<List<JobApplication>> Function() getApplications,
  required UpdateJobApplication updater,
  required CalendarEvent event,
  required Future<CalendarEvent>? previous,
}) async {
  if (previous != null) {
    try {
      await previous;
    } catch (_) {}
  }
  final appId = event.jobApplicationId;
  final index = jobRoundIndexOf(event);
  if (appId == null || index == null) {
    return event.copyWith(completed: !event.completed);
  }
  final applications = await getApplications();
  JobApplication? application;
  for (final item in applications) {
    if (item.id == appId) {
      application = item;
      break;
    }
  }
  if (application == null ||
      index < 0 ||
      index >= application.rounds.length) {
    return event.copyWith(completed: !event.completed);
  }
  final rounds = [...application.rounds];
  final round = rounds[index];
  final nextCompleted = !round.completed;
  rounds[index] = round.copyWith(completed: nextCompleted);
  await updater(application.copyWith(rounds: rounds));
  return event.copyWith(completed: nextCompleted);
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
