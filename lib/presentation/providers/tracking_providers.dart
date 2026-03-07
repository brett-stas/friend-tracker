import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friend_tracker/data/models/connection.dart';
import 'package:friend_tracker/data/models/group.dart';
import 'package:friend_tracker/data/models/location_request.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

/// The current user's 12-character share code (fetched/created on first load).
final myShareCodeProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return '';
  return ref.watch(firestoreServiceProvider).ensureUserProfile(
        user.uid,
        user.displayName ?? 'User',
      );
});

/// Set of UIDs the current user is actively tracking.
final trackedUidsProvider = StateProvider<Set<String>>((ref) => const {});

/// Streams the profile + location data for a single tracked user.
final trackedUserProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchUserData(uid);
});

/// Streams the current user's nicknames map { friendUid → nickname }.
final nicknamesProvider = StreamProvider<Map<String, String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({});
  return ref.watch(firestoreServiceProvider).watchNicknames(user.uid);
});

/// Streams the current user's shared tracking groups.
final groupsProvider = StreamProvider<List<Group>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchGroups(user.uid);
});

/// Streams incoming pending location sharing requests for the current user.
final incomingLocationRequestsProvider =
    StreamProvider<List<LocationRequest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .watchIncomingLocationRequests(user.uid);
});

/// Count of pending incoming location requests (for badge display).
final pendingRequestCountProvider = Provider<int>((ref) {
  return ref.watch(incomingLocationRequestsProvider).valueOrNull?.length ?? 0;
});

/// Streams the current user's active mutual tracking connections.
final connectionsProvider = StreamProvider<List<Connection>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchActiveConnections(user.uid);
});

/// Notifier to start/stop tracking all members of a group at once.
class GroupTrackingNotifier extends Notifier<void> {
  @override
  void build() {}

  void startGroup(Group group) {
    ref.read(trackedUidsProvider.notifier).update(
          (s) => {...s, ...group.memberUids},
        );
  }

  void stopGroup(Group group) {
    ref.read(trackedUidsProvider.notifier).update(
          (s) => s.difference(group.memberUids.toSet()),
        );
  }
}

final groupTrackingNotifier =
    NotifierProvider<GroupTrackingNotifier, void>(GroupTrackingNotifier.new);

/// Notifier that handles accepting/declining location requests.
class LocationRequestNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> accept(LocationRequest request) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).acceptLocationRequest(
          request.id,
          uid1: request.fromUid,
          uid2: request.toUid,
          initiatorUid: request.fromUid,
        );
    // Immediately start tracking the requester
    ref.read(trackedUidsProvider.notifier).update(
          (s) => {...s, request.fromUid},
        );
  }

  Future<void> decline(LocationRequest request) async {
    await ref
        .read(firestoreServiceProvider)
        .declineLocationRequest(request.id);
  }
}

final locationRequestNotifier =
    NotifierProvider<LocationRequestNotifier, void>(
        LocationRequestNotifier.new);

/// Groups that are expiring within 24 hours (for warning prompts).
final expiringGroupsProvider = Provider<List<Group>>((ref) {
  final groups = ref.watch(groupsProvider).valueOrNull ?? [];
  return groups.where((g) => g.isExpiringSoon).toList();
});
