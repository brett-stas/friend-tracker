import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friend_tracker/data/models/friend_request.dart';
import 'package:friend_tracker/data/repositories/friends_repository.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

final friendsRepositoryProvider = Provider((ref) => FriendsRepository(
      firestoreService: ref.watch(firestoreServiceProvider),
    ));

final friendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .watch(friendsRepositoryProvider)
      .watchIncomingRequests(user.uid);
});

final friendsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(friendsRepositoryProvider).watchFriends(user.uid);
});

class FriendsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendRequest(String toUserId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final repo = ref.read(friendsRepositoryProvider);
    await repo.sendFriendRequest(
      fromUserId: user.uid,
      fromDisplayName: user.displayName ?? 'Someone',
      toUserId: toUserId,
    );
  }

  Future<void> acceptRequest(String requestId) async {
    await ref.read(friendsRepositoryProvider).acceptRequest(requestId);
  }

  Future<void> declineRequest(String requestId) async {
    await ref.read(friendsRepositoryProvider).declineRequest(requestId);
  }
}

final friendsNotifierProvider =
    AsyncNotifierProvider<FriendsNotifier, void>(FriendsNotifier.new);
