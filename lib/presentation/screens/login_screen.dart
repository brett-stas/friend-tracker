import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    if (_isRegister) {
      await notifier.registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
    } else {
      await notifier.signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'FRIEND\nTRACKER',
                style: GoogleFonts.oswald(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: GTrackerColors.textPrimary,
                  letterSpacing: 2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: 60,
                color: GTrackerColors.orange,
              ),
              const SizedBox(height: 8),
              Text(
                'Track your mates, stay safe, stay in touch.',
                style: GoogleFonts.roboto(
                  color: GTrackerColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              if (_isRegister)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Display Name'),
                    style: const TextStyle(color: GTrackerColors.textPrimary),
                  ),
                ),
              TextField(
                controller: _emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
                style: const TextStyle(color: GTrackerColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Password'),
                style: const TextStyle(color: GTrackerColors.textPrimary),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: GTrackerColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _friendlyAuthError(authState.error),
                          style: const TextStyle(color: GTrackerColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GTrackerColors.background,
                        ),
                      )
                    : Text(_isRegister ? 'JOIN THE TEAM' : 'ENGAGE'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister
                      ? 'Already enlisted? Sign in'
                      : 'Ready to track?',
                  style: const TextStyle(color: GTrackerColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyAuthError(Object? error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'That doesn\'t look like a valid email address.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
    }
  }
  return 'Your username and password are not validating.';
}
