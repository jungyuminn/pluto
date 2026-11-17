import 'package:pluto/domain/entities/friend_profile.dart';

class GroupCalendar {
  const GroupCalendar({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;
  final int createdAt;
  final int updatedAt;

  bool isOwner(String uid) => ownerUid == uid;

  bool hasMember(String uid) => memberUids.contains(uid);

  factory GroupCalendar.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['memberUids'];
    return GroupCalendar(
      id: id,
      name: '${data['name'] ?? ''}'.trim(),
      ownerUid: '${data['ownerUid'] ?? ''}',
      memberUids: [
        if (raw is List)
          for (final item in raw)
            if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ],
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }
}

class GroupCalendarInvite {
  const GroupCalendarInvite({
    required this.id,
    required this.calendarId,
    required this.calendarName,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    required this.fromCode,
    required this.toName,
    required this.toCode,
    required this.status,
    required this.createdAt,
    this.fromPhotoURL = '',
    this.toPhotoURL = '',
  });

  final String id;
  final String calendarId;
  final String calendarName;
  final String fromUid;
  final String toUid;
  final String fromName;
  final String fromCode;
  final String fromPhotoURL;
  final String toName;
  final String toCode;
  final String toPhotoURL;
  final String status;
  final int createdAt;

  bool get isPending => status == 'pending';

  String get fromLabel => fromName.trim().isEmpty ? fromCode : fromName;

  FriendProfile get fromProfile => FriendProfile(
        uid: fromUid,
        displayName: fromName,
        friendCode: fromCode,
        photoURL: fromPhotoURL,
      );

  factory GroupCalendarInvite.fromMap(String id, Map<String, dynamic> data) {
    return GroupCalendarInvite(
      id: id,
      calendarId: '${data['calendarId'] ?? ''}',
      calendarName: '${data['calendarName'] ?? ''}'.trim(),
      fromUid: '${data['fromUid'] ?? ''}',
      toUid: '${data['toUid'] ?? ''}',
      fromName: '${data['fromName'] ?? ''}',
      fromCode: '${data['fromCode'] ?? ''}',
      fromPhotoURL: '${data['fromPhotoURL'] ?? ''}'.trim(),
      toName: '${data['toName'] ?? ''}',
      toCode: '${data['toCode'] ?? ''}',
      toPhotoURL: '${data['toPhotoURL'] ?? ''}'.trim(),
      status: '${data['status'] ?? ''}',
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}
