import 'package:flutter/foundation.dart';

@immutable
class Connection {
  final String id;
  final String uid1;
  final String uid2;
  final String initiatorUid;
  final bool isActive;
  final DateTime createdAt;

  const Connection({
    required this.id,
    required this.uid1,
    required this.uid2,
    required this.initiatorUid,
    required this.isActive,
    required this.createdAt,
  });

  /// Returns the other user's UID given one of the two UIDs.
  String otherUid(String myUid) => uid1 == myUid ? uid2 : uid1;

  /// Canonical connection ID: smaller UID first, joined by '_'.
  static String makeId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  factory Connection.fromMap(String id, Map<String, dynamic> map) {
    return Connection(
      id: id,
      uid1: map['uid1'] as String? ?? '',
      uid2: map['uid2'] as String? ?? '',
      initiatorUid: map['initiatorUid'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid1': uid1,
        'uid2': uid2,
        'initiatorUid': initiatorUid,
        'isActive': isActive,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Connection copyWith({bool? isActive}) => Connection(
        id: id,
        uid1: uid1,
        uid2: uid2,
        initiatorUid: initiatorUid,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
