import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/friend_request.dart';

void main() {
  group('FriendRequest', () {
    test('creates from map', () {
      final map = {
        'id': 'req1',
        'fromUserId': 'userA',
        'fromDisplayName': 'Alice',
        'toUserId': 'userB',
        'status': 'pending',
        'createdAt': 1700000000000,
      };

      final req = FriendRequest.fromMap(map);

      expect(req.id, 'req1');
      expect(req.fromUserId, 'userA');
      expect(req.status, FriendRequestStatus.pending);
    });

    test('toMap serialises status correctly', () {
      final req = FriendRequest(
        id: 'req2',
        fromUserId: 'userA',
        fromDisplayName: 'Alice',
        toUserId: 'userB',
        status: FriendRequestStatus.accepted,
        createdAt: DateTime(2025, 3, 1),
      );

      final map = req.toMap();

      expect(map['status'], 'accepted');
    });

    test('isPending returns true only for pending status', () {
      final pending = FriendRequest(
        id: 'r1',
        fromUserId: 'a',
        fromDisplayName: 'A',
        toUserId: 'b',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      final accepted = pending.copyWith(status: FriendRequestStatus.accepted);

      expect(pending.isPending, isTrue);
      expect(accepted.isPending, isFalse);
    });
  });
}
