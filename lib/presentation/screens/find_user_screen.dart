import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';

class FindUserScreen extends ConsumerStatefulWidget {
  const FindUserScreen({super.key});

  @override
  ConsumerState<FindUserScreen> createState() => _FindUserScreenState();
}

class _FindUserScreenState extends ConsumerState<FindUserScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  bool _sending = false;
  Map<String, dynamic>? _foundUser;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
      _foundUser = null;
      _successMessage = null;
    });

    final firestore = ref.read(firestoreServiceProvider);
    final me = ref.read(authStateProvider).value;
    Map<String, dynamic>? found;

    // Try share code first (6–13 chars with optional dash, any case)
    if (RegExp(r'^[A-Za-z0-9]{6,12}$').hasMatch(query.replaceAll('-', ''))) {
      final uid = await firestore.findUidByShareCode(query);
      if (uid != null) {
        final data = await firestore.watchUserData(uid).first;
        if (data != null) found = data;
      }
    }

    // Fall back to email/name search
    found ??= await firestore.findUserByEmailOrName(query);

    setState(() => _searching = false);

    if (found == null) {
      setState(() => _error = 'No user found. Check the share code or name.');
      return;
    }
    if (found['uid'] == me?.uid) {
      setState(() => _error = "That's you — find someone else!");
      return;
    }

    setState(() => _foundUser = found);
  }

  Future<void> _sendRequest() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _foundUser == null) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref.read(firestoreServiceProvider).sendLocationRequest(
            fromUid: user.uid,
            fromDisplayName: user.displayName ?? 'User',
            toUid: _foundUser!['uid'] as String,
          );
      setState(() {
        _sending = false;
        _successMessage =
            'Location request sent to ${_foundUser!['displayName'] ?? 'them'}!';
        _foundUser = null;
        _searchCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _sending = false;
        _error = 'Failed to send request. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FIND A TRACKER',
          style: GoogleFonts.oswald(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter a share code, username, or email address.',
              style: GoogleFonts.roboto(
                color: GTrackerColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Search field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textCapitalization: TextCapitalization.none,
                    style: GoogleFonts.robotoMono(
                      color: GTrackerColors.textPrimary,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'SHARE CODE / EMAIL / NAME',
                      hintStyle: GoogleFonts.robotoMono(
                        color: GTrackerColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2E2E2E),
                      errorText: _error,
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
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _search,
                    child: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            'SEARCH',
                            style: GoogleFonts.oswald(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                  ),
                ),
              ],
            ),

            // Success message
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GTrackerColors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GTrackerColors.orange),
                ),
                child: Text(
                  _successMessage!,
                  style: GoogleFonts.roboto(
                    color: GTrackerColors.orange,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            // Found user card
            if (_foundUser != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GTrackerColors.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GTrackerColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle,
                            color: GTrackerColors.orange, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundUser!['displayName'] as String? ?? 'Unknown',
                              style: GoogleFonts.oswald(
                                color: GTrackerColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_foundUser!['email'] != null)
                              Text(
                                _foundUser!['email'] as String,
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _sendRequest,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.send, size: 16),
                        label: Text(
                          'SEND LOCATION REQUEST',
                          style: GoogleFonts.oswald(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
