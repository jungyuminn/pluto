import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pluto/core/constants/app_strings.dart';
import 'package:pluto/data/datasources/friend_service.dart';
import 'package:pluto/domain/entities/calendar_event.dart';
import 'package:pluto/domain/entities/event_checklist_item.dart';
import 'package:pluto/domain/entities/friend_profile.dart';
import 'package:pluto/domain/entities/group_calendar.dart';

class GroupCalendarService {
  GroupCalendarService._();

  static final instance = GroupCalendarService._();

  static const maxMembers = 12;
  static const maxDays = 366;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get _ready =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  String? get _uid =>
      _ready ? FirebaseAuth.instance.currentUser?.uid : null;

  String? _calendarStreamUid;
  StreamController<List<GroupCalendar>>? _calendarsCtrl;
  Stream<List<GroupCalendar>>? _calendarsReplay;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _calendarsSub;
  var _lastCalendars = const <GroupCalendar>[];

  String? _inviteStreamUid;
  StreamController<List<GroupCalendarInvite>>? _invitesCtrl;
  Stream<List<GroupCalendarInvite>>? _invitesReplay;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invitesSub;
  var _lastInvites = const <GroupCalendarInvite>[];

  List<GroupCalendar> get lastCalendars => _lastCalendars;

  List<GroupCalendarInvite> get lastInvites => _lastInvites;

  void reset() {
    _disposeCalendarStream();
    _disposeInviteStream();
  }

  Stream<List<GroupCalendar>> calendars() {
    _bindCalendarStream();
    return _calendarsReplay ?? Stream.value(_lastCalendars);
  }

  Stream<List<GroupCalendarInvite>> incomingInvites() {
    _bindInviteStream();
    return _invitesReplay ?? Stream.value(_lastInvites);
  }

  Stream<GroupCalendar?> watch(String calendarId) {
    if (!_ready || calendarId.isEmpty) {
      return Stream.value(null);
    }
    return _db.collection('group_calendars').doc(calendarId).snapshots().map(
      (snap) {
        final data = snap.data();
        if (!snap.exists || data == null) return null;
        return GroupCalendar.fromMap(snap.id, data);
      },
    );
  }

