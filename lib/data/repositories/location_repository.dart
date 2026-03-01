import 'package:friend_tracker/data/models/user_location.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';

class LocationRepository {
  final FirestoreService _firestoreService;

  LocationRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> updateMyLocation(UserLocation location) async {
    await _firestoreService.setLocation(location.userId, location.toMap());
  }

  Future<void> setSharing(String userId, bool isSharing) async {
    await _firestoreService.setSharing(userId, isSharing);
  }

  Stream<List<UserLocation>> watchFriendsLocations(String myUserId) {
    return _firestoreService
        .watchFriendsLocations(myUserId)
        .map((list) => list.map(UserLocation.fromMap).toList());
  }
}
