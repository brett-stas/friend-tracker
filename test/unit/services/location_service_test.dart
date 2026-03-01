import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';
import 'package:friend_tracker/data/services/location_service.dart';

@GenerateMocks([GeolocatorPlatform])
import 'location_service_test.mocks.dart';

void main() {
  late LocationService locationService;
  late MockGeolocatorPlatform mockGeolocator;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    locationService = LocationService(geolocator: mockGeolocator);
  });

  group('LocationService.checkPermission', () {
    test('returns true when permission is always granted', () async {
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);

      final result = await locationService.hasPermission();

      expect(result, isTrue);
    });

    test('returns true when permission is whileInUse', () async {
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);

      final result = await locationService.hasPermission();

      expect(result, isTrue);
    });

    test('returns false when permission is denied', () async {
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      final result = await locationService.hasPermission();

      expect(result, isFalse);
    });

    test('returns false when permission is deniedForever', () async {
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      final result = await locationService.hasPermission();

      expect(result, isFalse);
    });
  });

  group('LocationService.getCurrentPosition', () {
    test('returns position when service is enabled and permission granted', () async {
      final fakePosition = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) async => fakePosition);

      final position = await locationService.getCurrentPosition();

      expect(position, isNotNull);
      expect(position!.latitude, 37.7749);
      expect(position.longitude, -122.4194);
    });

    test('returns null when location service is disabled', () async {
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      final position = await locationService.getCurrentPosition();

      expect(position, isNull);
    });

    test('returns null when permission denied', () async {
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      final position = await locationService.getCurrentPosition();

      expect(position, isNull);
    });
  });
}