  Stream<List<CalendarEvent>> eventsInMonth({
    required String calendarId,
    required DateTime month,
  }) {
    if (!_ready || calendarId.isEmpty) {
      return Stream.value(const []);
    }
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return _db
        .collection('group_calendars')
        .doc(calendarId)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: _date(start))
        .where('date', isLessThanOrEqualTo: _date(end))
        .snapshots()
        .map((snap) {
      return [for (final doc in snap.docs) _fromEvent(doc.id, doc.data())];
    });
  }

  Future<List<CalendarEvent>> eventsOn({
    required String calendarId,
    required DateTime date,
  }) async {
    if (!_ready || calendarId.isEmpty) return const [];
    final snap = await _db
        .collection('group_calendars')
        .doc(calendarId)
        .collection('events')
        .where('date', isEqualTo: _date(date))
        .get();
    return [for (final doc in snap.docs) _fromEvent(doc.id, doc.data())];
  }

  Future<GroupCalendar> create(String rawName) async {
    final me = _requireProfile();
    final name = _parseName(rawName);
    final existing = await _db
        .collection('group_calendars')
        .where('memberUids', arrayContains: me.uid)
        .get();
    if (existing.docs.length >= 20) {
      throw const FriendException('rate-limited');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _db.collection('group_calendars').doc();
    await ref.set({
      'name': name,
      'ownerUid': me.uid,
      'memberUids': [me.uid],
      'createdAt': now,
      'updatedAt': now,
    });
    return GroupCalendar(
      id: ref.id,
      name: name,
      ownerUid: me.uid,
      memberUids: [me.uid],
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> rename(String calendarId, String rawName) async {
    final me = _requireUid();
    final name = _parseName(rawName);
    final calendar = await _requireCalendar(calendarId);
    if (!calendar.isOwner(me)) {
      throw const FriendException('not-owner');
    }
    await _db.collection('group_calendars').doc(calendarId).update({
      'name': name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> invite({
    required GroupCalendar calendar,
    required FriendProfile friend,
  }) async {
    final me = _requireProfile();
    if (friend.uid.isEmpty || friend.uid == me.uid) {
      throw const FriendException('self');
    }
    if (!calendar.hasMember(me.uid)) {
      throw const FriendException('not-member');
    }
    if (calendar.hasMember(friend.uid)) {
      throw const FriendException('already-member');
    }
    if (calendar.memberUids.length >= maxMembers) {
      throw const FriendException('full');
    }
    if (!await FriendService.instance.isFriend(friend.uid)) {
      throw const FriendException('not-friends');
    }
    final id = '${calendar.id}_${friend.uid}';
    final ref = _db.collection('group_calendar_invites').doc(id);
    final existing = await ref.get();
    if (existing.exists) {
      final item = GroupCalendarInvite.fromMap(id, existing.data() ?? {});
      if (item.isPending) {
        throw const FriendException('already-sent');
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.set({
      'calendarId': calendar.id,
      'calendarName': calendar.name,
      'fromUid': me.uid,
      'toUid': friend.uid,
      'fromName': me.displayName,
      'fromCode': me.friendCode,
      'fromPhotoURL': me.photoURL,
      'toName': friend.displayName,
      'toCode': friend.friendCode,
      'toPhotoURL': friend.photoURL,
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
      'participants': [me.uid, friend.uid],
    });
  }

  Future<void> accept(String inviteId) async {
    final me = _requireUid();
    final ref = _db.collection('group_calendar_invites').doc(inviteId);
    final snap = await ref.get();
    if (!snap.exists) throw const FriendException('not-found');
    final invite = GroupCalendarInvite.fromMap(inviteId, snap.data() ?? {});
    if (!invite.isPending || invite.toUid != me) {
      throw const FriendException('not-allowed');
    }
    final calendar = await _requireCalendar(invite.calendarId);
    if (calendar.memberUids.length >= maxMembers &&
        !calendar.hasMember(me)) {
      throw const FriendException('full');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!calendar.hasMember(me)) {
      await _db.collection('group_calendars').doc(calendar.id).update({
        'memberUids': FieldValue.arrayUnion([me]),
        'updatedAt': now,
      });
    }
    await ref.update({
      'status': 'accepted',
      'updatedAt': now,
    });
  }

  Future<void> decline(String inviteId) async {
    final me = _requireUid();
    final ref = _db.collection('group_calendar_invites').doc(inviteId);
    final snap = await ref.get();
    if (!snap.exists) throw const FriendException('not-found');
    final invite = GroupCalendarInvite.fromMap(inviteId, snap.data() ?? {});
    if (!invite.isPending || invite.toUid != me) {
      throw const FriendException('not-allowed');
    }
    await ref.update({
      'status': 'declined',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> leave(String calendarId) async {
    final me = _requireUid();
    final calendar = await _requireCalendar(calendarId);
    if (calendar.isOwner(me)) {
      throw const FriendException('not-allowed');
    }
    if (!calendar.hasMember(me)) return;
    await _db.collection('group_calendars').doc(calendarId).update({
      'memberUids': FieldValue.arrayRemove([me]),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeMember({
    required String calendarId,
    required String memberUid,
  }) async {
    final me = _requireUid();
    final calendar = await _requireCalendar(calendarId);
    if (!calendar.isOwner(me)) {
      throw const FriendException('not-owner');
    }
    if (memberUid == me || memberUid.isEmpty) {
      throw const FriendException('not-allowed');
    }
    if (!calendar.hasMember(memberUid)) return;
    await _db.collection('group_calendars').doc(calendarId).update({
      'memberUids': FieldValue.arrayRemove([memberUid]),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> delete(String calendarId) async {
    final me = _requireUid();
    final calendar = await _requireCalendar(calendarId);
    if (!calendar.isOwner(me)) {
      throw const FriendException('not-owner');
    }
    final events = _db
        .collection('group_calendars')
        .doc(calendarId)
        .collection('events');
    while (true) {
      final snap = await events.limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _db.collection('group_calendars').doc(calendarId).delete();
  }

  Future<void> saveDays({
    required String calendarId,
    required List<CalendarEvent> events,
  }) async {
    final me = _requireUid();
    if (events.isEmpty) return;
    if (events.length > maxDays) {
      throw const FriendException('bad-todo');
    }
    await _requireCalendar(calendarId);
    final now = DateTime.now().millisecondsSinceEpoch;
    var batch = _db.batch();
    var ops = 0;
    final writes = <Future<void>>[];
    for (final event in events) {
      final ref = _events(calendarId).doc(event.id);
      batch.set(ref, _toEvent(event, me, me, now, now));
      ops += 1;
      if (ops >= 400) {
        writes.add(batch.commit());
        batch = _db.batch();
        ops = 0;
      }
    }
    if (ops > 0) writes.add(batch.commit());
    await Future.wait(writes);
  }

  Future<void> replaceGroup({
    required String calendarId,
    required CalendarEvent sample,
    required List<DateTime> days,
    String? previousGroupId,
    String? previousRepeatId,
  }) async {
    if (previousGroupId != null && previousGroupId.isNotEmpty) {
      await deleteByField(calendarId, 'groupId', previousGroupId);
    }
    if (previousRepeatId != null && previousRepeatId.isNotEmpty) {
      await deleteByField(calendarId, 'repeatId', previousRepeatId);
    }
    if (sample.id.isNotEmpty) {
      try {
        await _events(calendarId).doc(sample.id).delete();
      } catch (_) {}
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    final groupId = days.length > 1 && sample.repeatId == null
        ? (sample.groupId ?? '$now')
        : sample.groupId;
    final events = [
      for (var i = 0; i < days.length; i++)
        sample.copyWith(
          id: '${now}_$i',
          date: days[i],
          groupId: groupId,
          sortOrder: sample.sortOrder + i,
        ),
    ];
    await saveDays(calendarId: calendarId, events: events);
  }

  Future<void> updateEvent({
    required String calendarId,
    required CalendarEvent event,
  }) async {
    final me = _requireUid();
    await _requireCalendar(calendarId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _events(calendarId).doc(event.id);
    final existing = await ref.get();
    final createdBy = existing.data()?['createdBy'] as String? ?? me;
    final createdAt =
        (existing.data()?['createdAt'] as num?)?.toInt() ?? now;
    await ref.set(_toEvent(event, me, createdBy, createdAt, now));
  }

  Future<void> setCompleted({
    required String calendarId,
    required CalendarEvent event,
  }) async {
    final me = _requireUid();
    await _requireCalendar(calendarId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _events(calendarId).doc(event.id);
    final existing = await ref.get();
    if (!existing.exists) {
      await saveDays(calendarId: calendarId, events: [event]);
      return;
    }
    final createdBy = existing.data()?['createdBy'] as String? ?? me;
    final createdAt =
        (existing.data()?['createdAt'] as num?)?.toInt() ?? now;
    await ref.set(_toEvent(event, me, createdBy, createdAt, now));
  }

  Future<void> deleteEvent({
    required String calendarId,
    required CalendarEvent event,
  }) async {
    await _requireCalendar(calendarId);
    final groupId = event.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      await deleteByField(calendarId, 'groupId', groupId);
      return;
    }
    await _events(calendarId).doc(event.id).delete();
  }

  Future<void> deleteRepeats({
    required String calendarId,
    required String repeatId,
    DateTime? from,
  }) async {
    await _requireCalendar(calendarId);
    final snap = await _events(calendarId)
        .where('repeatId', isEqualTo: repeatId)
        .get();
    final stamp = from == null ? null : _date(from);
    final batch = _db.batch();
    var ops = 0;
    for (final doc in snap.docs) {
      if (stamp != null) {
        final date = '${doc.data()['date'] ?? ''}';
        if (date.compareTo(stamp) < 0) continue;
      }
      batch.delete(doc.reference);
      ops += 1;
    }
    if (ops > 0) await batch.commit();
  }

  Future<void> deleteByField(
    String calendarId,
    String field,
    String value,
  ) async {
    final snap = await _events(calendarId).where(field, isEqualTo: value).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String messageOf(Object error) {
    final mapped = FriendService.instance.messageOf(error);
    if (mapped != AppStrings.friendsFailed) return mapped;
    final code = error is FriendException ? error.code : '';
    return switch (code) {
      'already-member' => AppStrings.groupCalendarAlreadyMember,
      'already-sent' => AppStrings.groupCalendarAlreadyInvited,
      'full' => AppStrings.groupCalendarFull,
      'not-owner' || 'not-member' || 'not-allowed' =>
        AppStrings.groupCalendarDenied,
      _ => AppStrings.friendsFailed,
    };
  }

  CollectionReference<Map<String, dynamic>> _events(String calendarId) {
    return _db.collection('group_calendars').doc(calendarId).collection('events');
  }

  FriendProfile _requireProfile() {
    final me = FriendService.instance.profile.value;
    final uid = _uid;
    if (me == null || !me.hasIdentity || uid == null || me.uid != uid) {
      throw const FriendException('needs-profile');
    }
    return me;
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null) throw const FriendException('login-required');
    return uid;
  }

  Future<GroupCalendar> _requireCalendar(String calendarId) async {
    if (calendarId.isEmpty) throw const FriendException('not-found');
    final snap =
        await _db.collection('group_calendars').doc(calendarId).get();
    if (!snap.exists) throw const FriendException('not-found');
    final calendar = GroupCalendar.fromMap(snap.id, snap.data() ?? {});
    final me = _uid;
    if (me == null || !calendar.hasMember(me)) {
      throw const FriendException('not-member');
    }
    return calendar;
  }

  String _parseName(String raw) {
    final name = raw
        .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.isEmpty || name.length > 16 || RegExp(r'[#＃@＠]').hasMatch(name)) {
      throw const FriendException('bad-name');
    }
    return name;
  }

  void _bindCalendarStream() {
    final uid = _uid;
    if (uid == null) {
      _disposeCalendarStream();
      return;
    }
    if (_calendarStreamUid == uid && _calendarsReplay != null) return;
    _disposeCalendarStream();
    _calendarStreamUid = uid;
    _calendarsCtrl = StreamController<List<GroupCalendar>>.broadcast();
    _calendarsReplay = _ReplayStream(_calendarsCtrl!.stream, () => _lastCalendars);
    _calendarsSub = _db
        .collection('group_calendars')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .listen((snap) {
      final items = [
        for (final doc in snap.docs) GroupCalendar.fromMap(doc.id, doc.data()),
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _lastCalendars = items;
      _calendarsCtrl?.add(items);
    }, onError: (error) {
      debugPrint('Group calendars stream failed: $error');
    });
  }

  void _bindInviteStream() {
    final uid = _uid;
    if (uid == null) {
      _disposeInviteStream();
      return;
    }
    if (_inviteStreamUid == uid && _invitesReplay != null) return;
    _disposeInviteStream();
    _inviteStreamUid = uid;
    _invitesCtrl = StreamController<List<GroupCalendarInvite>>.broadcast();
    _invitesReplay = _ReplayStream(_invitesCtrl!.stream, () => _lastInvites);
    _invitesSub = _db
        .collection('group_calendar_invites')
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      final items = [
        for (final doc in snap.docs)
          GroupCalendarInvite.fromMap(doc.id, doc.data()),
      ].where((item) => item.isPending).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _lastInvites = items;
      _invitesCtrl?.add(items);
    }, onError: (error) {
      debugPrint('Group calendar invites stream failed: $error');
    });
  }

  void _disposeCalendarStream() {
    _calendarsSub?.cancel();
    _calendarsSub = null;
    _calendarsCtrl?.close();
    _calendarsCtrl = null;
    _calendarsReplay = null;
    _calendarStreamUid = null;
    _lastCalendars = const [];
  }

  void _disposeInviteStream() {
    _invitesSub?.cancel();
    _invitesSub = null;
    _invitesCtrl?.close();
    _invitesCtrl = null;
    _invitesReplay = null;
    _inviteStreamUid = null;
    _lastInvites = const [];
  }

  Map<String, dynamic> _toEvent(
    CalendarEvent event,
    String uid,
    String createdBy,
    int createdAt,
    int updatedAt,
  ) {
    return {
      'title': event.title.trim(),
      'date': _date(event.date),
      'memo': event.memo,
      'color': event.categoryColor,
      'categoryName': event.categoryName,
      'completed': event.completed,
      'groupId': event.groupId,
      'repeatId': event.repeatId,
      'startMinutes': event.startMinutes,
      'endMinutes': event.endMinutes,
      'checklist': EventChecklistItem.listToJson(event.checklist),
      'sortOrder': event.sortOrder,
      'createdBy': createdBy,
      'updatedBy': uid,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CalendarEvent _fromEvent(String id, Map<String, dynamic> data) {
    return CalendarEvent(
      id: id,
      title: '${data['title'] ?? ''}',
      date: _parseDate('${data['date'] ?? ''}'),
      memo: '${data['memo'] ?? ''}',
      checklist: EventChecklistItem.listFrom(data['checklist']),
      categoryName: '${data['categoryName'] ?? CalendarEvent.defaultCategoryName}',
      categoryColor: (data['color'] as num?)?.toInt() ??
          CalendarEvent.defaultCategoryColor,
      completed: data['completed'] == true,
      groupId: _optionalId(data['groupId']),
      repeatId: _optionalId(data['repeatId']),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      startMinutes: (data['startMinutes'] as num?)?.toInt(),
      endMinutes: (data['endMinutes'] as num?)?.toInt(),
    );
  }

  String _date(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime _parseDate(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  String? _optionalId(Object? value) {
    if (value == null) return null;
    final id = '$value'.trim();
    return id.isEmpty ? null : id;
  }
}

class _ReplayStream<T> extends Stream<T> {
  _ReplayStream(this._source, this._current);

  final Stream<T> _source;
  final T Function() _current;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onData?.call(_current());
    return _source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
