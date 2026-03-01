import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/group.dart';

void main() {
  group('Group.fromMap', () {
    test('creates from valid map', () {
      final map = {
        'name': 'Road Trip',
        'memberUids': ['uid1', 'uid2', 'uid3'],
        'createdAt': 1700000000000,
      };

      final group = Group.fromMap('g1', map);

      expect(group.id, 'g1');
      expect(group.name, 'Road Trip');
      expect(group.memberUids, ['uid1', 'uid2', 'uid3']);
      expect(group.createdAt.millisecondsSinceEpoch, 1700000000000);
    });

    test('defaults to empty name when missing', () {
      final group = Group.fromMap('g1', {});
      expect(group.name, '');
    });

    test('defaults to empty memberUids when missing', () {
      final group = Group.fromMap('g1', {'name': 'Test'});
      expect(group.memberUids, isEmpty);
    });

    test('defaults to epoch when createdAt missing', () {
      final group = Group.fromMap('g1', {'name': 'Test'});
      expect(group.createdAt.millisecondsSinceEpoch, 0);
    });
  });

  group('Group.toMap', () {
    test('round-trips correctly', () {
      final created = DateTime(2025, 6, 1, 12);
      final group = Group(
        id: 'g42',
        name: 'Weekend Crew',
        memberUids: ['a', 'b', 'c'],
        createdAt: created,
      );

      final map = group.toMap();

      expect(map['id'], 'g42');
      expect(map['name'], 'Weekend Crew');
      expect(map['memberUids'], ['a', 'b', 'c']);
      expect(map['createdAt'], created.millisecondsSinceEpoch);
    });
  });

  group('Group.copyWith', () {
    final original = Group(
      id: 'g1',
      name: 'Original',
      memberUids: ['uid1'],
      createdAt: DateTime(2025, 1, 1),
    );

    test('changes only name', () {
      final copy = original.copyWith(name: 'Renamed');
      expect(copy.name, 'Renamed');
      expect(copy.id, 'g1');
      expect(copy.memberUids, ['uid1']);
    });

    test('changes only memberUids', () {
      final copy = original.copyWith(memberUids: ['uid2', 'uid3']);
      expect(copy.memberUids, ['uid2', 'uid3']);
      expect(copy.name, 'Original');
    });

    test('with no args returns equivalent group', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.memberUids, original.memberUids);
    });
  });
}
