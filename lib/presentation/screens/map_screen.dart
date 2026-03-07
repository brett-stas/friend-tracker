import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/data/models/user_location.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  static const _defaultLatLng = LatLng(37.7749, -122.4194);

  Set<Marker> _buildMarkers(
    Position? myPos,
    List<UserLocation> friends,
  ) {
    final markers = <Marker>{};

    if (myPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(myPos.latitude, myPos.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    }

    for (final friend in friends) {
      markers.add(Marker(
        markerId: MarkerId(friend.userId),
        position: LatLng(friend.latitude, friend.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: friend.displayName),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final myLocation = ref.watch(myLocationProvider);
    final friendsLocations = ref.watch(friendsLocationsProvider);
    final isSharing = ref.watch(isSharingProvider);

    final myPos = myLocation.valueOrNull;
    final friends = friendsLocations.valueOrNull ?? [];
    final onlineFriends = friends.where((f) => f.isSharing).toList();

    return Scaffold(
      body: Stack(
        children: [
          myLocation.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Location error: $e',
                  style: const TextStyle(color: GTrackerColors.error)),
            ),
            data: (pos) => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: pos != null
                    ? LatLng(pos.latitude, pos.longitude)
                    : _defaultLatLng,
                zoom: 14,
              ),
              onMapCreated: (c) => _mapController = c,
              markers: _buildMarkers(pos, onlineFriends),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              style: _darkMapStyle,
            ),
          ),

          // Top status bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (onlineFriends.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: GTrackerColors.surface.withAlpha(230),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: GTrackerColors.orange),
                      ),
                      child: Text(
                        '${onlineFriends.length} friend${onlineFriends.length == 1 ? '' : 's'} online',
                        style: GoogleFonts.oswald(
                          color: GTrackerColors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Share toggle
                  Container(
                    key: const Key('shareToggle'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: GTrackerColors.surface.withAlpha(230),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SHARE',
                          style: GoogleFonts.oswald(
                            color: isSharing
                                ? GTrackerColors.orange
                                : GTrackerColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isSharing,
                          onChanged: (v) => ref
                              .read(locationNotifierProvider.notifier)
                              .toggleSharing(v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recenter FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: GTrackerColors.surface,
              foregroundColor: GTrackerColors.orange,
              onPressed: () {
                if (myPos != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(myPos.latitude, myPos.longitude),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

const _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]}
]''';
