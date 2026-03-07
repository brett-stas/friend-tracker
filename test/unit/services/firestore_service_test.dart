import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FirestoreService service;

  final futureEnd = DateTime.now().add(const Duration(days: 30));

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = FirestoreService(db: fakeDb);
  });

  // ── Nicknames ─────────────────────────────────────────────────────────────

  group('FirestoreService.setNickname', () {
    test('writes nickname into users/{myUid}.nicknames map', () async {
      await service.setNickname('myUid', 'friendUid', 'Bestie');

      final doc = await fakeDb.collection('users').doc('myUid').get();
      expect(doc.data()?['nicknames'], {'friendUid': 'Bestie'});
    });

    test('adding a second nickname merges without overwriting first', () async {
      await service.setNickname('myUid', 'friend1', 'Alice');
      await service.setNickname('myUid', 'friend2', 'Bob');

      final doc = await fakeDb.collection('users').doc('myUid').get();
      final nicknames = doc.data()?['nicknames'] as Map;
      expect(nicknames['friend1'], 'Alice');
      expect(nicknames['friend2'], 'Bob');
    });
  });

  group('FirestoreService.watchNicknames', () {
    test('returns empty map when no nicknames exist', () async {
      final result = await service.watchNicknames('myUid').first;
      expect(result, isEmpty);
    });

    test('streams set nicknames in real time', () async {
      await service.setNickname('myUid', 'uid1', 'Alice');
      await service.setNickname('myUid', 'uid2', 'Bob');

      final result = await service.watchNicknames('myUid').first;
      expect(result['uid1'], 'Alice');
      expect(result['uid2'], 'Bob');
    });

    test('returns empty map when nicknames field is absent', () async {
      await fakeDb.collection('users').doc('myUid').set({'shareCode': 'ABC'});

      final result = await service.watchNicknames('myUid').first;
      expect(result, isEmpty);
    });
  });

  group('FirestoreService.removeNickname', () {
    test('removes the specified key from nicknames map', () async {
      await service.setNickname('myUid', 'uid1', 'Alice');
      await service.setNickname('myUid', 'uid2', 'Bob');
      await service.removeNickname('myUid', 'uid1');

      final result = await service.watchNicknames('myUid').first;
      expect(result.containsKey('uid1'), isFalse);
      expect(result['uid2'], 'Bob');
    });
  });

  // ── Groups (top-level collection) ─────────────────────────────────────────

  group('FirestoreService.createGroup', () {
    test('creates a document in top-level groups collection', () async {
      await service.createGroup(
        creatorUid: 'myUid',
        title: 'Road Trip',
        invitedUids: ['uid1', 'uid2'],
        endDate: futureEnd,
      );

      final snap = await fakeDb.collection('groups').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['title'], 'Road Trip');
      // Only creator is a confirmed member on creation
      expect(snap.docs.first.data()['memberUids'], contains('myUid'));
      // Invited users are in pendingMemberUids until they accept
      expect(snap.docs.first.data()['pendingMemberUids'], contains('uid1'));
    });

    test('creator is the only confirmed member on creation', () async {
      await service.createGroup(
        creatorUid: 'creator',
        title: 'MyGroup',
        invitedUids: ['uid1'],
        endDate: futureEnd,
      );
      final snap = await fakeDb.collection('groups').get();
      final members =
          List<String>.from(snap.docs.first.data()['memberUids'] as List);
      expect(members, contains('creator'));
      expect(members, hasLength(1));
    });

    test('each call creates a distinct document', () async {
      await service.createGroup(
          creatorUid: 'myUid',
          title: 'Group A',
          invitedUids: ['uid1'],
          endDate: futureEnd);
      await service.createGroup(
          creatorUid: 'myUid',
          title: 'Group B',
          invitedUids: ['uid2'],
          endDate: futureEnd);

      final snap = await fakeDb.collection('groups').get();
      expect(snap.docs.length, 2);
    });

    test('invited UIDs stored as pendingMemberUids', () async {
      final invited = List.generate(5, (i) => 'uid$i');
      await service.createGroup(
          creatorUid: 'myUid',
          title: 'Big Group',
          invitedUids: invited,
          endDate: futureEnd);

      final snap = await fakeDb.collection('groups').get();
      final pending = List<String>.from(
          snap.docs.first.data()['pendingMemberUids'] as List);
      expect(pending, containsAll(invited));
      expect(pending.length, invited.length);
    });

    test('group has a non-empty groupCode with a dash', () async {
      final group = await service.createGroup(
          creatorUid: 'myUid',
          title: 'Coded',
          invitedUids: [],
          endDate: futureEnd);
      expect(group.groupCode, isNotEmpty);
      expect(group.groupCode, contains('-'));
      expect(group.groupCode.replaceAll('-', '').length, 12);
    });
  });

  group('FirestoreService.watchGroups', () {
    test('streams empty list when no groups exist', () async {
      final groups = await service.watchGroups('myUid').first;
      expect(groups, isEmpty);
    });

    test('streams groups where user is a confirmed member', () async {
      await service.createGroup(
          creatorUid: 'myUid',
          title: 'Alpha',
          invitedUids: ['uid1'],
          endDate: futureEnd);
      await service.createGroup(
          creatorUid: 'myUid',
          title: 'Beta',
          invitedUids: ['uid2', 'uid3'],
          endDate: futureEnd);

      final groups = await service.watchGroups('myUid').first;
      expect(groups.length, 2);
      expect(groups.map((g) => g.title), containsAll(['Alpha', 'Beta']));
    });

    test('group objects have pendingMemberUids for invited users', () async {
      await service.createGroup(
          creatorUid: 'myUid',
          title: 'Crew',
          invitedUids: ['a', 'b', 'c'],
          endDate: futureEnd);

      final groups = await service.watchGroups('myUid').first;
      expect(groups.first.pendingMemberUids, containsAll(['a', 'b', 'c']));
    });
  });

  group('FirestoreService.updateGroup', () {
    test('updates title without changing memberUids', () async {
      final created = await service.createGroup(
          creatorUid: 'myUid',
          title: 'OldName',
          invitedUids: [],
          endDate: futureEnd);

      await service.updateGroup(created.id, title: 'NewName');

      final doc = await fakeDb.collection('groups').doc(created.id).get();
      expect(doc.data()?['title'], 'NewName');
      expect(doc.data()?['memberUids'], contains('myUid'));
    });

    test('updates memberUids without changing title', () async {
      final created = await service.createGroup(
          creatorUid: 'myUid',
          title: 'Crew',
          invitedUids: [],
          endDate: futureEnd);

      await service.updateGroup(created.id, memberUids: ['myUid', 'uid2']);

      final doc = await fakeDb.collection('groups').doc(created.id).get();
      expect(doc.data()?['title'], 'Crew');
      expect(doc.data()?['memberUids'], containsAll(['myUid', 'uid2']));
    });

    test('updates endDate', () async {
      final created = await service.createGroup(
          creatorUid: 'myUid',
          title: 'Timed',
          invitedUids: [],
          endDate: futureEnd);
      final newEnd = futureEnd.add(const Duration(days: 7));

      await service.updateGroup(created.id, endDate: newEnd);

      final doc = await fakeDb.collection('groups').doc(created.id).get();
      expect(doc.data()?['endDate'], newEnd.millisecondsSinceEpoch);
    });

    test('no-op when no fields provided', () async {
      final created = await service.createGroup(
          creatorUid: 'myUid',
          title: 'Stable',
          invitedUids: [],
          endDate: futureEnd);

      // Should not throw
      await service.updateGroup(created.id);
    });
  });

  group('FirestoreService.deleteGroup', () {
    test('removes the group document', () async {
      final created = await service.createGroup(
          creatorUid: 'myUid',
          title: 'Temp',
          invitedUids: ['uid1'],
          endDate: futureEnd);

      await service.deleteGroup(created.id);

      final snap = await fakeDb.collection('groups').get();
      expect(snap.docs, isEmpty);
    });
  });

  // ── Location requests ─────────────────────────────────────────────────────

  group('FirestoreService.sendLocationRequest', () {
    test('creates pending request document', () async {
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'bob',
      );

      final snap = await fakeDb.collection('locationRequests').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['status'], 'pending');
      expect(snap.docs.first.data()['fromUid'], 'alice');
      expect(snap.docs.first.data()['toUid'], 'bob');
    });
  });

  group('FirestoreService.watchIncomingLocationRequests', () {
    test('streams pending requests for recipient', () async {
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'bob',
      );

      final requests =
          await service.watchIncomingLocationRequests('bob').first;
      expect(requests.length, 1);
      expect(requests.first.fromDisplayName, 'Alice');
    });

    test('does not stream requests for other users', () async {
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'charlie',
      );

      final requests = await service.watchIncomingLocationRequests('bob').first;
      expect(requests, isEmpty);
    });
  });

  group('FirestoreService.acceptLocationRequest', () {
    test('creates a connection and marks request accepted', () async {
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'bob',
      );
      final snap = await fakeDb.collection('locationRequests').get();
      final requestId = snap.docs.first.id;

      await service.acceptLocationRequest(
        requestId,
        uid1: 'alice',
        uid2: 'bob',
        initiatorUid: 'alice',
      );

      final req = await fakeDb.collection('locationRequests').doc(requestId).get();
      expect(req.data()?['status'], 'accepted');

      final connections = await fakeDb.collection('connections').get();
      expect(connections.docs.length, 1);
      expect(connections.docs.first.data()['isActive'], isTrue);
    });
  });

  group('FirestoreService.declineLocationRequest', () {
    test('marks request as declined', () async {
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'bob',
      );
      final snap = await fakeDb.collection('locationRequests').get();
      final requestId = snap.docs.first.id;

      await service.declineLocationRequest(requestId);

      final req =
          await fakeDb.collection('locationRequests').doc(requestId).get();
      expect(req.data()?['status'], 'declined');
    });
  });

  // ── Share codes ───────────────────────────────────────────────────────────

  group('FirestoreService.findUidByShareCode', () {
    test('returns uid when code matches (with dash)', () async {
      await fakeDb.collection('users').doc('uid123').set({
        'shareCode': 'ABCDEF-GHIJ12',
        'displayName': 'Alice',
      });

      final uid = await service.findUidByShareCode('ABCDEF-GHIJ12');
      expect(uid, 'uid123');
    });

    test('returns null when code not found', () async {
      final uid = await service.findUidByShareCode('NOT-EXIST');
      expect(uid, isNull);
    });

    test('lookup normalises case and strips/re-inserts dash', () async {
      await fakeDb.collection('users').doc('uid123').set({
        'shareCode': 'ABCDEF-GHIJ12',
        'displayName': 'Alice',
      });

      // lowercase without dash — still finds the record
      final uid = await service.findUidByShareCode('abcdefghij12');
      expect(uid, 'uid123');
    });
  });

  // ── ensureUserProfile ─────────────────────────────────────────────────────

  group('FirestoreService.ensureUserProfile', () {
    test('creates profile with 6–12 char share code (with dash) if none exists',
        () async {
      final code = await service.ensureUserProfile('uid1', 'Alice');

      // Code is formatted as e.g. "ABC-DEF" — strip dash to check raw length
      final raw = code.replaceAll('-', '');
      expect(raw.length, greaterThanOrEqualTo(6));
      expect(raw.length, lessThanOrEqualTo(12));
      expect(code, contains('-'));
      final doc = await fakeDb.collection('users').doc('uid1').get();
      expect(doc.data()?['displayName'], 'Alice');
      expect(doc.data()?['shareCode'], code);
    });

    test('returns existing share code without overwriting', () async {
      await fakeDb.collection('users').doc('uid1').set({
        'shareCode': 'EXISTINGCODE',
        'displayName': 'Alice',
      });

      final code = await service.ensureUserProfile('uid1', 'Alice');
      expect(code, 'EXISTINGCODE');
    });
  });
}
