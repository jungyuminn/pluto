import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pluto/data/datasources/device_calendar_mapper.dart';
import 'package:pluto/domain/entities/calendar_event.dart';

class PhotoCalendarDraft {
  const PhotoCalendarDraft({
    required this.title,
    required this.day,
    this.until,
    this.startMinutes,
    this.endMinutes,
  });

  final String title;
  final DateTime day;
  final DateTime? until;
  final int? startMinutes;
  final int? endMinutes;

  DateTime get last {
    final end = until;
    if (end == null || end.isBefore(day)) return day;
    final max = day.add(const Duration(days: 62));
    return end.isAfter(max) ? max : end;
  }

  bool get isRange => last.isAfter(day);
}

abstract final class PhotoCalendarClient {
  static const _region = 'asia-northeast3';
  static const maxPhotos = 8;
  static const _maxBytes = 1_200_000;

  static Future<List<Uint8List>> pickPhotos() async {
    final picked = await FilePicker.pickFiles(type: FileType.image);
    if (picked.isEmpty) return [];
    final out = <Uint8List>[];
    for (final file in picked.take(maxPhotos)) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      out.add(await _shrink(bytes));
    }
    return out;
  }

  static Stream<List<PhotoCalendarDraft>> readAll(List<Uint8List> photos) async* {
    final found = <PhotoCalendarDraft>[];
    final year = DateTime.now().year;
    for (final photo in photos) {
      found.addAll(await readOne(photo, year: year));
      yield List<PhotoCalendarDraft>.from(found);
    }
  }

  static Future<List<PhotoCalendarDraft>> readOne(
    Uint8List photo, {
    required int year,
  }) async {
    if (Firebase.apps.isEmpty) return [];
    if (FirebaseAuth.instance.currentUser == null) return [];
    try {
      final result = await FirebaseFunctions.instanceFor(region: _region)
          .httpsCallable('importCalendarPhoto')
          .call({
            'image': base64Encode(photo),
            'mime': _mimeOf(photo),
            'year': year,
          })
          .timeout(const Duration(seconds: 40));
      final data = result.data;
      if (data is! Map) return [];
      final raw = data['events'];
      if (raw is! List) return [];
      return [
        for (final item in raw)
          if (item is Map) ?_parse(item, year),
      ];
    } catch (error) {
      debugPrint('Photo calendar failed: $error');
      return [];
    }
  }

  static List<CalendarEvent> toEvents(
    List<PhotoCalendarDraft> drafts, {
    required Iterable<CalendarEvent> existing,
  }) {
    final keys = {
      for (final event in existing)
        DeviceCalendarMapper.titleDayKey(event.title, event.day),
    };
    final events = <CalendarEvent>[];
    var stamp = DateTime.now().millisecondsSinceEpoch;
    for (final draft in drafts) {
      final days = [
        for (
          var day = draft.day;
          !day.isAfter(draft.last);
          day = day.add(const Duration(days: 1))
        )
          day,
      ];
      final kept = [
        for (final day in days)
          if (keys.add(DeviceCalendarMapper.titleDayKey(draft.title, day))) day,
      ];
      if (kept.isEmpty) continue;
      final groupId = kept.length > 1
          ? 'photo_g_${(stamp + events.length).toRadixString(16)}_${draft.title.hashCode.toUnsigned(32).toRadixString(16)}'
          : null;
      for (final day in kept) {
        final stampDay =
            '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
        events.add(
          CalendarEvent(
            id: 'photo_${stampDay}_${draft.title.hashCode.toUnsigned(32).toRadixString(16)}',
            title: draft.title,
            date: day,
            groupId: groupId,
            sortOrder: stamp + events.length,
            startMinutes: draft.startMinutes,
            endMinutes: draft.endMinutes,
          ),
        );
      }
    }
    return events;
  }

  static PhotoCalendarDraft? _parse(Map item, int year) {
    final title = '${item['title'] ?? ''}'.trim();
    if (title.isEmpty) return null;
    final day = _dayOf('${item['date'] ?? ''}', year);
    if (day == null) return null;
    final until = _dayOf('${item['until'] ?? ''}', year);
    return PhotoCalendarDraft(
      title: title,
      day: day,
      until: until == null || until.isBefore(day) ? null : until,
      startMinutes: _minutesOf('${item['start'] ?? ''}'),
      endMinutes: _minutesOf('${item['end'] ?? ''}'),
    );
  }

  static DateTime? _dayOf(String text, int year) {
    final match = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text);
    if (match == null) return null;
    final y = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);
    if (y < year - 1 || y > year + 1) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  static int? _minutesOf(String text) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String _mimeOf(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  static Future<Uint8List> _shrink(Uint8List bytes) async {
    if (bytes.length <= _maxBytes) return bytes;
    for (final width in [1280, 960, 720, 480]) {
      final out = await _resizePng(bytes, width);
      if (out != null && out.length <= _maxBytes) return out;
    }
    return await _resizePng(bytes, 480) ?? bytes;
  }

  static Future<Uint8List?> _resizePng(Uint8List bytes, int width) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        return png?.buffer.asUint8List();
      } finally {
        image.dispose();
        codec.dispose();
      }
    } catch (_) {
      return null;
    }
  }
}
