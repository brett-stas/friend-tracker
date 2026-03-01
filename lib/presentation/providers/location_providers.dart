import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friend_tracker/data/models/user_location.dart';
import 'package:friend_tracker/data/repositories/location_repository.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';
import 'package:friend_tracker/data/services/location_service.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final locationServiceProvider = Provider((ref) => LocationService());

final locationRepositoryProvider = Provider((ref) => LocationRepository(
      firestoreService: ref.watch(firestoreServiceProvider),
    ));

final isSharingProvider = StateProvider<bool>((ref) => false);

final myLocationProvider = StreamProvider<Position?>((ref) async* {
  final service = ref.watch(locationServiceProvider);
  final hasPermission = await service.hasPermission();
  if (!hasPermission) {
    yield null;
    return;
  }
  yield* service.watchPosition().map((p) => p);
});

final friendsLocationsProvider =
    StreamProvider<List<UserLocation>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .watch(locationRepositoryProvider)
      .watchFriendsLocations(user.uid);
});

class LocationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> publishLocation(Position position) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final isSharing = ref.read(isSharingProvider);
    if (!isSharing) return;

    final repo = ref.read(locationRepositoryProvider);
    await repo.updateMyLocation(UserLocation(
      userId: user.uid,
      displayName: user.displayName ?? 'Me',
      latitude: position.latitude,
      longitude: position.longitude,
      updatedAt: DateTime.now(),
      isSharing: true,
    ));
  }

  Future<void> toggleSharing(bool value) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    ref.read(isSharingProvider.notifier).state = value;
    final repo = ref.read(locationRepositoryProvider);
    await repo.setSharing(user.uid, value);
  }
}

final locationNotifierProvider =
    AsyncNotifierProvider<LocationNotifier, void>(LocationNotifier.new);
