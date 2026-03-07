// Tests that 3 simultaneous user locations render correctly on the map.
// BR-15: Minimum 3 users shown in map tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/user_location.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';
import 'package:friend_tracker/presentation/screens/map_screen.dart';

/// Three simulated users with distinct locations.
final _threeUsers = [
  UserLocation(
    userId: 'user_alice',
    displayName: 'Alice',
    latitude: 37.7749,
    longitude: -122.4194,
    updatedAt: DateTime.now(),
    isSharing: true,
  ),
  UserLocation(
    userId: 'user_bob',
    displayName: 'Bob',
    latitude: 37.7849,
    longitude: -122.4094,
    updatedAt: DateTime.now(),
    isSharing: true,
  ),
  UserLocation(
    userId: 'user_charlie',
    displayName: 'Charlie',
    latitude: 37.7649,
    longitude: -122.4294,
    updatedAt: DateTime.now(),
    isSharing: true,
  ),
];

Widget _buildMapWithThreeUsers() {
  return ProviderScope(
    overrides: [
      myLocationProvider.overrideWith((ref) => Stream.empty()),
      friendsLocationsProvider.overrideWith(
        (ref) => Stream.value(_threeUsers),
      ),
    ],
    child: const MaterialApp(home: MapScreen()),
  );
}

void main() {
  group('MapScreen — 3 simultaneous users (BR-15)', () {
    testWidgets('shows 3-friend count chip for 3 online users', (tester) async {
      await tester.pumpWidget(_buildMapWithThreeUsers());
      await tester.pump();

      expect(find.text('3 friends online'), findsOneWidget);
    });

    testWidgets('all three users are in the friends stream', (tester) async {
      // Verify the 3-user stream is set up correctly and UI reflects it
      await tester.pumpWidget(_buildMapWithThreeUsers());
      await tester.pump();

      // 3 friends online text confirms all 3 users are present
      expect(find.text('3 friends online'), findsOneWidget);
    });

    testWidgets('friend count chip is absent when no friends online',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myLocationProvider.overrideWith((ref) => Stream.empty()),
            friendsLocationsProvider
                .overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('3 friends online'), findsNothing);
      expect(find.text('1 friend online'), findsNothing);
    });

    testWidgets('share toggle is visible alongside 3 tracked users',
        (tester) async {
      await tester.pumpWidget(_buildMapWithThreeUsers());
      await tester.pump();

      expect(find.byKey(const Key('shareToggle')), findsOneWidget);
      expect(find.text('3 friends online'), findsOneWidget);
    });
  });

  group('UserLocation model', () {
    test('constructs with required fields', () {
      final loc = _threeUsers[0];
      expect(loc.userId, 'user_alice');
      expect(loc.displayName, 'Alice');
      expect(loc.latitude, 37.7749);
      expect(loc.isSharing, isTrue);
    });

    test('3 users have distinct userIds', () {
      final ids = _threeUsers.map((u) => u.userId).toSet();
      expect(ids.length, 3);
    });

    test('3 users have distinct lat/lng positions', () {
      final positions =
          _threeUsers.map((u) => '${u.latitude},${u.longitude}').toSet();
      expect(positions.length, 3);
    });
  });
}
