import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

/// Curated list of Font Awesome icons available as user avatars.
// ignore: library_private_types_in_public_api
const List<_IconOption> kAvatarIcons = [
  _IconOption('rocket', FontAwesomeIcons.rocket),
  _IconOption('star', FontAwesomeIcons.star),
  _IconOption('bolt', FontAwesomeIcons.bolt),
  _IconOption('dragon', FontAwesomeIcons.dragon),
  _IconOption('ghost', FontAwesomeIcons.ghost),
  _IconOption('skull', FontAwesomeIcons.skull),
  _IconOption('crown', FontAwesomeIcons.crown),
  _IconOption('fire', FontAwesomeIcons.fire),
  _IconOption('snowflake', FontAwesomeIcons.snowflake),
  _IconOption('shield', FontAwesomeIcons.shieldHalved),
  _IconOption('cat', FontAwesomeIcons.cat),
  _IconOption('dog', FontAwesomeIcons.dog),
  _IconOption('crow', FontAwesomeIcons.crow),
  _IconOption('fish', FontAwesomeIcons.fish),
  _IconOption('spider', FontAwesomeIcons.spider),
  _IconOption('frog', FontAwesomeIcons.frog),
  _IconOption('paw', FontAwesomeIcons.paw),
  _IconOption('feather', FontAwesomeIcons.feather),
  _IconOption('leaf', FontAwesomeIcons.leaf),
  _IconOption('gem', FontAwesomeIcons.gem),
  _IconOption('motorcycle', FontAwesomeIcons.motorcycle),
  _IconOption('plane', FontAwesomeIcons.plane),
  _IconOption('ship', FontAwesomeIcons.ship),
  _IconOption('bicycle', FontAwesomeIcons.bicycle),
  _IconOption('person-running', FontAwesomeIcons.personRunning),
  _IconOption('person-hiking', FontAwesomeIcons.personHiking),
  _IconOption('mountain', FontAwesomeIcons.mountain),
  _IconOption('tree', FontAwesomeIcons.tree),
  _IconOption('sun', FontAwesomeIcons.sun),
  _IconOption('moon', FontAwesomeIcons.moon),
];

class _IconOption {
  final String name;
  final IconData icon;
  const _IconOption(this.name, this.icon);
}

/// Returns the [IconData] for a stored icon name, or a default pin icon.
IconData iconDataFromName(String? name) {
  if (name == null || name.isEmpty) return FontAwesomeIcons.locationDot;
  try {
    return kAvatarIcons.firstWhere((o) => o.name == name).icon;
  } catch (_) {
    return FontAwesomeIcons.locationDot;
  }
}

class IconPickerScreen extends ConsumerStatefulWidget {
  final String? currentIconName;

  const IconPickerScreen({super.key, this.currentIconName});

  @override
  ConsumerState<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends ConsumerState<IconPickerScreen> {
  String? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentIconName;
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await ref.read(firestoreServiceProvider).setUserIcon(user.uid, _selected!);
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CHOOSE YOUR ICON',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _selected == null ? null : _save,
              child: Text(
                'SAVE',
                style: GoogleFonts.oswald(
                  color: GTrackerColors.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your icon appears on the map for all other users.',
              style: GoogleFonts.roboto(
                color: GTrackerColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: kAvatarIcons.length,
                itemBuilder: (context, index) {
                  final option = kAvatarIcons[index];
                  final isSelected = _selected == option.name;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = option.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GTrackerColors.orange.withAlpha(30)
                            : GTrackerColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? GTrackerColors.orange
                              : GTrackerColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          option.icon,
                          color: isSelected
                              ? GTrackerColors.orange
                              : GTrackerColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
