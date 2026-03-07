import 'package:flutter/foundation.dart';

@immutable
class Group {
  final String id;
  final String title;
  final String creatorUid;
  final List<String> memberUids;
  final DateTime createdAt;
  final DateTime endDate;
  final int maxMembers;

  const Group({
    required this.id,
    required this.title,
    required this.creatorUid,
    required this.memberUids,
    required this.createdAt,
    required this.endDate,
    this.maxMembers = 12,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);

  bool get isExpiringSoon =>
      !isExpired &&
      endDate.difference(DateTime.now()).inHours <= 24;

  factory Group.fromMap(String id, Map<String, dynamic> map) {
    return Group(
      id: id,
      title: map['title'] as String? ?? map['name'] as String? ?? '',
      creatorUid: map['creatorUid'] as String? ?? '',
      memberUids: List<String>.from(map['memberUids'] as List? ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
      endDate: DateTime.fromMillisecondsSinceEpoch(
        (map['endDate'] as num?)?.toInt() ??
            DateTime.now()
                .add(const Duration(days: 7))
                .millisecondsSinceEpoch,
      ),
      maxMembers: (map['maxMembers'] as num?)?.toInt() ?? 12,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'creatorUid': creatorUid,
        'memberUids': memberUids,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'maxMembers': maxMembers,
      };

  Group copyWith({
    String? id,
    String? title,
    String? creatorUid,
    List<String>? memberUids,
    DateTime? createdAt,
    DateTime? endDate,
    int? maxMembers,
  }) {
    return Group(
      id: id ?? this.id,
      title: title ?? this.title,
      creatorUid: creatorUid ?? this.creatorUid,
      memberUids: memberUids ?? this.memberUids,
      createdAt: createdAt ?? this.createdAt,
      endDate: endDate ?? this.endDate,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }
}
