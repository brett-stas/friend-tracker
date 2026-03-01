import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friend_tracker/data/models/group.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── User profiles & share codes ──────────────────────────────────────────

  /// Creates a user profile if one doesn't exist and returns the share code.
  Future<String> ensureUserProfile(String uid, String displayName) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final code = doc.data()?['shareCode'];
      if (code is String && code.isNotEmpty) return code;
    }
    final shareCode = _generateShareCode();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'shareCode': shareCode,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    return shareCode;
  }

  static String _generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Returns the UID of the user with [shareCode], or null if not found.
  Future<String?> findUidByShareCode(String shareCode) async {
    final snap = await _db
        .collection('users')
        .where('shareCode', isEqualTo: shareCode.toUpperCase().trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  /// Streams the full user document (location + profile) for [uid].
  Stream<Map<String, dynamic>?> watchUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? {...doc.data()!, 'uid': doc.id} : null,
        );
  }

  /// Writes the user's current lat/lng into their profile doc.
  Future<void> updateLocationInProfile(
    String uid, {
    required double latitude,
    required double longitude,
  }) async {
    await _db.collection('users').doc(uid).set({
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

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

  // ── Nicknames ─────────────────────────────────────────────────────────────

  /// Streams the nicknames map `{ friendUid → nickname }` from [myUid]'s doc.
  Stream<Map<String, String>> watchNicknames(String myUid) {
    return _db.collection('users').doc(myUid).snapshots().map((doc) {
      if (!doc.exists) return {};
      final raw = doc.data()?['nicknames'];
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    });
  }

  /// Saves [nickname] for [friendUid] inside [myUid]'s `nicknames` map.
  Future<void> setNickname(
      String myUid, String friendUid, String nickname) async {
    await _db.collection('users').doc(myUid).set({
      'nicknames': {friendUid: nickname},
    }, SetOptions(merge: true));
  }

  /// Removes the nickname for [friendUid] from [myUid]'s `nicknames` map.
  Future<void> removeNickname(String myUid, String friendUid) async {
    await _db.collection('users').doc(myUid).update({
      'nicknames.$friendUid': FieldValue.delete(),
    });
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  /// Streams the groups subcollection for [myUid].
  Stream<List<Group>> watchGroups(String myUid) {
    return _db
        .collection('users')
        .doc(myUid)
        .collection('groups')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Group.fromMap(doc.id, doc.data())).toList());
  }

  /// Creates a new group document under [myUid]/groups.
  Future<void> createGroup(
      String myUid, String name, List<String> memberUids) async {
    final ref = _db
        .collection('users')
        .doc(myUid)
        .collection('groups')
        .doc();
    await ref.set({
      'id': ref.id,
      'name': name,
      'memberUids': memberUids,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Merges [name] and/or [memberUids] into the group doc.
  Future<void> updateGroup(
    String myUid,
    String groupId, {
    String? name,
    List<String>? memberUids,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (memberUids != null) data['memberUids'] = memberUids;
    if (data.isEmpty) return;
    await _db
        .collection('users')
        .doc(myUid)
        .collection('groups')
        .doc(groupId)
        .update(data);
  }

  /// Deletes the group doc.
  Future<void> deleteGroup(String myUid, String groupId) async {
    await _db
        .collection('users')
        .doc(myUid)
        .collection('groups')
        .doc(groupId)
        .delete();
  }
}
