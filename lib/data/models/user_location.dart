import 'package:flutter/foundation.dart';

@immutable
class UserLocation {
  final String userId;
  final String displayName;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final bool isSharing;

  const UserLocation({
    required this.userId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    required this.isSharing,
  });

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isSharing: map['isSharing'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSharing': isSharing,
    };
  }

  UserLocation copyWith({
    String? userId,
    String? displayName,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
    bool? isSharing,
  }) {
    return UserLocation(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
      isSharing: isSharing ?? this.isSharing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocation &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          displayName == other.displayName &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          updatedAt == other.updatedAt &&
          isSharing == other.isSharing;

  @override
  int get hashCode => Object.hash(
        userId,
        displayName,
        latitude,
        longitude,
        updatedAt,
        isSharing,
      );
}
