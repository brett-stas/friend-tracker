import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/user_location.dart';

void main() {
  group('UserLocation', () {
    test('creates from map with valid data', () {
      final map = {
        'userId': 'user123',
        'displayName': 'Alice',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'updatedAt': 1700000000000,
        'isSharing': true,
      };

      final loc = UserLocation.fromMap(map);

      expect(loc.userId, 'user123');
      expect(loc.displayName, 'Alice');
      expect(loc.latitude, 37.7749);
      expect(loc.longitude, -122.4194);
      expect(loc.isSharing, true);
    });

    test('toMap round-trips correctly', () {
      final loc = UserLocation(
        userId: 'u1',
        displayName: 'Bob',
        latitude: 40.7128,
        longitude: -74.0060,
        updatedAt: DateTime(2025, 1, 1),
        isSharing: true,
      );

      final map = loc.toMap();

      expect(map['userId'], 'u1');
      expect(map['displayName'], 'Bob');
      expect(map['latitude'], 40.7128);
      expect(map['longitude'], -74.0060);
      expect(map['isSharing'], true);
    });

    test('copyWith preserves unchanged fields', () {
      final original = UserLocation(
        userId: 'u1',
        displayName: 'Carol',
        latitude: 51.5074,
        longitude: -0.1278,
        updatedAt: DateTime(2025, 6, 1),
        isSharing: true,
      );

      final updated = original.copyWith(isSharing: false);

      expect(updated.userId, 'u1');
      expect(updated.displayName, 'Carol');
      expect(updated.isSharing, false);
    });

    test('equality check works', () {
      final a = UserLocation(
        userId: 'u1',
        displayName: 'Dave',
        latitude: 48.8566,
        longitude: 2.3522,
        updatedAt: DateTime(2025, 1, 1),
        isSharing: false,
      );
      final b = a.copyWith();

      expect(a, equals(b));
    });
  });
}
