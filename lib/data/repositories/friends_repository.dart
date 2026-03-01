import 'package:uuid/uuid.dart';
import 'package:friend_tracker/data/models/friend_request.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';

class FriendsRepository {
  final FirestoreService _firestoreService;
  final Uuid _uuid;

  FriendsRepository({
    required FirestoreService firestoreService,
    Uuid? uuid,
  })  : _firestoreService = firestoreService,
        _uuid = uuid ?? const Uuid();

  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromDisplayName,
    required String toUserId,
  }) async {
    await _firestoreService.sendFriendRequest(
      id: _uuid.v4(),
      fromUserId: fromUserId,
      fromDisplayName: fromDisplayName,
      toUserId: toUserId,
    );
  }

  Future<void> acceptRequest(String requestId) async {
    await _firestoreService.updateRequestStatus(requestId, 'accepted');
  }

  Future<void> declineRequest(String requestId) async {
    await _firestoreService.updateRequestStatus(requestId, 'declined');
  }

  Stream<List<FriendRequest>> watchIncomingRequests(String userId) {
    return _firestoreService
        .watchIncomingRequests(userId)
        .map((list) => list.map(FriendRequest.fromMap).toList());
  }

  Stream<List<FriendRequest>> watchFriends(String userId) {
    return _firestoreService
        .watchFriends(userId)
        .map((list) => list.map(FriendRequest.fromMap).toList());
  }
}
