import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friend_tracker/data/models/connection.dart';
import 'package:friend_tracker/data/models/group.dart';
import 'package:friend_tracker/data/models/group_invite.dart';
import 'package:friend_tracker/data/models/location_request.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── User profiles & share codes ──────────────────────────────────────────

  Future<String> ensureUserProfile(String uid, String displayName) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final code = doc.data()?['shareCode'];
      if (code is String && code.isNotEmpty) return code;
    }
    final shareCode = await _uniqueShareCode();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'shareCode': shareCode,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    return shareCode;
  }

  /// Generates the shortest unique share code starting at 6 chars, up to 12.
  Future<String> _uniqueShareCode() async {
    for (var length = 6; length <= 12; length++) {
      // Try a few candidates at this length before growing
      for (var attempt = 0; attempt < 5; attempt++) {
        final candidate = _generateCode(length);
        final existing = await findUidByShareCode(candidate);
        if (existing == null) return candidate;
      }
    }
    // Fallback: 12-char code (collision astronomically unlikely at this point)
    return _generateCode(12);
  }

  static String _generateCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final raw = List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
    final mid = length ~/ 2;
    return '${raw.substring(0, mid)}-${raw.substring(mid)}';
  }

  Future<bool> isDisplayNameTaken(String displayName) async {
    final snap = await _db
        .collection('users')
        .where('displayName', isEqualTo: displayName.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<String?> findUidByShareCode(String shareCode) async {
    // Normalise: uppercase, strip dashes, then re-insert dash at midpoint
    final stripped = shareCode.toUpperCase().trim().replaceAll('-', '');
    final mid = stripped.length ~/ 2;
    final normalised = stripped.isEmpty
        ? ''
        : '${stripped.substring(0, mid)}-${stripped.substring(mid)}';
    final snap = await _db
        .collection('users')
        .where('shareCode', isEqualTo: normalised)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  /// Find a user by email or display name (case-insensitive display name match).
  Future<Map<String, dynamic>?> findUserByEmailOrName(String query) async {
    final trimmed = query.trim();

    // Try email first (exact match)
    final emailSnap = await _db
        .collection('users')
        .where('email', isEqualTo: trimmed.toLowerCase())
        .limit(1)
        .get();
    if (emailSnap.docs.isNotEmpty) {
      return {...emailSnap.docs.first.data(), 'uid': emailSnap.docs.first.id};
    }

    // Try displayName (prefix match using Firestore range query)
    final nameSnap = await _db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: trimmed)
        .where('displayName', isLessThan: '${trimmed}z')
        .limit(5)
        .get();
    if (nameSnap.docs.isNotEmpty) {
      return {...nameSnap.docs.first.data(), 'uid': nameSnap.docs.first.id};
    }

    return null;
  }

  Stream<Map<String, dynamic>?> watchUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? {...doc.data()!, 'uid': doc.id} : null,
        );
  }

  Future<void> updateDisplayNameInProfile(String uid, String displayName) async {
    await _db.collection('users').doc(uid).set(
      {'displayName': displayName},
      SetOptions(merge: true),
    );
  }

  Future<void> updateLocationInProfile(
    String uid, {
    required double latitude,
    required double longitude,
  }) async {
    await _db.collection('users').doc(uid).set({
      'latitude': latitude,
      'longitude': longitude,
      'lastSeenAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> setUserIcon(String uid, String iconName) async {
    await _db.collection('users').doc(uid).set({
      'iconName': iconName,
    }, SetOptions(merge: true));
  }

  Future<void> setUserEmail(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'email': email.toLowerCase().trim(),
    }, SetOptions(merge: true));
  }

  // ── Location sharing requests ─────────────────────────────────────────────

  Future<void> sendLocationRequest({
    required String fromUid,
    required String fromDisplayName,
    required String toUid,
  }) async {
    final ref = _db.collection('locationRequests').doc();
    await ref.set({
      'id': ref.id,
      'fromUid': fromUid,
      'fromDisplayName': fromDisplayName,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<LocationRequest>> watchIncomingLocationRequests(String uid) {
    return _db
        .collection('locationRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs
            .map((d) => LocationRequest.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> acceptLocationRequest(
    String requestId, {
    required String uid1,
    required String uid2,
    required String initiatorUid,
  }) async {
    final batch = _db.batch();

    // Mark request accepted
    batch.update(_db.collection('locationRequests').doc(requestId), {
      'status': 'accepted',
    });

    // Create mutual connection
    final connectionId = Connection.makeId(uid1, uid2);
    final sorted = [uid1, uid2]..sort();
    batch.set(_db.collection('connections').doc(connectionId), {
      'id': connectionId,
      'uid1': sorted[0],
      'uid2': sorted[1],
      'initiatorUid': initiatorUid,
      'isActive': true,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    await batch.commit();
  }

  Future<void> declineLocationRequest(String requestId) async {
    await _db
        .collection('locationRequests')
        .doc(requestId)
        .update({'status': 'declined'});
  }

  // ── Connections ───────────────────────────────────────────────────────────

  Stream<List<Connection>> watchActiveConnections(String uid) {
    // Firestore doesn't support OR queries across fields in a single query,
    // so we merge two streams client-side.
    final q1 = _db
        .collection('connections')
        .where('uid1', isEqualTo: uid)
        .where('isActive', isEqualTo: true);
    final q2 = _db
        .collection('connections')
        .where('uid2', isEqualTo: uid)
        .where('isActive', isEqualTo: true);

    return q1.snapshots().asyncMap((s1) async {
      final s2 = await q2.get();
      final all = [
        ...s1.docs.map((d) => Connection.fromMap(d.id, d.data())),
        ...s2.docs.map((d) => Connection.fromMap(d.id, d.data())),
      ];
      // Deduplicate by id
      final seen = <String>{};
      return all.where((c) => seen.add(c.id)).toList();
    });
  }

  Future<void> deactivateConnection(String uid1, String uid2) async {
    final id = Connection.makeId(uid1, uid2);
    await _db.collection('connections').doc(id).update({'isActive': false});
  }

  // ── Nicknames ─────────────────────────────────────────────────────────────

  Stream<Map<String, String>> watchNicknames(String myUid) {
    return _db.collection('users').doc(myUid).snapshots().map((doc) {
      if (!doc.exists) return {};
      final raw = doc.data()?['nicknames'];
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    });
  }

  Future<void> setNickname(
      String myUid, String friendUid, String nickname) async {
    await _db.collection('users').doc(myUid).set({
      'nicknames': {friendUid: nickname},
    }, SetOptions(merge: true));
  }

  Future<void> removeNickname(String myUid, String friendUid) async {
    await _db.collection('users').doc(myUid).update({
      'nicknames.$friendUid': FieldValue.delete(),
    });
  }

  // ── Shared Tracking Groups (top-level collection) ─────────────────────────

  /// Streams all groups where [myUid] is a member.
  Stream<List<Group>> watchGroups(String myUid) {
    return _db
        .collection('groups')
        .where('memberUids', arrayContains: myUid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Group.fromMap(doc.id, doc.data())).toList());
  }

  Future<Group?> findGroupByCode(String groupCode) async {
    final snap = await _db
        .collection('groups')
        .where('groupCode', isEqualTo: groupCode.toUpperCase().trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Group.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  // ── Group invites ─────────────────────────────────────────────────────────

  Future<void> sendGroupInvite({
    required String groupId,
    required String groupTitle,
    required String groupCode,
    required String fromUid,
    required String fromDisplayName,
    required String toUid,
  }) async {
    final ref = _db.collection('groupInvites').doc();
    final invite = GroupInvite(
      id: ref.id,
      groupId: groupId,
      groupTitle: groupTitle,
      groupCode: groupCode,
      fromUid: fromUid,
      fromDisplayName: fromDisplayName,
      toUid: toUid,
      status: GroupInviteStatus.pending,
      createdAt: DateTime.now(),
    );
    await ref.set(invite.toMap());
  }

  Stream<List<GroupInvite>> watchIncomingGroupInvites(String uid) {
    return _db
        .collection('groupInvites')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs
            .map((d) => GroupInvite.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> acceptGroupInvite(String inviteId,
      {required String groupId, required String toUid}) async {
    final batch = _db.batch();
    // Mark invite accepted
    batch.update(_db.collection('groupInvites').doc(inviteId),
        {'status': 'accepted'});
    // Move toUid from pendingMemberUids → memberUids
    batch.update(_db.collection('groups').doc(groupId), {
      'pendingMemberUids': FieldValue.arrayRemove([toUid]),
      'memberUids': FieldValue.arrayUnion([toUid]),
    });
    await batch.commit();
  }

  Future<void> declineGroupInvite(String inviteId,
      {required String groupId, required String toUid}) async {
    final batch = _db.batch();
    batch.update(_db.collection('groupInvites').doc(inviteId),
        {'status': 'declined'});
    batch.update(_db.collection('groups').doc(groupId), {
      'pendingMemberUids': FieldValue.arrayRemove([toUid]),
    });
    await batch.commit();
  }

  // ── Groups CRUD ───────────────────────────────────────────────────────────

  Future<Group> createGroup({
    required String creatorUid,
    required String title,
    required List<String> invitedUids,   // UIDs to invite (not yet members)
    required DateTime endDate,
  }) async {
    assert(invitedUids.length < 12, 'Groups cannot exceed 12 members');
    final ref = _db.collection('groups').doc();
    final code = _generateCode(12);
    final group = Group(
      id: ref.id,
      title: title,
      creatorUid: creatorUid,
      memberUids: [creatorUid],           // only creator confirmed on create
      pendingMemberUids: invitedUids,
      createdAt: DateTime.now(),
      endDate: endDate,
      groupCode: code,
    );
    await ref.set(group.toMap());
    return group;
  }

  Future<void> updateGroup(
    String groupId, {
    String? title,
    List<String>? memberUids,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (memberUids != null) data['memberUids'] = memberUids;
    if (endDate != null) data['endDate'] = endDate.millisecondsSinceEpoch;
    if (data.isEmpty) return;
    await _db.collection('groups').doc(groupId).update(data);
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }

  /// Deletes all expired groups (called on app foreground).
  Future<void> purgeExpiredGroups() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final snap = await _db
        .collection('groups')
        .where('endDate', isLessThan: now)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    if (snap.docs.isNotEmpty) await batch.commit();
  }

  // ── Dashboard stats (admin only) ──────────────────────────────────────────

  /// Stream of total registered users count.
  Stream<int> watchTotalUsersCount() {
    return _db
        .collection('users')
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Stream of users active in the last 5 minutes.
  Stream<int> watchActiveUsersCount() {
    final threshold =
        DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
    return _db
        .collection('users')
        .where('lastSeenAt', isGreaterThan: threshold)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Stream of active (non-expired) group count.
  Stream<int> watchActiveGroupsCount() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db
        .collection('groups')
        .where('endDate', isGreaterThan: now)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Stream of pending location request count.
  Stream<int> watchPendingRequestsCount() {
    return _db
        .collection('locationRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ── Legacy compatibility (do not use for new features) ────────────────────

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

  // ── Legacy friend requests (kept for backwards compat) ────────────────────

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
