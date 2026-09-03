import 'package:pluto/domain/entities/calendar_event.dart';

abstract class CalendarEventRepository {
  Future<List<CalendarEvent>> getAll();
  Future<void> add(CalendarEvent event);
  Future<void> addAll(List<CalendarEvent> events);
  Future<void> update(CalendarEvent event);
  Future<void> delete(String id);
  Future<void> deleteMany(Iterable<String> ids);
  Future<void> deleteGroup(String groupId);
  Future<void> updateGroup(String groupId, CalendarEvent patch);
  Future<void> updateRepeatTitles(String repeatId, String title);
  Future<void> deleteRepeat(String repeatId);
  Future<void> deleteRepeatFrom(String repeatId, DateTime from);
  Future<void> replaceAll(List<CalendarEvent> events);
}
