import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/group.dart';

final _endDate = DateTime(2026, 12, 31);

Group _makeGroup({
  String id = 'g1',
  String title = 'Test Group',
  String creatorUid = 'creator1',
  List<String>? memberUids,
  DateTime? endDate,
}) {
  return Group(
    id: id,
    title: title,
    creatorUid: creatorUid,
    memberUids: memberUids ?? ['uid1'],
    createdAt: DateTime(2025, 1, 1),
    endDate: endDate ?? _endDate,
  );
}

void main() {
  group('Group.fromMap', () {
    test('creates from valid map with title field', () {
      final map = {
        'title': 'Road Trip',
        'creatorUid': 'creator1',
        'memberUids': ['uid1', 'uid2', 'uid3'],
        'createdAt': 1700000000000,
        'endDate': 1800000000000,
      };

      final group = Group.fromMap('g1', map);

      expect(group.id, 'g1');
      expect(group.title, 'Road Trip');
      expect(group.creatorUid, 'creator1');
      expect(group.memberUids, ['uid1', 'uid2', 'uid3']);
      expect(group.createdAt.millisecondsSinceEpoch, 1700000000000);
      expect(group.endDate.millisecondsSinceEpoch, 1800000000000);
    });

    test('falls back to legacy name field when title absent', () {
      final map = {
        'name': 'Legacy Group',
        'memberUids': ['uid1'],
        'createdAt': 0,
        'endDate': 1800000000000,
      };
      final group = Group.fromMap('g1', map);
      expect(group.title, 'Legacy Group');
    });

    test('defaults to empty title when both title and name missing', () {
      final group = Group.fromMap('g1', {});
      expect(group.title, '');
    });

    test('defaults to empty memberUids when missing', () {
      final group = Group.fromMap('g1', {'title': 'Test'});
      expect(group.memberUids, isEmpty);
    });

    test('maxMembers defaults to 12', () {
      final group = Group.fromMap('g1', {});
      expect(group.maxMembers, 12);
    });
  });

  group('Group.toMap', () {
    test('round-trips correctly', () {
      final created = DateTime(2025, 6, 1, 12);
      final end = DateTime(2026, 6, 1);
      final group = Group(
        id: 'g42',
        title: 'Weekend Crew',
        creatorUid: 'creator42',
        memberUids: ['a', 'b', 'c'],
        createdAt: created,
        endDate: end,
      );

      final map = group.toMap();

      expect(map['id'], 'g42');
      expect(map['title'], 'Weekend Crew');
      expect(map['creatorUid'], 'creator42');
      expect(map['memberUids'], ['a', 'b', 'c']);
      expect(map['createdAt'], created.millisecondsSinceEpoch);
      expect(map['endDate'], end.millisecondsSinceEpoch);
    });
  });

  group('Group.copyWith', () {
    final original = _makeGroup(title: 'Original');

    test('changes only title', () {
      final copy = original.copyWith(title: 'Renamed');
      expect(copy.title, 'Renamed');
      expect(copy.id, original.id);
      expect(copy.memberUids, original.memberUids);
    });

    test('changes only memberUids', () {
      final copy = original.copyWith(memberUids: ['uid2', 'uid3']);
      expect(copy.memberUids, ['uid2', 'uid3']);
      expect(copy.title, 'Original');
    });

    test('with no args returns equivalent group', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.memberUids, original.memberUids);
      expect(copy.endDate, original.endDate);
    });
  });

  group('Group.isExpiringSoon', () {
    test('true when end date is within 24 hours', () {
      final group = _makeGroup(
          endDate: DateTime.now().add(const Duration(hours: 12)));
      expect(group.isExpiringSoon, isTrue);
    });

    test('false when end date is more than 24 hours away', () {
      final group = _makeGroup(
          endDate: DateTime.now().add(const Duration(days: 3)));
      expect(group.isExpiringSoon, isFalse);
    });

    test('false when already expired', () {
      final group =
          _makeGroup(endDate: DateTime.now().subtract(const Duration(days: 1)));
      expect(group.isExpiringSoon, isFalse);
    });
  });

  group('Group.isExpired', () {
    test('true when end date is in the past', () {
      final group =
          _makeGroup(endDate: DateTime.now().subtract(const Duration(hours: 1)));
      expect(group.isExpired, isTrue);
    });

    test('false when end date is in the future', () {
      final group = _makeGroup(
          endDate: DateTime.now().add(const Duration(days: 7)));
      expect(group.isExpired, isFalse);
    });
  });
}
