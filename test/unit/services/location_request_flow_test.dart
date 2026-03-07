// Integration-style test for the full location request accept/decline flow.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/connection.dart';
import 'package:friend_tracker/data/models/location_request.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FirestoreService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = FirestoreService(db: fakeDb);
  });

  group('Location sharing request flow', () {
    test('full happy path: send → accept → connection created', () async {
      // Alice sends a request to Bob
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'bob',
      );

      // Bob sees pending request
      final incoming = await service.watchIncomingLocationRequests('bob').first;
      expect(incoming.length, 1);
      expect(incoming.first.status, LocationRequestStatus.pending);
      expect(incoming.first.fromDisplayName, 'Alice');

      // Bob accepts
      await service.acceptLocationRequest(
        incoming.first.id,
        uid1: 'alice',
        uid2: 'bob',
        initiatorUid: 'alice',
      );

      // Request is now accepted
      final updated = await service.watchIncomingLocationRequests('bob').first;
      expect(updated, isEmpty); // no more pending requests

      // A mutual connection exists
      final connectionId = Connection.makeId('alice', 'bob');
      final connDoc =
          await fakeDb.collection('connections').doc(connectionId).get();
      expect(connDoc.exists, isTrue);
      expect(connDoc.data()?['isActive'], isTrue);
    });

    test('decline path: send → decline → no connection', () async {
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'bob',
      );

      final incoming = await service.watchIncomingLocationRequests('bob').first;
      await service.declineLocationRequest(incoming.first.id);

      // No connection created
      final connections = await fakeDb.collection('connections').get();
      expect(connections.docs, isEmpty);

      // Request is declined (not pending)
      final declined = await fakeDb
          .collection('locationRequests')
          .doc(incoming.first.id)
          .get();
      expect(declined.data()?['status'], 'declined');
    });

    test('deactivating a connection removes it from active list', () async {
      // Setup: create a connection directly
      final id = Connection.makeId('alice', 'bob');
      await fakeDb.collection('connections').doc(id).set({
        'id': id,
        'uid1': 'alice',
        'uid2': 'bob',
        'initiatorUid': 'alice',
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Verify it appears in active connections
      final before = await service.watchActiveConnections('alice').first;
      expect(before.length, 1);

      // Deactivate
      await service.deactivateConnection('alice', 'bob');

      // No longer active
      final after = await service.watchActiveConnections('alice').first;
      expect(after, isEmpty);
    });

    test('multiple pending requests arrive correctly', () async {
      await service.sendLocationRequest(
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'charlie',
      );
      await service.sendLocationRequest(
        fromUid: 'bob',
        fromDisplayName: 'Bob',
        toUid: 'charlie',
      );

      final incoming =
          await service.watchIncomingLocationRequests('charlie').first;
      expect(incoming.length, 2);
      expect(
        incoming.map((r) => r.fromDisplayName),
        containsAll(['Alice', 'Bob']),
      );
    });
  });

  group('Connection.makeId canonical ordering', () {
    test('connection id is the same regardless of uid order', () {
      final id1 = Connection.makeId('bob', 'alice');
      final id2 = Connection.makeId('alice', 'bob');
      expect(id1, id2);
    });
  });
}
