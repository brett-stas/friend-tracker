import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/data/models/group.dart';
import 'package:friend_tracker/presentation/providers/tracking_providers.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

Group _makeGroup(String id, List<String> members) => Group(
      id: id,
      title: 'Group $id',
      creatorUid: 'creator',
      memberUids: members,
      createdAt: DateTime(2025),
      endDate: DateTime(2027),
    );

void main() {
  // ── trackedUidsProvider ───────────────────────────────────────────────────

  group('trackedUidsProvider', () {
    test('starts empty', () {
      final c = _container();
      expect(c.read(trackedUidsProvider), isEmpty);
    });

    test('adding a UID works', () {
      final c = _container();
      c.read(trackedUidsProvider.notifier).update((s) => {...s, 'uid1'});
      expect(c.read(trackedUidsProvider), contains('uid1'));
    });

    test('removing a UID works', () {
      final c = _container();
      c.read(trackedUidsProvider.notifier).update((s) => {...s, 'uid1', 'uid2'});
      c.read(trackedUidsProvider.notifier).update((s) => {...s}..remove('uid1'));
      expect(c.read(trackedUidsProvider), isNot(contains('uid1')));
      expect(c.read(trackedUidsProvider), contains('uid2'));
    });

    test('can track 10 users simultaneously', () {
      final c = _container();
      final uids = List.generate(10, (i) => 'user_$i');
      c.read(trackedUidsProvider.notifier).update((s) => {...s, ...uids});
      expect(c.read(trackedUidsProvider).length, 10);
      for (final uid in uids) {
        expect(c.read(trackedUidsProvider), contains(uid));
      }
    });
  });

  // ── GroupTrackingNotifier.startGroup ─────────────────────────────────────

  group('GroupTrackingNotifier.startGroup', () {
    test('adds all group members to trackedUids', () {
      final c = _container();
      final grp = _makeGroup('g1', ['uid1', 'uid2', 'uid3']);

      c.read(groupTrackingNotifier.notifier).startGroup(grp);

      final tracked = c.read(trackedUidsProvider);
      expect(tracked, containsAll(['uid1', 'uid2', 'uid3']));
    });

    test('merges with already-tracked UIDs', () {
      final c = _container();
      c.read(trackedUidsProvider.notifier).update((s) => {...s, 'existing'});
      final grp = _makeGroup('g1', ['new1', 'new2']);

      c.read(groupTrackingNotifier.notifier).startGroup(grp);

      final tracked = c.read(trackedUidsProvider);
      expect(tracked, containsAll(['existing', 'new1', 'new2']));
    });

    test('starting a group of 10 tracks all 10', () {
      final c = _container();
      final members = List.generate(10, (i) => 'uid$i');
      final grp = _makeGroup('big', members);

      c.read(groupTrackingNotifier.notifier).startGroup(grp);

      expect(c.read(trackedUidsProvider).length, 10);
      expect(c.read(trackedUidsProvider), containsAll(members));
    });

    test('calling startGroup twice on same group is idempotent', () {
      final c = _container();
      final grp = _makeGroup('g1', ['uid1', 'uid2']);

      c.read(groupTrackingNotifier.notifier).startGroup(grp);
      c.read(groupTrackingNotifier.notifier).startGroup(grp);

      expect(c.read(trackedUidsProvider).length, 2);
    });
  });

  // ── GroupTrackingNotifier.stopGroup ──────────────────────────────────────

  group('GroupTrackingNotifier.stopGroup', () {
    test('removes only group members from trackedUids', () {
      final c = _container();
      c.read(trackedUidsProvider.notifier).update(
            (s) => {'uid1', 'uid2', 'uid3', 'unrelated'},
          );
      final grp = _makeGroup('g1', ['uid1', 'uid2']);

      c.read(groupTrackingNotifier.notifier).stopGroup(grp);

      final tracked = c.read(trackedUidsProvider);
      expect(tracked, isNot(contains('uid1')));
      expect(tracked, isNot(contains('uid2')));
      expect(tracked, contains('uid3'));
      expect(tracked, contains('unrelated'));
    });

    test('stopping a group not yet tracked is a no-op', () {
      final c = _container();
      c.read(trackedUidsProvider.notifier).update((s) => {...s, 'keeper'});
      final grp = _makeGroup('g1', ['uid1', 'uid2']);

      c.read(groupTrackingNotifier.notifier).stopGroup(grp);

      expect(c.read(trackedUidsProvider), contains('keeper'));
      expect(c.read(trackedUidsProvider).length, 1);
    });

    test('startGroup then stopGroup leaves trackedUids empty', () {
      final c = _container();
      final grp = _makeGroup('g1', ['uid1', 'uid2', 'uid3']);

      c.read(groupTrackingNotifier.notifier).startGroup(grp);
      c.read(groupTrackingNotifier.notifier).stopGroup(grp);

      expect(c.read(trackedUidsProvider), isEmpty);
    });

    test('stopping group of 10 removes all 10', () {
      final c = _container();
      final members = List.generate(10, (i) => 'uid$i');
      final grp = _makeGroup('big', members);

      c.read(groupTrackingNotifier.notifier).startGroup(grp);
      c.read(groupTrackingNotifier.notifier).stopGroup(grp);

      expect(c.read(trackedUidsProvider), isEmpty);
    });
  });
}
