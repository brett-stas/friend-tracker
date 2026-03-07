import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';
import 'package:friend_tracker/presentation/providers/tracking_providers.dart';

// Hues and matching label colours cycle in the same order
const _markerHues = [
  BitmapDescriptor.hueBlue,
  BitmapDescriptor.hueCyan,
  BitmapDescriptor.hueGreen,
  BitmapDescriptor.hueViolet,
  BitmapDescriptor.hueYellow,
  BitmapDescriptor.hueRose,
];

const _chipColors = [
  Color(0xFF2196F3),
  Color(0xFF00BCD4),
  Color(0xFF4CAF50),
  Color(0xFF9C27B0),
  Color(0xFFFFEB3B),
  Color(0xFFE91E63),
];

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  final _codeCtrl = TextEditingController();
  String? _inputError;
  bool _looking = false;

  static const _defaultPos = LatLng(37.7749, -122.4194);

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _trackByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 12) {
      setState(() => _inputError = 'Code must be 12 characters');
      return;
    }
    setState(() {
      _looking = true;
      _inputError = null;
    });

    final firestore = ref.read(firestoreServiceProvider);
    final me = ref.read(authStateProvider).value;

    // ── Try as user share code first ──────────────────────────────────────
    final uid = await firestore.findUidByShareCode(code);

    if (uid != null) {
      setState(() => _looking = false);
      if (uid == me?.uid) {
        setState(() => _inputError = "That's YOUR code — track someone else!");
        return;
      }
      if (ref.read(trackedUidsProvider).contains(uid)) {
        setState(() => _inputError = 'Already tracking this person');
        return;
      }
      ref.read(trackedUidsProvider.notifier).update((s) => {...s, uid});
      _codeCtrl.clear();
      _animateCameraToUid(uid);
      return;
    }

    // ── Try as group code ─────────────────────────────────────────────────
    final group = await firestore.findGroupByCode(code);
    setState(() => _looking = false);

    if (group == null) {
      setState(() => _inputError = 'No user or group found with that code');
      return;
    }

    // Add all confirmed group members to tracked set (excluding self)
    final newUids =
        group.memberUids.where((u) => u != me?.uid).toList();
    if (newUids.isEmpty) {
      setState(() => _inputError = 'No other members in that group yet');
      return;
    }
    ref.read(trackedUidsProvider.notifier).update(
          (s) => {...s, ...newUids},
        );
    _codeCtrl.clear();

    // Animate to first group member with a location
    for (final u in newUids) {
      final data = await firestore.watchUserData(u).first;
      final lat = data?['latitude'] as double?;
      final lng = data?['longitude'] as double?;
      if (lat != null && lng != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12),
        );
        break;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Tracking ${newUids.length} member${newUids.length == 1 ? '' : 's'} of "${group.title}"'),
      duration: const Duration(seconds: 3),
    ));
  }

  void _animateCameraToUid(String uid) {
    ref.read(firestoreServiceProvider).watchUserData(uid).first.then((data) {
      final lat = data?['latitude'] as double?;
      final lng = data?['longitude'] as double?;
      if (lat != null && lng != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
        );
      }
    });
  }

  void _stopTracking(String uid) {
    ref.read(trackedUidsProvider.notifier).update((s) => {...s}..remove(uid));
  }

  void _showMarkerOptions(
    BuildContext context,
    String uid,
    String displayName,
    Map<String, String> nicknames,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GTrackerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      isScrollControlled: true,
      builder: (_) => _MarkerOptionsSheet(
        uid: uid,
        displayName: displayName,
        currentNickname: nicknames[uid],
        onStopTracking: () {
          Navigator.pop(context);
          _stopTracking(uid);
        },
        onSaveNickname: (nickname) async {
          final me = ref.read(authStateProvider).value;
          if (me == null) return;
          final firestore = ref.read(firestoreServiceProvider);
          if (nickname.isEmpty) {
            await firestore.removeNickname(me.uid, uid);
          } else {
            await firestore.setNickname(me.uid, uid, nickname);
          }
        },
      ),
    );
  }

  // ── Map markers ───────────────────────────────────────────────────────────

  Set<Marker> _buildMarkers(
    double? myLat,
    double? myLng,
    List<String> orderedUids,
    Map<String, Map<String, dynamic>> trackedData,
    Map<String, String> nicknames,
  ) {
    final markers = <Marker>{};

    if (myLat != null && myLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(myLat, myLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You'),
        zIndexInt: 1,
      ));
    }

    for (var i = 0; i < orderedUids.length; i++) {
      final uid = orderedUids[i];
      final data = trackedData[uid];
      if (data == null) continue;
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat == null || lng == null) continue;

      final displayName = data['displayName'] as String? ?? 'Friend';
      final label = nicknames[uid] ?? displayName;

      markers.add(Marker(
        markerId: MarkerId(uid),
        position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            _markerHues[i % _markerHues.length]),
        infoWindow: InfoWindow(
          title: label,
          snippet: 'Tap for orders',
        ),
        onTap: () => _showMarkerOptions(context, uid, displayName, nicknames),
      ));
    }

    return markers;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final myLocation = ref.watch(myLocationProvider);
    final shareCode = ref.watch(myShareCodeProvider);
    final trackedUids = ref.watch(trackedUidsProvider);
    final orderedUids = trackedUids.toList();
    final nicknames = ref.watch(nicknamesProvider).valueOrNull ?? {};

    // Collect location data for each tracked user
    final trackedData = <String, Map<String, dynamic>>{};
    for (final uid in orderedUids) {
      final data = ref.watch(trackedUserProvider(uid)).valueOrNull;
      if (data != null) trackedData[uid] = data;
    }

    // Publish my location to Firestore whenever it updates
    ref.listen(myLocationProvider, (_, next) async {
      final pos = next.valueOrNull;
      final user = ref.read(authStateProvider).value;
      if (pos == null || user == null) return;
      await ref.read(firestoreServiceProvider).updateLocationInProfile(
            user.uid,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
    });

    final myPos = myLocation.valueOrNull;
    final hasTracked = orderedUids.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          // ── Map section (expands to fill remaining space) ────────────────
          Expanded(
            child: Stack(
              children: [
                myLocation.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Location error: $e',
                        style: const TextStyle(color: GTrackerColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (pos) => GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: pos != null
                          ? LatLng(pos.latitude, pos.longitude)
                          : _defaultPos,
                      zoom: 14,
                    ),
                    onMapCreated: (c) => _mapController = c,
                    markers: _buildMarkers(
                      pos?.latitude,
                      pos?.longitude,
                      orderedUids,
                      trackedData,
                      nicknames,
                    ),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    style: _darkMapStyle,
                  ),
                ),

                // ── Top bar: share code + sign-out (overlays map) ──────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: shareCode.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (code) {
                              final displayName = ref
                                      .watch(authStateProvider)
                                      .value
                                      ?.displayName ??
                                  '';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: GTrackerColors.surface.withAlpha(230),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                      color: GTrackerColors.orange),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    // ── Name + code ────────────────────
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (displayName.isNotEmpty)
                                          Text(
                                            displayName.toUpperCase(),
                                            style: GoogleFonts.oswald(
                                              color: GTrackerColors
                                                  .textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(
                                                ClipboardData(text: code));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Share code copied to clipboard'),
                                                duration:
                                                    Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'CODE  ',
                                                style: GoogleFonts.oswald(
                                                  color: GTrackerColors
                                                      .textSecondary,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              Text(
                                                code,
                                                style:
                                                    GoogleFonts.robotoMono(
                                                  color:
                                                      GTrackerColors.orange,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.copy,
                                                color: GTrackerColors
                                                    .textSecondary,
                                                size: 11,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // ── Recenter-on-me ─────────────────
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        if (myPos != null) {
                                          _mapController?.animateCamera(
                                            CameraUpdate.newLatLngZoom(
                                              LatLng(myPos.latitude,
                                                  myPos.longitude),
                                              15,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Icon(
                                        Icons.my_location,
                                        color: GTrackerColors.orange,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: GTrackerColors.surface.withAlpha(230),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.logout,
                              color: GTrackerColors.textSecondary,
                              size: 20,
                            ),
                            tooltip: 'Retreat',
                            onPressed: () =>
                                ref.read(authNotifierProvider.notifier).signOut(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Recenter FAB (overlays map, bottom-right) ───────────────
                Positioned(
                  bottom: 16,
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
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: GTrackerColors.surface,
              border: Border(
                  top: BorderSide(color: GTrackerColors.divider, width: 1)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Code entry row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 12,
                        style: GoogleFonts.robotoMono(
                          color: GTrackerColors.textPrimary,
                          fontSize: 15,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'USER OR GROUP CODE',
                          hintStyle: GoogleFonts.robotoMono(
                            color: GTrackerColors.textMuted,
                            fontSize: 13,
                            letterSpacing: 2,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2E2E2E),
                          counterText: '',
                          errorText: _inputError,
                          errorStyle: GoogleFonts.roboto(
                            color: GTrackerColors.error,
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2),
                            borderSide: const BorderSide(
                                color: GTrackerColors.orange, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        onSubmitted: (_) => _trackByCode(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 88,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _looking ? null : _trackByCode,
                        child: _looking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'TRACK EM',
                                style: GoogleFonts.oswald(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),

                // Tracked user chips (with nickname + stop-tracking icon)
                if (hasTracked) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: orderedUids.asMap().entries.map((entry) {
                      final i = entry.key;
                      final uid = entry.value;
                      final data = trackedData[uid];
                      final displayName =
                          data?['displayName'] as String? ?? '...';
                      final label = nicknames[uid] ?? displayName;
                      final color = _chipColors[i % _chipColors.length];
                      return GestureDetector(
                        onTap: () => _animateCameraToUid(uid),
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundColor: color,
                            radius: 8,
                          ),
                          label: Text(
                            label,
                            style: GoogleFonts.roboto(
                              color: GTrackerColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: GTrackerColors.card,
                          deleteIcon: const Icon(
                            Icons.location_off,
                            size: 16,
                          ),
                          deleteIconColor: GTrackerColors.error,
                          deleteButtonTooltipMessage: 'Terminate tracking',
                          side: BorderSide(color: color.withAlpha(120)),
                          onDeleted: () => _stopTracking(uid),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Groups section
                _GroupsSection(
                  orderedUids: orderedUids,
                  trackedData: trackedData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Marker Options Bottom Sheet ───────────────────────────────────────────────

class _MarkerOptionsSheet extends StatefulWidget {
  final String uid;
  final String displayName;
  final String? currentNickname;
  final VoidCallback onStopTracking;
  final Future<void> Function(String nickname) onSaveNickname;

  const _MarkerOptionsSheet({
    required this.uid,
    required this.displayName,
    required this.currentNickname,
    required this.onStopTracking,
    required this.onSaveNickname,
  });

  @override
  State<_MarkerOptionsSheet> createState() => _MarkerOptionsSheetState();
}

class _MarkerOptionsSheetState extends State<_MarkerOptionsSheet> {
  bool _editingNickname = false;
  late final TextEditingController _nickCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(text: widget.currentNickname ?? '');
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    setState(() => _saving = true);
    await widget.onSaveNickname(_nickCtrl.text.trim());
    if (mounted) setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.person_pin_circle,
                  color: GTrackerColors.orange, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentNickname ?? widget.displayName,
                    style: GoogleFonts.oswald(
                      color: GTrackerColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.currentNickname != null)
                    Text(
                      widget.displayName,
                      style: GoogleFonts.roboto(
                        color: GTrackerColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: GTrackerColors.divider),
          const SizedBox(height: 4),

          if (_editingNickname) ...[
            TextField(
              controller: _nickCtrl,
              autofocus: true,
              style: GoogleFonts.roboto(
                color: GTrackerColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                labelText: 'Callsign',
                labelStyle:
                    const TextStyle(color: GTrackerColors.textSecondary),
                hintText: widget.displayName,
                hintStyle: const TextStyle(color: GTrackerColors.textMuted),
                filled: true,
                fillColor: const Color(0xFF2E2E2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                      color: GTrackerColors.orange, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _saveNickname(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _editingNickname = false),
                    child: Text(
                      'ABORT',
                      style: GoogleFonts.oswald(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveNickname,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'LOCKED IN',
                            style: GoogleFonts.oswald(
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ListTile(
              leading:
                  const Icon(Icons.edit, color: GTrackerColors.textSecondary),
              title: Text(
                'Change Callsign',
                style: GoogleFonts.roboto(color: GTrackerColors.textPrimary),
              ),
              subtitle: widget.currentNickname != null
                  ? Text(
                      widget.currentNickname!,
                      style: GoogleFonts.roboto(
                          color: GTrackerColors.orange, fontSize: 12),
                    )
                  : null,
              onTap: () => setState(() => _editingNickname = true),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading:
                  const Icon(Icons.location_off, color: GTrackerColors.error),
              title: Text(
                'Terminate Tracking',
                style: GoogleFonts.roboto(color: GTrackerColors.error),
              ),
              onTap: widget.onStopTracking,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Groups Section ────────────────────────────────────────────────────────────

class _GroupsSection extends ConsumerWidget {
  final List<String> orderedUids;
  final Map<String, Map<String, dynamic>> trackedData;

  const _GroupsSection({
    required this.orderedUids,
    required this.trackedData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    final groups = ref.watch(groupsProvider).valueOrNull ?? [];
    final trackedUids = ref.watch(trackedUidsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(color: GTrackerColors.divider, height: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GROUPS',
              style: GoogleFonts.oswald(
                color: GTrackerColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  _showCreateGroupDialog(context, ref, user.uid),
              icon:
                  const Icon(Icons.add, size: 16, color: GTrackerColors.orange),
              label: Text(
                'CREATE GROUP',
                style: GoogleFonts.oswald(
                  color: GTrackerColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No groups yet. Create one to track your team!',
              style: GoogleFonts.roboto(
                color: GTrackerColors.textMuted,
                fontSize: 13,
              ),
            ),
          )
        else
          ...groups.map((group) {
            final allActive =
                group.memberUids.every((uid) => trackedUids.contains(uid));
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading:
                  const Icon(Icons.group, color: GTrackerColors.orange, size: 20),
              title: Text(
                group.title,
                style: GoogleFonts.roboto(
                  color: GTrackerColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${group.memberUids.length} traveller${group.memberUids.length == 1 ? '' : 's'}',
                style: GoogleFonts.roboto(
                  color: GTrackerColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      allActive ? Icons.stop_circle : Icons.play_circle,
                      color: allActive
                          ? GTrackerColors.error
                          : GTrackerColors.orange,
                    ),
                    tooltip: allActive ? 'Stop tracking group' : 'Start tracking group',
                    onPressed: () {
                      if (allActive) {
                        ref
                            .read(groupTrackingNotifier.notifier)
                            .stopGroup(group);
                      } else {
                        ref
                            .read(groupTrackingNotifier.notifier)
                            .startGroup(group);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: GTrackerColors.textSecondary),
                    tooltip: 'Delete group',
                    onPressed: () => ref
                        .read(firestoreServiceProvider)
                        .deleteGroup(group.id),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showCreateGroupDialog(
      BuildContext context, WidgetRef ref, String myUid) {
    showDialog(
      context: context,
      builder: (_) => _CreateGroupDialog(
        myUid: myUid,
        onConfirm: (name, invitedMembers, endDate) async {
          final fs = ref.read(firestoreServiceProvider);
          final me = ref.read(authStateProvider).value;
          final myName = me?.displayName ?? 'Someone';
          final group = await fs.createGroup(
            creatorUid: myUid,
            title: name,
            invitedUids: invitedMembers.keys.toList(),
            endDate: endDate,
          );
          for (final uid in invitedMembers.keys) {
            await fs.sendGroupInvite(
              groupId: group.id,
              groupTitle: group.title,
              groupCode: group.groupCode,
              fromUid: myUid,
              fromDisplayName: myName,
              toUid: uid,
            );
          }
        },
      ),
    );
  }
}

// ── Create Group Dialog ───────────────────────────────────────────────────────
// Allows adding members by share code; sends an invite to each before creating.

class _CreateGroupDialog extends ConsumerStatefulWidget {
  final String myUid;
  final Future<void> Function(
      String name, Map<String, String> invitedMembers, DateTime endDate) onConfirm;

  const _CreateGroupDialog({
    required this.myUid,
    required this.onConfirm,
  });

  @override
  ConsumerState<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<_CreateGroupDialog> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _invitedMembers = <String, String>{}; // uid → displayName
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _creating = false;
  bool _looking = false;
  String? _addError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _addByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 12) {
      setState(() => _addError = 'Share code must be 12 characters');
      return;
    }
    setState(() {
      _looking = true;
      _addError = null;
    });
    final fs = ref.read(firestoreServiceProvider);
    final uid = await fs.findUidByShareCode(code);
    setState(() => _looking = false);

    if (uid == null) {
      setState(() => _addError = 'No user found with that code');
      return;
    }
    if (uid == widget.myUid) {
      setState(() => _addError = "That's your own code");
      return;
    }
    if (_invitedMembers.containsKey(uid)) {
      setState(() => _addError = 'Already added');
      return;
    }
    if (_invitedMembers.length >= 11) {
      setState(() => _addError = 'Group is full (12 members max)');
      return;
    }
    final data = await fs.watchUserData(uid).first;
    final name = data?['displayName'] as String? ?? uid;
    setState(() {
      _invitedMembers[uid] = name;
      _codeCtrl.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: GTrackerColors.orange,
            onPrimary: Colors.black,
            surface: GTrackerColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _confirm() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    await widget.onConfirm(
        _nameCtrl.text.trim(), Map.of(_invitedMembers), _endDate);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _invitedMembers.length + 1;
    return AlertDialog(
      backgroundColor: GTrackerColors.surface,
      title: Text(
        'Create Tracking Group',
        style: GoogleFonts.oswald(
          color: GTrackerColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: GoogleFonts.roboto(
                    color: GTrackerColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Group name',
                  labelStyle:
                      const TextStyle(color: GTrackerColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFF2E2E2E),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                          color: GTrackerColors.orange, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: GTrackerColors.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Ends ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: GoogleFonts.roboto(
                            color: GTrackerColors.textPrimary, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit,
                          color: GTrackerColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'INVITE MEMBERS  $totalCount / 12',
                style: GoogleFonts.oswald(
                  color: GTrackerColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.robotoMono(
                          color: GTrackerColors.textPrimary,
                          fontSize: 13,
                          letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'ENTER SHARE CODE',
                        hintStyle: GoogleFonts.robotoMono(
                            color: GTrackerColors.textMuted,
                            fontSize: 12,
                            letterSpacing: 2),
                        filled: true,
                        fillColor: const Color(0xFF2E2E2E),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                                color: GTrackerColors.orange, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                      ),
                      onSubmitted: (_) => _addByCode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _looking ? null : _addByCode,
                      child: _looking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text('ADD',
                              style: GoogleFonts.oswald(
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              if (_addError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_addError!,
                      style: GoogleFonts.roboto(
                          color: GTrackerColors.error, fontSize: 11)),
                ),
              if (_invitedMembers.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._invitedMembers.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              color: GTrackerColors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.value,
                                    style: GoogleFonts.roboto(
                                        color: GTrackerColors.textPrimary,
                                        fontSize: 13)),
                                Text('Invite pending',
                                    style: GoogleFonts.roboto(
                                        color: GTrackerColors.textMuted,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: GTrackerColors.error, size: 16),
                            onPressed: () =>
                                setState(() => _invitedMembers.remove(e.key)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Enter a share code above to invite people.',
                    style: GoogleFonts.roboto(
                        color: GTrackerColors.textMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL',
              style: GoogleFonts.oswald(
                  color: GTrackerColors.textSecondary,
                  fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _confirm,
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text('CREATE',
                  style: GoogleFonts.oswald(fontWeight: FontWeight.w700)),
        ),
      ],
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
