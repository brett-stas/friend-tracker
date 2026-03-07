import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/tracking_providers.dart';
import 'package:friend_tracker/presentation/screens/find_user_screen.dart';
import 'package:friend_tracker/presentation/screens/icon_picker_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final myData = user == null
        ? null
        : ref.watch(trackedUserProvider(user.uid)).valueOrNull;
    final currentIconName = myData?['iconName'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Profile section
          _SectionHeader('PROFILE'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: GTrackerColors.orange,
                child: currentIconName != null
                    ? FaIcon(
                        iconDataFromName(currentIconName),
                        color: Colors.black,
                        size: 18,
                      )
                    : const Icon(Icons.person, color: GTrackerColors.background),
              ),
              title: Text(
                user?.displayName ?? 'Unknown',
                style: const TextStyle(color: GTrackerColors.textPrimary),
              ),
              subtitle: Text(
                user?.email ?? '',
                style: const TextStyle(color: GTrackerColors.textSecondary),
              ),
            ),
          ),

          // Change display name
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit, color: GTrackerColors.orange),
              title: Text(
                'Change Display Name',
                style: GoogleFonts.roboto(color: GTrackerColors.textPrimary),
              ),
              subtitle: Text(
                'Name must be unique',
                style: GoogleFonts.roboto(
                    color: GTrackerColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: GTrackerColors.textSecondary),
              onTap: () => _showChangeNameDialog(
                  context, ref, user?.displayName ?? ''),
            ),
          ),

          // Icon picker
          Card(
            child: ListTile(
              leading: const Icon(Icons.tag_faces_outlined,
                  color: GTrackerColors.orange),
              title: Text(
                'Choose Your Icon',
                style: GoogleFonts.roboto(color: GTrackerColors.textPrimary),
              ),
              subtitle: Text(
                currentIconName != null
                    ? 'Current: $currentIconName'
                    : 'No icon set — tap to choose',
                style:
                    GoogleFonts.roboto(color: GTrackerColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: GTrackerColors.textSecondary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      IconPickerScreen(currentIconName: currentIconName),
                ),
              ),
            ),
          ),

          // Find user / send request
          _SectionHeader('TRACKING'),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.person_search, color: GTrackerColors.orange),
              title: Text(
                'Find a Tracker',
                style: GoogleFonts.roboto(color: GTrackerColors.textPrimary),
              ),
              subtitle: Text(
                'Send a location sharing request',
                style:
                    GoogleFonts.roboto(color: GTrackerColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: GTrackerColors.textSecondary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindUserScreen()),
              ),
            ),
          ),

          // Share code
          _SectionHeader('YOUR SHARE CODE'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ref.watch(myShareCodeProvider).when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (code) => GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Share code copied to clipboard')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GTrackerColors.card,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: GTrackerColors.orange),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              code,
                              style: GoogleFonts.robotoMono(
                                color: GTrackerColors.orange,
                                fontSize: 18,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.copy,
                              size: 16, color: GTrackerColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Share this code or your email so others can find you.',
              style: GoogleFonts.roboto(
                color: GTrackerColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),

          // Account section
          _SectionHeader('ACCOUNT'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: GTrackerColors.error),
              title: Text(
                'Sign Out',
                style: GoogleFonts.roboto(color: GTrackerColors.error),
              ),
              onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

Future<void> _showChangeNameDialog(
    BuildContext context, WidgetRef ref, String currentName) async {
  final controller = TextEditingController(text: currentName);
  String? errorText;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: GTrackerColors.surface,
        title: Text(
          'CHANGE DISPLAY NAME',
          style: GoogleFonts.oswald(
            color: GTrackerColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          style: GoogleFonts.roboto(color: GTrackerColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Display name',
            labelStyle:
                GoogleFonts.roboto(color: GTrackerColors.textSecondary),
            errorText: errorText,
            counterStyle:
                GoogleFonts.roboto(color: GTrackerColors.textMuted, fontSize: 11),
          ),
          onChanged: (_) {
            if (errorText != null) setState(() => errorText = null);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: GoogleFonts.oswald(color: GTrackerColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                setState(() => errorText = 'Name cannot be empty');
                return;
              }
              if (name == currentName) {
                Navigator.pop(ctx);
                return;
              }
              try {
                await ref
                    .read(authNotifierProvider.notifier)
                    .updateDisplayName(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Display name updated to "$name"'),
                    duration: const Duration(seconds: 2),
                  ));
                }
              } on Exception catch (e) {
                final msg = e.toString().contains('display-name-taken')
                    ? 'That name is already taken — choose a different one.'
                    : 'Something went wrong. Try again.';
                setState(() => errorText = msg);
              }
            },
            child: Text('SAVE',
                style: GoogleFonts.oswald(color: GTrackerColors.orange)),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: GoogleFonts.oswald(
          color: GTrackerColors.textSecondary,
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
