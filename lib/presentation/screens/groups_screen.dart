import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friend_tracker/config/theme.dart';
import 'package:friend_tracker/data/models/group.dart';
import 'package:friend_tracker/presentation/providers/auth_providers.dart';
import 'package:friend_tracker/presentation/providers/location_providers.dart';
import 'package:friend_tracker/presentation/providers/tracking_providers.dart';
import 'package:intl/intl.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final groups = ref.watch(groupsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TRACKING GROUPS',
          style: GoogleFonts.oswald(fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: user == null
            ? null
            : () => _showCreateDialog(context, ref, user.uid),
        backgroundColor: GTrackerColors.orange,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(
          'CREATE GROUP',
          style: GoogleFonts.oswald(fontWeight: FontWeight.w700),
        ),
      ),
      body: groups.isEmpty
          ? _EmptyState(onCreate: user == null
              ? null
              : () => _showCreateDialog(context, ref, user.uid))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: groups.length,
              itemBuilder: (context, index) => _GroupCard(
                group: groups[index],
                myUid: user?.uid ?? '',
              ),
            ),
    );
  }

  void _showCreateDialog(
      BuildContext context, WidgetRef ref, String myUid) {
    showDialog(
      context: context,
      builder: (_) => _CreateGroupDialog(
        myUid: myUid,
        onConfirm: (title, memberUids, endDate) async {
          await ref.read(firestoreServiceProvider).createGroup(
                creatorUid: myUid,
                title: title,
                memberUids: memberUids,
                endDate: endDate,
              );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onCreate;
  const _EmptyState({this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_outlined,
              color: GTrackerColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No tracking groups yet',
            style: GoogleFonts.oswald(
              color: GTrackerColors.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group and track up to 12 people at once.',
            style: GoogleFonts.roboto(
              color: GTrackerColors.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'CREATE TRACKING GROUP',
              style: GoogleFonts.oswald(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final Group group;
  final String myUid;

  const _GroupCard({required this.group, required this.myUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedUids = ref.watch(trackedUidsProvider);
    final allActive =
        group.memberUids.every((uid) => trackedUids.contains(uid));
    final isCreator = group.creatorUid == myUid;
    final dateStr = DateFormat('dd MMM yyyy').format(group.endDate);

    return Card(
      color: GTrackerColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: group.isExpiringSoon
              ? GTrackerColors.orange
              : GTrackerColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: GTrackerColors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    style: GoogleFonts.oswald(
                      color: GTrackerColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Play/stop toggle
                IconButton(
                  icon: Icon(
                    allActive ? Icons.stop_circle : Icons.play_circle,
                    color:
                        allActive ? GTrackerColors.error : GTrackerColors.orange,
                    size: 28,
                  ),
                  tooltip: allActive ? 'Stop tracking' : 'Start tracking',
                  onPressed: () {
                    if (allActive) {
                      ref
                          .read(groupTrackingNotifier.notifier)
                          .stopGroup(group);
                    } else {
                      ref
                          .read(groupTrackingNotifier.notifier)
                          .startGroup(group);
                    }
                  },
                ),
                if (isCreator)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: GTrackerColors.textSecondary),
                    color: GTrackerColors.surface,
                    onSelected: (action) =>
                        _handleAction(context, ref, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit',
                            style: GoogleFonts.roboto(
                                color: GTrackerColors.textPrimary)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Disband',
                            style: GoogleFonts.roboto(
                                color: GTrackerColors.error)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 28),
                Text(
                  '${group.memberUids.length} / ${group.maxMembers} members',
                  style: GoogleFonts.roboto(
                    color: GTrackerColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_today,
                  size: 11,
                  color: group.isExpiringSoon
                      ? GTrackerColors.orange
                      : GTrackerColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ends $dateStr',
                  style: GoogleFonts.roboto(
                    color: group.isExpiringSoon
                        ? GTrackerColors.orange
                        : GTrackerColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (group.isExpiringSoon) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GTrackerColors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: GTrackerColors.orange),
                ),
                child: Text(
                  'Expires within 24 hours!',
                  style: GoogleFonts.roboto(
                    color: GTrackerColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: GTrackerColors.surface,
          title: Text(
            'Disband Group?',
            style: GoogleFonts.oswald(
              color: GTrackerColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will permanently remove "${group.title}" for all members.',
            style: GoogleFonts.roboto(color: GTrackerColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL',
                  style: GoogleFonts.oswald(
                      color: GTrackerColors.textSecondary,
                      fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: GTrackerColors.error),
              onPressed: () async {
                Navigator.pop(context);
                await ref
                    .read(firestoreServiceProvider)
                    .deleteGroup(group.id);
              },
              child: Text('DISBAND',
                  style: GoogleFonts.oswald(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else if (action == 'edit') {
      showDialog(
        context: context,
        builder: (_) => _EditGroupDialog(group: group),
      );
    }
  }
}

class _CreateGroupDialog extends ConsumerStatefulWidget {
  final String myUid;
  final Future<void> Function(
      String title, List<String> memberUids, DateTime endDate) onConfirm;

  const _CreateGroupDialog({
    required this.myUid,
    required this.onConfirm,
  });

  @override
  ConsumerState<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<_CreateGroupDialog> {
  final _titleCtrl = TextEditingController();
  final _selectedUids = <String>{};
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a group title');
      return;
    }
    if (_endDate.isBefore(DateTime.now())) {
      setState(() => _error = 'End date must be in the future');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    await widget.onConfirm(
      _titleCtrl.text.trim(),
      _selectedUids.toList(),
      _endDate,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: GTrackerColors.orange,
            onPrimary: Colors.black,
            surface: GTrackerColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final trackedUids = ref.watch(trackedUidsProvider);
    final trackedList = trackedUids.toList();
    final memberCount = _selectedUids.length + 1; // +1 for creator

    return AlertDialog(
      backgroundColor: GTrackerColors.surface,
      title: Text(
        'Create Tracking Group',
        style: GoogleFonts.oswald(
          color: GTrackerColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: GoogleFonts.roboto(
                          color: GTrackerColors.error, fontSize: 12)),
                ),
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                style: GoogleFonts.roboto(
                  color: GTrackerColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: 'Group title',
                  labelStyle:
                      const TextStyle(color: GTrackerColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFF2E2E2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                        color: GTrackerColors.orange, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // End date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: GTrackerColors.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Ends ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: GoogleFonts.roboto(
                          color: GTrackerColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit,
                          color: GTrackerColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ),

              // Member count
              const SizedBox(height: 12),
              Text(
                'MEMBERS  $memberCount / 12',
                style: GoogleFonts.oswald(
                  color: GTrackerColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),

              if (trackedList.isEmpty)
                Text(
                  'Track users first to add them to a group.',
                  style: GoogleFonts.roboto(
                    color: GTrackerColors.textMuted,
                    fontSize: 12,
                  ),
                )
              else
                ...trackedList.map((uid) {
                  final data = ref.watch(trackedUserProvider(uid)).valueOrNull;
                  final name = data?['displayName'] as String? ?? uid;
                  final alreadyFull =
                      memberCount >= 12 && !_selectedUids.contains(uid);
                  return CheckboxListTile(
                    value: _selectedUids.contains(uid),
                    onChanged: alreadyFull
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedUids.add(uid);
                              } else {
                                _selectedUids.remove(uid);
                              }
                            });
                          },
                    title: Text(
                      name,
                      style: GoogleFonts.roboto(
                        color: alreadyFull
                            ? GTrackerColors.textMuted
                            : GTrackerColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    checkColor: Colors.black,
                    activeColor: GTrackerColors.orange,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL',
              style: GoogleFonts.oswald(
                  color: GTrackerColors.textSecondary,
                  fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _confirm,
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text('CREATE',
                  style: GoogleFonts.oswald(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _EditGroupDialog extends ConsumerStatefulWidget {
  final Group group;
  const _EditGroupDialog({required this.group});

  @override
  ConsumerState<_EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends ConsumerState<_EditGroupDialog> {
  late final TextEditingController _titleCtrl;
  late DateTime _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.group.title);
    _endDate = widget.group.endDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: GTrackerColors.orange,
            onPrimary: Colors.black,
            surface: GTrackerColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(firestoreServiceProvider).updateGroup(
          widget.group.id,
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          endDate: _endDate,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GTrackerColors.surface,
      title: Text('Edit Group',
          style: GoogleFonts.oswald(
              color: GTrackerColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.roboto(
                color: GTrackerColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Group title',
              labelStyle:
                  const TextStyle(color: GTrackerColors.textSecondary),
              filled: true,
              fillColor: const Color(0xFF2E2E2E),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                      color: GTrackerColors.orange, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: GTrackerColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Ends ${DateFormat('dd MMM yyyy').format(_endDate)}',
                    style: GoogleFonts.roboto(
                        color: GTrackerColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style: GoogleFonts.oswald(
                    color: GTrackerColors.textSecondary,
                    fontWeight: FontWeight.w700))),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text('SAVE',
                  style: GoogleFonts.oswald(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
