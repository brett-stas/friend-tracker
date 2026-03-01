import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:friend_tracker/data/models/user_location.dart';
import 'package:friend_tracker/data/repositories/location_repository.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';

@GenerateMocks([FirestoreService])
import 'location_repository_test.mocks.dart';

void main() {
  late LocationRepository repository;
  late MockFirestoreService mockFirestore;

  setUp(() {
    mockFirestore = MockFirestoreService();
    repository = LocationRepository(firestoreService: mockFirestore);
  });

  group('LocationRepository.updateMyLocation', () {
    test('calls firestoreService with correct data', () async {
      final location = UserLocation(
        userId: 'me',
        displayName: 'Me',
        latitude: 37.7749,
        longitude: -122.4194,
        updatedAt: DateTime(2025, 1, 1),
        isSharing: true,
      );

      when(mockFirestore.setLocation(any, any)).thenAnswer((_) async {});

      await repository.updateMyLocation(location);

      verify(mockFirestore.setLocation('me', location.toMap())).called(1);
    });
  });

  group('LocationRepository.getFriendsLocations', () {
    test('returns stream of UserLocation list', () async {
      final mockData = [
        {
          'userId': 'friend1',
          'displayName': 'Friend One',
          'latitude': 40.7128,
          'longitude': -74.0060,
          'updatedAt': 1700000000000,
          'isSharing': true,
        }
      ];

      when(mockFirestore.watchFriendsLocations('me'))
          .thenAnswer((_) => Stream.value(mockData));

      final stream = repository.watchFriendsLocations('me');
      final locations = await stream.first;

      expect(locations.length, 1);
      expect(locations.first.displayName, 'Friend One');
    });

    test('returns empty list when no friends are sharing', () async {
      when(mockFirestore.watchFriendsLocations('me'))
          .thenAnswer((_) => Stream.value([]));

      final stream = repository.watchFriendsLocations('me');
      final locations = await stream.first;

      expect(locations, isEmpty);
    });
  });

  group('LocationRepository.setSharing', () {
    test('updates sharing flag in firestore', () async {
      when(mockFirestore.setSharing('me', false)).thenAnswer((_) async {});

      await repository.setSharing('me', false);

      verify(mockFirestore.setSharing('me', false)).called(1);
    });
  });
}
