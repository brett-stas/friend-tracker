import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

// Admin UID — only this user sees the dashboard.
// Replace with your actual Firebase UID.
const String kAdminUid = 'REPLACE_WITH_YOUR_ADMIN_UID';

final totalUsersProvider = StreamProvider<int>((ref) {
  return ref.watch(firestoreServiceProvider).watchTotalUsersCount();
});

final activeUsersProvider = StreamProvider<int>((ref) {
  return ref.watch(firestoreServiceProvider).watchActiveUsersCount();
});

final activeGroupsProvider = StreamProvider<int>((ref) {
  return ref.watch(firestoreServiceProvider).watchActiveGroupsCount();
});

final pendingRequestsProvider = StreamProvider<int>((ref) {
  return ref.watch(firestoreServiceProvider).watchPendingRequestsCount();
});
