import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/data/models/location_request.dart';
import 'package:friend_tracker/presentation/providers/tracking_providers.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(incomingLocationRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'INCOMING REQUESTS',
          style: GoogleFonts.oswald(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: GTrackerColors.error)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      color: GTrackerColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No pending requests',
                    style: GoogleFonts.roboto(
                      color: GTrackerColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (context2, index2) =>
                const Divider(color: GTrackerColors.divider),
            itemBuilder: (context, index) =>
                _RequestTile(request: list[index]),
          );
        },
      ),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final LocationRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.person_pin_circle,
              color: GTrackerColors.orange, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromDisplayName,
                  style: GoogleFonts.oswald(
                    color: GTrackerColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Wants to share locations with you',
                  style: GoogleFonts.roboto(
                    color: GTrackerColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Decline
          IconButton(
            icon: const Icon(Icons.close, color: GTrackerColors.error),
            tooltip: 'Decline',
            onPressed: () => ref
                .read(locationRequestNotifier.notifier)
                .decline(request),
          ),
          // Accept
          IconButton(
            icon: const Icon(Icons.check, color: GTrackerColors.orange),
            tooltip: 'Accept',
            onPressed: () =>
                ref.read(locationRequestNotifier.notifier).accept(request),
          ),
        ],
      ),
    );
  }
}
