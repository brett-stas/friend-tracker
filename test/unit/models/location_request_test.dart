import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/location_request.dart';

void main() {
  group('LocationRequest.fromMap', () {
    test('parses pending status correctly', () {
      final req = LocationRequest.fromMap('req1', {
        'fromUid': 'alice',
        'fromDisplayName': 'Alice',
        'toUid': 'bob',
        'status': 'pending',
        'createdAt': 1700000000000,
      });

      expect(req.id, 'req1');
      expect(req.fromUid, 'alice');
      expect(req.fromDisplayName, 'Alice');
      expect(req.toUid, 'bob');
      expect(req.status, LocationRequestStatus.pending);
    });

    test('parses accepted status correctly', () {
      final req = LocationRequest.fromMap('req1', {
        'fromUid': 'alice',
        'fromDisplayName': 'Alice',
        'toUid': 'bob',
        'status': 'accepted',
        'createdAt': 0,
      });
      expect(req.status, LocationRequestStatus.accepted);
    });

    test('parses declined status correctly', () {
      final req = LocationRequest.fromMap('req1', {
        'fromUid': 'alice',
        'fromDisplayName': 'Alice',
        'toUid': 'bob',
        'status': 'declined',
        'createdAt': 0,
      });
      expect(req.status, LocationRequestStatus.declined);
    });

    test('defaults to pending for unknown status', () {
      final req = LocationRequest.fromMap('req1', {
        'fromUid': 'alice',
        'fromDisplayName': 'Alice',
        'toUid': 'bob',
        'status': 'unknown_value',
        'createdAt': 0,
      });
      expect(req.status, LocationRequestStatus.pending);
    });

    test('defaults fromDisplayName to "Someone" when missing', () {
      final req = LocationRequest.fromMap('req1', {
        'fromUid': 'alice',
        'toUid': 'bob',
        'status': 'pending',
        'createdAt': 0,
      });
      expect(req.fromDisplayName, 'Someone');
    });
  });

  group('LocationRequest.toMap', () {
    test('serialises correctly', () {
      final req = LocationRequest(
        id: 'req42',
        fromUid: 'alice',
        fromDisplayName: 'Alice',
        toUid: 'bob',
        status: LocationRequestStatus.pending,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final map = req.toMap();
      expect(map['id'], 'req42');
      expect(map['fromUid'], 'alice');
      expect(map['toUid'], 'bob');
      expect(map['status'], 'pending');
    });
  });
}
