import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> setLocation(String userId, Map<String, dynamic> data) async {
    await _db.collection('locations').doc(userId).set(data);
  }

  Future<void> setSharing(String userId, bool isSharing) async {
    await _db.collection('locations').doc(userId).update({
      'isSharing': isSharing,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<Map<String, dynamic>>> watchFriendsLocations(String myUserId) {
    return _db
        .collection('locations')
        .where('isSharing', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.id != myUserId)
            .map((doc) => doc.data()..['userId'] = doc.id)
            .toList());
  }

  Future<void> sendFriendRequest({
    required String id,
    required String fromUserId,
    required String fromDisplayName,
    required String toUserId,
  }) async {
    await _db.collection('friendRequests').doc(id).set({
      'id': id,
      'fromUserId': fromUserId,
      'fromDisplayName': fromDisplayName,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<Map<String, dynamic>>> watchIncomingRequests(String userId) {
    return _db
        .collection('friendRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> watchFriends(String userId) {
    return _db
        .collection('friendRequests')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((s) => s.docs
            .where((d) =>
                d['fromUserId'] == userId || d['toUserId'] == userId)
            .map((d) => d.data())
            .toList());
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _db
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': status});
  }
}
