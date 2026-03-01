import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friend_tracker/data/models/user_location.dart';
import 'package:friend_tracker/presentation/screens/map_screen.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

void main() {
  group('MapScreen', () {
    testWidgets('shows loading indicator while fetching location', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myLocationProvider.overrideWith(
              (ref) => Stream.empty(),
            ),
            friendsLocationsProvider.overrideWith(
              (ref) => Stream.empty(),
            ),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows friends count chip when friends share location',
        (tester) async {
      final friendsStream = Stream.value([
        UserLocation(
          userId: 'f1',
          displayName: 'Alice',
          latitude: 37.77,
          longitude: -122.41,
          updatedAt: DateTime.now(),
          isSharing: true,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myLocationProvider.overrideWith((ref) => Stream.empty()),
            friendsLocationsProvider.overrideWith((ref) => friendsStream),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('1 friend online'), findsOneWidget);
    });

    testWidgets('share toggle button is present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myLocationProvider.overrideWith((ref) => Stream.empty()),
            friendsLocationsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      expect(find.byKey(const Key('shareToggle')), findsOneWidget);
    });
  });
}
