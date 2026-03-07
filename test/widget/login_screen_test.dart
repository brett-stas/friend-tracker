import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/screens/login_screen.dart';

// ── Fake AuthNotifier implementations ────────────────────────────────────────

class _OkAuthNotifier extends AuthNotifier {
  @override
  Future<void> build() async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {
    // success — state stays AsyncData(null)
  }
}

class _FailAuthNotifier extends AuthNotifier {
  final FirebaseAuthException _error;
  _FailAuthNotifier(this._error);

  @override
  Future<void> build() async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {
    state = AsyncError(_error, StackTrace.current);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _buildLogin(AuthNotifier notifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(
      theme: buildGTrackerTheme(),
      home: const LoginScreen(),
    ),
  );
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(
      find.widgetWithText(TextField, 'Email'), 'test@test.com');
  await tester.enterText(
      find.widgetWithText(TextField, 'Password'), 'wrongpassword');
  await tester.tap(find.widgetWithText(ElevatedButton, 'ENGAGE'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen — layout', () {
    testWidgets('shows FRIEND TRACKER title', (tester) async {
      await tester.pumpWidget(_buildLogin(_OkAuthNotifier()));
      await tester.pump();
      expect(find.textContaining('FRIEND'), findsOneWidget);
    });

    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(_buildLogin(_OkAuthNotifier()));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    });

    testWidgets('shows SIGN IN button by default', (tester) async {
      await tester.pumpWidget(_buildLogin(_OkAuthNotifier()));
      await tester.pump();
      expect(find.widgetWithText(ElevatedButton, 'ENGAGE'), findsOneWidget);
    });

    testWidgets('switches to register mode', (tester) async {
      await tester.pumpWidget(_buildLogin(_OkAuthNotifier()));
      await tester.pump();
      await tester.tap(find.textContaining('Ready to track'));
      await tester.pump();
      expect(
          find.widgetWithText(ElevatedButton, 'JOIN THE TEAM'), findsOneWidget);
    });
  });

  group('LoginScreen — failed sign in shows friendly error', () {
    testWidgets('user-not-found shows readable message', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(FirebaseAuthException(code: 'user-not-found')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.textContaining('Invalid email or password'), findsOneWidget);
    });

    testWidgets('invalid-credential shows readable message', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(FirebaseAuthException(code: 'invalid-credential')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.textContaining('Invalid email or password'), findsOneWidget);
    });

    testWidgets('wrong-password shows readable message', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(FirebaseAuthException(code: 'wrong-password')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.textContaining('Incorrect password'), findsOneWidget);
    });

    testWidgets('invalid-email shows readable message', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(FirebaseAuthException(code: 'invalid-email')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.textContaining('valid email address'), findsOneWidget);
    });

    testWidgets('too-many-requests shows throttle message', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(FirebaseAuthException(code: 'too-many-requests')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.textContaining('Too many attempts'), findsOneWidget);
    });

    testWidgets('network-request-failed shows offline message', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(
            FirebaseAuthException(code: 'network-request-failed')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.textContaining('No internet connection'), findsOneWidget);
    });

    testWidgets('unknown error shows generic fallback message', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(FirebaseAuthException(code: 'unknown-code')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.textContaining('not validating'), findsOneWidget);
    });

    testWidgets('error message includes error icon', (tester) async {
      await tester.pumpWidget(_buildLogin(
        _FailAuthNotifier(FirebaseAuthException(code: 'user-not-found')),
      ));
      await tester.pump();
      await _fillAndSubmit(tester);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
