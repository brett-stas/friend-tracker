import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/friends_providers.dart';
import 'package:friend_tracker/presentation/screens/friends_screen.dart';
import 'package:friend_tracker/presentation/screens/map_screen.dart';
import 'package:friend_tracker/presentation/screens/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  static const _screens = [
    MapScreen(),
    FriendsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        ref.watch(friendRequestsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(
                '$pendingCount',
                style: GoogleFonts.roboto(fontSize: 10),
              ),
              child: const Icon(Icons.people_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(
                '$pendingCount',
                style: GoogleFonts.roboto(fontSize: 10),
              ),
              child: const Icon(Icons.people),
            ),
            label: 'Friends',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
