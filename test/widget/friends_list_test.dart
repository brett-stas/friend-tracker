import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friend_tracker/data/models/friend_request.dart';
import 'package:friend_tracker/presentation/screens/friends_screen.dart';
import 'package:friend_tracker/presentation/providers/friends_providers.dart';

void main() {
  group('FriendsScreen', () {
    testWidgets('shows empty state when no friends', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRequestsProvider.overrideWith((ref) => Stream.value([])),
            friendsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: FriendsScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('No friends yet'), findsOneWidget);
      expect(find.text('Add a friend to start tracking'), findsOneWidget);
    });

    testWidgets('shows pending request badge', (tester) async {
      final pendingRequest = FriendRequest(
        id: 'r1',
        fromUserId: 'userA',
        fromDisplayName: 'Alice',
        toUserId: 'me',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRequestsProvider.overrideWith(
              (ref) => Stream.value([pendingRequest]),
            ),
            friendsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: FriendsScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Alice wants to share location'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('add friend button is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendRequestsProvider.overrideWith((ref) => Stream.value([])),
            friendsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: FriendsScreen()),
        ),
      );

      expect(find.byKey(const Key('addFriendFab')), findsOneWidget);
    });
  });
}
