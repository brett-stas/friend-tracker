import 'package:flutter/foundation.dart';

enum LocationRequestStatus { pending, accepted, declined }

@immutable
class LocationRequest {
  final String id;
  final String fromUid;
  final String fromDisplayName;
  final String toUid;
  final LocationRequestStatus status;
  final DateTime createdAt;

  const LocationRequest({
    required this.id,
    required this.fromUid,
    required this.fromDisplayName,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  factory LocationRequest.fromMap(String id, Map<String, dynamic> map) {
    return LocationRequest(
      id: id,
      fromUid: map['fromUid'] as String? ?? '',
      fromDisplayName: map['fromDisplayName'] as String? ?? 'Someone',
      toUid: map['toUid'] as String? ?? '',
      status: _parseStatus(map['status'] as String? ?? 'pending'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  static LocationRequestStatus _parseStatus(String s) {
    switch (s) {
      case 'accepted':
        return LocationRequestStatus.accepted;
      case 'declined':
        return LocationRequestStatus.declined;
      default:
        return LocationRequestStatus.pending;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'fromUid': fromUid,
        'fromDisplayName': fromDisplayName,
        'toUid': toUid,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
