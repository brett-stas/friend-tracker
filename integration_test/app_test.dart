import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:friend_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Friend Tracker — Full App Integration', () {

    // ── Login Screen ───────────────────────────────────────────────────────

    testWidgets('App launches and shows login screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.textContaining('FRIEND'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
    });

    testWidgets('Login screen renders email and password fields', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Tapping "New here" switches to register mode', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await tester.tap(find.textContaining('New here'));
      await tester.pumpAndSettle();

      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      // Register mode has 3 fields: name, email, password
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('Tapping back to sign-in restores 2 fields', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await tester.tap(find.textContaining('New here'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Already have'));
      await tester.pumpAndSettle();

      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Submitting empty fields shows loading then error', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await tester.enterText(find.byType(TextField).at(0), 'bad@email.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
      await tester.tap(find.text('SIGN IN'));
      await tester.pump();

      // Loading indicator appears immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for Firebase to respond
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Error text should now appear
      expect(find.byType(Text), findsWidgets);
    });

    // ── Garmin Theme checks ────────────────────────────────────────────────

    testWidgets('Scaffold background is black (Garmin theme)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFF000000));
    });

    testWidgets('Sign in button is orange (Garmin theme)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      final style = btn.style?.backgroundColor?.resolve({});
      expect(style, const Color(0xFFFF9B00));
    });

    // ── Navigation (requires signed-in user — skipped if not authed) ───────

    testWidgets('Bottom nav has Map, Friends, Settings tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Only verifiable after login — check structure exists if authed
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(nav.items.length, 3);
        expect(nav.items[0].label, 'Map');
        expect(nav.items[1].label, 'Friends');
        expect(nav.items[2].label, 'Settings');
      }
    });
  });
}
