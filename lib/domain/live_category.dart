import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/diary_entry.dart';
import 'package:pluto/domain/entities/event_category.dart';
import 'package:pluto/domain/entities/job_application.dart';
import 'package:pluto/domain/entities/ledger_entry.dart';
import 'package:pluto/domain/entities/license.dart';

class LiveCategory {
  const LiveCategory._();

  static CalendarEvent event(
    CalendarEvent item,
    Iterable<EventCategory> categories,
  ) {
    final found = EventCategory.lookup(
      categories,
      id: item.categoryId,
      name: item.categoryName,
    );
    if (found == null) return item;
    if (found.id == item.categoryId &&
        found.name == item.categoryName &&
        found.color == item.categoryColor) {
      return item;
    }
    return item.copyWith(
      categoryId: found.id,
      categoryName: found.name,
      categoryColor: found.color,
    );
  }

  static DiaryEntry diary(
    DiaryEntry item,
    Iterable<EventCategory> categories,
  ) {
    final found = EventCategory.lookup(
      categories,
      id: item.categoryId,
      name: item.categoryName,
    );
    if (found == null) return item;
    if (found.id == item.categoryId &&
        found.name == item.categoryName &&
        found.color == item.categoryColor) {
      return item;
    }
    return item.copyWith(
      categoryId: found.id,
      categoryName: found.name,
      categoryColor: found.color,
    );
  }

  static LedgerEntry ledger(
    LedgerEntry item,
    Iterable<EventCategory> categories,
  ) {
    final found = EventCategory.lookup(
      categories,
      id: item.categoryId,
      name: item.categoryName,
    );
    if (found == null) return item;
    if (found.id == item.categoryId &&
        found.name == item.categoryName &&
        found.color == item.categoryColor) {
      return item;
    }
    return item.copyWith(
      categoryId: found.id,
      categoryName: found.name,
      categoryColor: found.color,
    );
  }

  static JobApplication job(
    JobApplication item,
    Iterable<EventCategory> categories,
  ) {
    final found = EventCategory.lookup(
      categories,
      id: item.categoryId,
      name: item.categoryName,
    );
    if (found == null) return item;
    if (found.id == item.categoryId &&
        found.name == item.categoryName &&
        found.color == item.categoryColor) {
      return item;
    }
    return item.copyWith(
      categoryId: found.id,
      categoryName: found.name,
      categoryColor: found.color,
    );
  }

  static License license(
    License item,
    Iterable<EventCategory> categories,
  ) {
    final found = EventCategory.lookup(
      categories,
      id: item.categoryId,
      name: item.categoryName,
    );
    if (found == null) return item;
    if (found.id == item.categoryId &&
        found.name == item.categoryName &&
        found.color == item.categoryColor) {
      return item;
    }
    return item.copyWith(
      categoryId: found.id,
      categoryName: found.name,
      categoryColor: found.color,
    );
  }

  static List<CalendarEvent> events(
    Iterable<CalendarEvent> items,
    Iterable<EventCategory> categories,
  ) {
    return [for (final item in items) event(item, categories)];
  }

  static List<DiaryEntry> diaries(
    Iterable<DiaryEntry> items,
    Iterable<EventCategory> categories,
  ) {
    return [for (final item in items) diary(item, categories)];
  }

  static List<LedgerEntry> ledgers(
    Iterable<LedgerEntry> items,
    Iterable<EventCategory> categories,
  ) {
    return [for (final item in items) ledger(item, categories)];
  }

  static List<JobApplication> jobs(
    Iterable<JobApplication> items,
    Iterable<EventCategory> categories,
  ) {
    return [for (final item in items) job(item, categories)];
  }

  static List<License> licenses(
    Iterable<License> items,
    Iterable<EventCategory> categories,
  ) {
    return [for (final item in items) license(item, categories)];
  }
}
