import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/presentation/providers/dashboard_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalUsers = ref.watch(totalUsersProvider);
    final activeUsers = ref.watch(activeUsersProvider);
    final activeGroups = ref.watch(activeGroupsProvider);
    final pendingRequests = ref.watch(pendingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ADMIN DASHBOARD',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: GTrackerColors.orange,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: GoogleFonts.oswald(
                    color: const Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'APP USAGE',
              style: GoogleFonts.oswald(
                color: GTrackerColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  label: 'TOTAL USERS',
                  value: totalUsers,
                  icon: Icons.people,
                  color: const Color(0xFF2196F3),
                ),
                _StatCard(
                  label: 'ACTIVE NOW',
                  sublabel: 'last 5 min',
                  value: activeUsers,
                  icon: Icons.person_pin_circle,
                  color: const Color(0xFF4CAF50),
                ),
                _StatCard(
                  label: 'ACTIVE GROUPS',
                  value: activeGroups,
                  icon: Icons.group,
                  color: GTrackerColors.orange,
                ),
                _StatCard(
                  label: 'PENDING REQUESTS',
                  value: pendingRequests,
                  icon: Icons.mail_outline,
                  color: const Color(0xFF9C27B0),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'SYSTEM',
              style: GoogleFonts.oswald(
                color: GTrackerColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Environment', value: 'Production'),
            _InfoRow(
                label: 'Last refreshed',
                value: TimeOfDay.now().format(context)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String? sublabel;
  final AsyncValue<int> value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GTrackerColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              value.when(
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, st) => const Icon(Icons.error_outline,
                    color: GTrackerColors.error, size: 16),
                data: (count) => Text(
                  '$count',
                  style: GoogleFonts.oswald(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.oswald(
                  color: GTrackerColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: GoogleFonts.roboto(
                    color: GTrackerColors.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              color: GTrackerColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              color: GTrackerColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
