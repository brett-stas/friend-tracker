import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/firebase_options.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/screens/home_shell.dart';
import 'package:friend_tracker/presentation/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: FriendTrackerApp()));
}

class FriendTrackerApp extends ConsumerWidget {
  const FriendTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Friend Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildGarminTheme(),
      home: authState.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        data: (user) => user != null ? const HomeShell() : const LoginScreen(),
      ),
    );
  }
}
