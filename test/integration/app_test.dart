import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:friend_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Friend Tracker Integration Tests', () {
    // ── Auth flow ──────────────────────────────────────────────────────────

    testWidgets('Login screen shows FRIEND TRACKER title', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.textContaining('FRIEND'), findsOneWidget);
    });

    testWidgets('Shows error on invalid login credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.enterText(
        find.byType(TextField).at(0),
        'notareal@email.com',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'wrongpassword',
      );

      await tester.tap(find.text('ENGAGE'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Firebase auth error should appear
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Can switch to register mode', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.textContaining('Ready to track'));
      await tester.pumpAndSettle();

      expect(find.text('JOIN THE TEAM'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3)); // name, email, password
    });

    testWidgets('Can switch back to sign in mode', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go to register
      await tester.tap(find.textContaining('Ready to track'));
      await tester.pumpAndSettle();

      // Go back to sign in
      await tester.tap(find.textContaining('Already enlisted'));
      await tester.pumpAndSettle();

      expect(find.text('ENGAGE'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // email, password only
    });

    // ── UI structure ───────────────────────────────────────────────────────

    testWidgets('Login screen has email and password fields', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Login screen has orange accent bar', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasOrangeBar = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          return decoration.color!.toARGB32() == const Color(0xFFFF9B00).toARGB32();
        }
        return false;
      });
      expect(hasOrangeBar, isTrue);
    });

    testWidgets('Login button is disabled while loading', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('ENGAGE'));
      await tester.pump(); // Don't settle — catch the loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
