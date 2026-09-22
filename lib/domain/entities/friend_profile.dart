class FriendProfile {
  const FriendProfile({
    required this.uid,
    required this.displayName,
    required this.friendCode,
    this.suggestedCode = '',
    this.photoURL = '',
    this.needsCode = false,
    this.nextChangeAt = 0,
  });

  final String uid;
  final String displayName;
  final String friendCode;
  final String photoURL;
  final String suggestedCode;
  final bool needsCode;
  final int nextChangeAt;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'friendCode': friendCode,
      'photoURL': photoURL,
      'suggestedCode': suggestedCode,
      'needsCode': needsCode,
      'nextChangeAt': nextChangeAt,
    };
  }

  FriendProfile copyWith({
    String? displayName,
    String? friendCode,
    String? photoURL,
    String? suggestedCode,
    bool? needsCode,
    int? nextChangeAt,
  }) {
    return FriendProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      friendCode: friendCode ?? this.friendCode,
      photoURL: photoURL ?? this.photoURL,
      suggestedCode: suggestedCode ?? this.suggestedCode,
      needsCode: needsCode ?? this.needsCode,
      nextChangeAt: nextChangeAt ?? this.nextChangeAt,
    );
  }

  String get label {
    final name = displayName.trim();
    if (name.isNotEmpty) return name;
    return friendCode;
  }

  bool get hasIdentity {
    return !needsCode &&
        friendCode.trim().isNotEmpty &&
        displayName.trim().isNotEmpty;
  }

  bool get hasAppPhoto {
    final url = photoURL.trim();
    if (url.isEmpty) return false;
    return url.contains('firebasestorage.googleapis.com') ||
        url.contains('firebasestorage.app') ||
        url.contains('storage.googleapis.com');
  }

  bool get canChangeCode {
    if (needsCode || friendCode.isEmpty) return true;
    if (nextChangeAt <= 0) return true;
    return DateTime.now().millisecondsSinceEpoch >= nextChangeAt;
  }

  int get cooldownDays {
    final left = nextChangeAt - DateTime.now().millisecondsSinceEpoch;
    if (left <= 0) return 0;
    return (left / 86400000).ceil();
  }

  factory FriendProfile.fromMap(Map<String, dynamic> data, {String? uid}) {
    final code = '${data['friendCode'] ?? ''}'.trim();
    final needs = data['needsCode'] == true || code.isEmpty || code.contains('#');
    return FriendProfile(
      uid: uid ?? '${data['uid'] ?? ''}',
      displayName: '${data['displayName'] ?? ''}'.trim(),
      friendCode: needs ? '' : code,
      photoURL: '${data['photoURL'] ?? ''}'.trim(),
      suggestedCode: '${data['suggestedCode'] ?? ''}'.trim(),
      needsCode: needs,
      nextChangeAt: (data['nextChangeAt'] as num?)?.toInt() ?? 0,
    );
  }
}

class FriendRequestItem {
  const FriendRequestItem({
    required this.id,
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

  String get toLabel => toName.trim().isEmpty ? toCode : toName;

  FriendProfile get fromProfile => FriendProfile(
        uid: fromUid,
        displayName: fromName,
        friendCode: fromCode,
        photoURL: fromPhotoURL,
      );

  FriendProfile get toProfile => FriendProfile(
        uid: toUid,
        displayName: toName,
        friendCode: toCode,
        photoURL: toPhotoURL,
      );

  FriendRequestItem copyWith({
    String? fromPhotoURL,
    String? toPhotoURL,
  }) {
    return FriendRequestItem(
      id: id,
      fromUid: fromUid,
      toUid: toUid,
      fromName: fromName,
      fromCode: fromCode,
      fromPhotoURL: fromPhotoURL ?? this.fromPhotoURL,
      toName: toName,
      toCode: toCode,
      toPhotoURL: toPhotoURL ?? this.toPhotoURL,
      status: status,
      createdAt: createdAt,
    );
  }

  factory FriendRequestItem.fromMap(String id, Map<String, dynamic> data) {
    return FriendRequestItem(
      id: id,
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

class FriendException implements Exception {
  const FriendException(this.code);

  final String code;
}
