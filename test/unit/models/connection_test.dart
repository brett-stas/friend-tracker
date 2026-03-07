import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/connection.dart';

void main() {
  group('Connection.makeId', () {
    test('smaller UID is always first', () {
      expect(Connection.makeId('bob', 'alice'), 'alice_bob');
      expect(Connection.makeId('alice', 'bob'), 'alice_bob');
    });

    test('same input always produces same id', () {
      final id1 = Connection.makeId('uid_z', 'uid_a');
      final id2 = Connection.makeId('uid_a', 'uid_z');
      expect(id1, id2);
    });
  });

  group('Connection.otherUid', () {
    final conn = Connection(
      id: 'a_b',
      uid1: 'alice',
      uid2: 'bob',
      initiatorUid: 'alice',
      isActive: true,
      createdAt: DateTime(2025),
    );

    test('returns uid2 when given uid1', () {
      expect(conn.otherUid('alice'), 'bob');
    });

    test('returns uid1 when given uid2', () {
      expect(conn.otherUid('bob'), 'alice');
    });
  });

  group('Connection.fromMap', () {
    test('parses correctly', () {
      final conn = Connection.fromMap('id1', {
        'uid1': 'alice',
        'uid2': 'bob',
        'initiatorUid': 'alice',
        'isActive': true,
        'createdAt': 1700000000000,
      });

      expect(conn.uid1, 'alice');
      expect(conn.uid2, 'bob');
      expect(conn.isActive, isTrue);
    });

    test('defaults isActive to true when missing', () {
      final conn = Connection.fromMap('id1', {
        'uid1': 'alice',
        'uid2': 'bob',
        'initiatorUid': 'alice',
        'createdAt': 0,
      });
      expect(conn.isActive, isTrue);
    });
  });

  group('Connection.copyWith', () {
    test('can deactivate connection', () {
      final conn = Connection(
        id: 'a_b',
        uid1: 'alice',
        uid2: 'bob',
        initiatorUid: 'alice',
        isActive: true,
        createdAt: DateTime(2025),
      );
      final inactive = conn.copyWith(isActive: false);
      expect(inactive.isActive, isFalse);
      expect(inactive.uid1, 'alice');
    });
  });
}
