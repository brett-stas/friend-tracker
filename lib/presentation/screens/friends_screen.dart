import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/data/models/friend_request.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/friends_providers.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(friendRequestsProvider).valueOrNull ?? [];
    final friends = ref.watch(friendsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('FRIENDS')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addFriendFab'),
        onPressed: () => _showAddFriendDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: Text(
          'ADD FRIEND',
          style: GoogleFonts.oswald(fontWeight: FontWeight.w700),
        ),
      ),
      body: friends.isEmpty && requests.isEmpty
          ? _buildEmpty()
          : CustomScrollView(
              slivers: [
                if (requests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'PENDING REQUESTS',
                        style: GoogleFonts.oswald(
                          color: GarminColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _RequestTile(request: requests[i]),
                      childCount: requests.length,
                    ),
                  ),
                ],
                if (friends.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'FRIENDS',
                        style: GoogleFonts.oswald(
                          color: GarminColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _FriendTile(friend: friends[i]),
                      childCount: friends.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 64, color: GarminColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: GoogleFonts.oswald(
              color: GarminColors.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a friend to start tracking',
            style: GoogleFonts.roboto(color: GarminColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GarminColors.card,
        title: Text(
          'ADD FRIEND',
          style: GoogleFonts.oswald(color: GarminColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Friend\'s User ID'),
          style: const TextStyle(color: GarminColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: GarminColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref
                    .read(friendsNotifierProvider.notifier)
                    .sendRequest(ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('SEND REQUEST'),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final FriendRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(friendsNotifierProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: GarminColors.divider,
              child: Icon(Icons.person, color: GarminColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${request.fromDisplayName} wants to share location',
                style: GoogleFonts.roboto(color: GarminColors.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () => notifier.declineRequest(request.id),
              child: const Text('Decline',
                  style: TextStyle(color: GarminColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => notifier.acceptRequest(request.id),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  final FriendRequest friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).value?.uid;
    final friendName = friend.fromUserId == myUid
        ? friend.toUserId
        : friend.fromDisplayName;

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: GarminColors.divider,
          child: Icon(Icons.person, color: GarminColors.orange),
        ),
        title: Text(
          friendName,
          style: GoogleFonts.roboto(color: GarminColors.textPrimary),
        ),
        trailing: const Icon(Icons.location_on,
            color: GarminColors.orange, size: 18),
      ),
    );
  }
}
