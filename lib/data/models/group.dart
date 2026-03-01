import 'package:flutter/foundation.dart';

@immutable
class Group {
  final String id;
  final String name;
  final List<String> memberUids;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.memberUids,
    required this.createdAt,
  });

  factory Group.fromMap(String id, Map<String, dynamic> map) {
    return Group(
      id: id,
      name: map['name'] as String? ?? '',
      memberUids: List<String>.from(map['memberUids'] as List? ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'memberUids': memberUids,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Group copyWith({
    String? id,
    String? name,
    List<String>? memberUids,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      memberUids: memberUids ?? this.memberUids,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
