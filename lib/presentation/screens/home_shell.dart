import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/dashboard_providers.dart';
import 'package:friend_tracker/presentation/providers/tracking_providers.dart';
import 'package:friend_tracker/presentation/screens/admin_dashboard_screen.dart';
import 'package:friend_tracker/presentation/screens/groups_screen.dart';
import 'package:friend_tracker/presentation/screens/inbox_screen.dart';
import 'package:friend_tracker/presentation/screens/settings_screen.dart';
import 'package:friend_tracker/presentation/screens/tracking_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  static const _screens = [
    TrackingScreen(),
    GroupsScreen(),
    InboxScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final pendingCount = ref.watch(pendingRequestCountProvider);
    final isAdmin = user?.uid == kAdminUid;

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
          const BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(
                '$pendingCount',
                style: GoogleFonts.roboto(fontSize: 10),
              ),
              child: const Icon(Icons.mail_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(
                '$pendingCount',
                style: GoogleFonts.roboto(fontSize: 10),
              ),
              child: const Icon(Icons.mail),
            ),
            label: 'Inbox',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),

      // Admin dashboard FAB — only visible to admin user
      floatingActionButton: isAdmin
          ? FloatingActionButton.small(
              heroTag: 'admin_dash',
              backgroundColor: GTrackerColors.card,
              foregroundColor: GTrackerColors.orange,
              tooltip: 'Admin Dashboard',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen(),
                ),
              ),
              child: const Icon(Icons.analytics_outlined),
            )
          : null,
    );
  }
}
