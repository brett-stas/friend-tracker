import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FirestoreService service;

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

  // ── Groups ────────────────────────────────────────────────────────────────

  group('FirestoreService.createGroup', () {
    test('creates a document in groups subcollection', () async {
      await service.createGroup('myUid', 'Road Trip', ['uid1', 'uid2']);

      final snap = await fakeDb
          .collection('users')
          .doc('myUid')
          .collection('groups')
          .get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['name'], 'Road Trip');
      expect(snap.docs.first.data()['memberUids'], ['uid1', 'uid2']);
    });

    test('each call creates a distinct document (different auto IDs)', () async {
      await service.createGroup('myUid', 'Group A', ['uid1']);
      await service.createGroup('myUid', 'Group B', ['uid2']);

      final snap = await fakeDb
          .collection('users')
          .doc('myUid')
          .collection('groups')
          .get();
      expect(snap.docs.length, 2);
    });

    test('group with 10 members stores all UIDs', () async {
      final members = List.generate(10, (i) => 'uid$i');
      await service.createGroup('myUid', 'Big Group', members);

      final snap = await fakeDb
          .collection('users')
          .doc('myUid')
          .collection('groups')
          .get();
      final stored = List<String>.from(snap.docs.first.data()['memberUids']);
      expect(stored.length, 10);
      expect(stored, containsAll(members));
    });
  });

  group('FirestoreService.watchGroups', () {
    test('streams empty list when no groups exist', () async {
      final groups = await service.watchGroups('myUid').first;
      expect(groups, isEmpty);
    });

    test('streams all created groups', () async {
      await service.createGroup('myUid', 'Alpha', ['uid1']);
      await service.createGroup('myUid', 'Beta', ['uid2', 'uid3']);

      final groups = await service.watchGroups('myUid').first;
      expect(groups.length, 2);
      expect(groups.map((g) => g.name), containsAll(['Alpha', 'Beta']));
    });

    test('group objects have correct memberUids', () async {
      await service.createGroup('myUid', 'Crew', ['a', 'b', 'c']);

      final groups = await service.watchGroups('myUid').first;
      expect(groups.first.memberUids, containsAll(['a', 'b', 'c']));
    });
  });

  group('FirestoreService.updateGroup', () {
    test('updates name without changing memberUids', () async {
      await service.createGroup('myUid', 'OldName', ['uid1']);
      final snap = await fakeDb
          .collection('users')
          .doc('myUid')
          .collection('groups')
          .get();
      final id = snap.docs.first.id;

      await service.updateGroup('myUid', id, name: 'NewName');

      final doc = await fakeDb
          .collection('users')
          .doc('myUid')
          .collection('groups')
          .doc(id)
          .get();
      expect(doc.data()?['name'], 'NewName');
      expect(doc.data()?['memberUids'], ['uid1']);
    });

    test('updates memberUids without changing name', () async {
      await service.createGroup('myUid', 'Crew', ['uid1']);
      final id = (await fakeDb
              .collection('users')
              .doc('myUid')
              .collection('groups')
              .get())
          .docs
          .first
          .id;

      await service.updateGroup('myUid', id, memberUids: ['uid1', 'uid2']);

      final doc = await fakeDb
          .collection('users')
          .doc('myUid')
          .collection('groups')
          .doc(id)
          .get();
      expect(doc.data()?['name'], 'Crew');
      expect(doc.data()?['memberUids'], ['uid1', 'uid2']);
    });

    test('no-op when neither name nor memberUids provided', () async {
      await service.createGroup('myUid', 'Stable', ['uid1']);
      final id = (await fakeDb
              .collection('users')
              .doc('myUid')
              .collection('groups')
              .get())
          .docs
          .first
          .id;

      // Should not throw
      await service.updateGroup('myUid', id);
    });
  });

  group('FirestoreService.deleteGroup', () {
    test('removes the group document', () async {
      await service.createGroup('myUid', 'Temp', ['uid1']);
      final id = (await fakeDb
              .collection('users')
              .doc('myUid')
              .collection('groups')
              .get())
          .docs
          .first
          .id;

      await service.deleteGroup('myUid', id);

      final snap = await fakeDb
          .collection('users')
          .doc('myUid')
          .collection('groups')
          .get();
      expect(snap.docs, isEmpty);
    });
  });

  // ── Share codes ───────────────────────────────────────────────────────────

  group('FirestoreService.findUidByShareCode', () {
    test('returns uid when code matches', () async {
      await fakeDb.collection('users').doc('uid123').set({
        'shareCode': 'ABCDEFGHIJ12',
        'displayName': 'Alice',
      });

      final uid = await service.findUidByShareCode('ABCDEFGHIJ12');
      expect(uid, 'uid123');
    });

    test('returns null when code not found', () async {
      final uid = await service.findUidByShareCode('NOTEXISTCODE');
      expect(uid, isNull);
    });

    test('lookup is case-insensitive (normalises to upper)', () async {
      await fakeDb.collection('users').doc('uid123').set({
        'shareCode': 'ABCDEFGHIJ12',
        'displayName': 'Alice',
      });

      final uid = await service.findUidByShareCode('abcdefghij12');
      expect(uid, 'uid123');
    });
  });

  // ── ensureUserProfile ─────────────────────────────────────────────────────

  group('FirestoreService.ensureUserProfile', () {
    test('creates profile with 12-char share code if none exists', () async {
      final code = await service.ensureUserProfile('uid1', 'Alice');

      expect(code.length, 12);
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
