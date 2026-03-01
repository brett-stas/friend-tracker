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
                  color: GarminColors.textPrimary,
                  letterSpacing: 2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: 60,
                color: GarminColors.orange,
              ),
              const SizedBox(height: 8),
              Text(
                'Share your location with friends',
                style: GoogleFonts.roboto(
                  color: GarminColors.textSecondary,
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
                    style: const TextStyle(color: GarminColors.textPrimary),
                  ),
                ),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                style: const TextStyle(color: GarminColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                style: const TextStyle(color: GarminColors.textPrimary),
              ),
              const SizedBox(height: 24),
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.error.toString(),
                    style: const TextStyle(color: GarminColors.error),
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
                          color: GarminColors.background,
                        ),
                      )
                    : Text(_isRegister ? 'CREATE ACCOUNT' : 'SIGN IN'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                  style: const TextStyle(color: GarminColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
