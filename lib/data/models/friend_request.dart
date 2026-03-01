import 'package:flutter/foundation.dart';

enum FriendRequestStatus { pending, accepted, declined }

@immutable
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == FriendRequestStatus.pending;

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      fromUserId: map['fromUserId'] as String,
      fromDisplayName: map['fromDisplayName'] as String,
      toUserId: map['toUserId'] as String,
      status: FriendRequestStatus.values.byName(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromDisplayName': fromDisplayName,
      'toUserId': toUserId,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? fromDisplayName,
    String? toUserId,
    FriendRequestStatus? status,
    DateTime? createdAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromDisplayName: fromDisplayName ?? this.fromDisplayName,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, status);
}
