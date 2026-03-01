import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isSharing = ref.watch(isSharingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          // Profile section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'PROFILE',
              style: GoogleFonts.oswald(
                color: GarminColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: GarminColors.orange,
                child: Icon(Icons.person, color: GarminColors.background),
              ),
              title: Text(
                user?.displayName ?? 'Unknown',
                style: const TextStyle(color: GarminColors.textPrimary),
              ),
              subtitle: Text(
                user?.email ?? '',
                style: const TextStyle(color: GarminColors.textSecondary),
              ),
            ),
          ),

          // Location section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'LOCATION SHARING',
              style: GoogleFonts.oswald(
                color: GarminColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text(
                'Share my location',
                style: TextStyle(color: GarminColors.textPrimary),
              ),
              subtitle: Text(
                isSharing
                    ? 'Friends can see where you are'
                    : 'Your location is hidden',
                style: const TextStyle(color: GarminColors.textSecondary),
              ),
              value: isSharing,
              onChanged: (v) =>
                  ref.read(locationNotifierProvider.notifier).toggleSharing(v),
            ),
          ),

          // Account section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'ACCOUNT',
              style: GoogleFonts.oswald(
                color: GarminColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: GarminColors.error),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: GarminColors.error),
              ),
              onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ),

          // User ID (for sharing with friends)
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR USER ID',
                    style: GoogleFonts.oswald(
                      color: GarminColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User ID copied'),
                          backgroundColor: GarminColors.surface,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GarminColors.surface,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: GarminColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.uid,
                              style: GoogleFonts.robotoMono(
                                color: GarminColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Icon(Icons.copy,
                              size: 16, color: GarminColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share this ID with friends so they can add you',
                    style: GoogleFonts.roboto(
                      color: GarminColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
