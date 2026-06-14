import 'package:flutter/material.dart';
import '../../../backend/services/auth_service.dart';
import '../../profile/models/profile_state.dart';
import '../models/committee_permission.dart';
import '../services/permissions_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';

// ─── Preset Definition ──────────────────────────────────────────────────────

class _PresetDef {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final CommitteePermission Function(String userId) factory;

  const _PresetDef({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.factory,
  });
}

final List<_PresetDef> _presets = [
  _PresetDef(
    label: 'Full Admin',
    shortLabel: 'Admin',
    icon: Icons.admin_panel_settings_rounded,
    color: Colors.deepPurple,
    factory: CommitteePermission.fullAdmin,
  ),
  _PresetDef(
    label: 'Treasurer',
    shortLabel: 'Treasury',
    icon: Icons.account_balance_wallet_rounded,
    color: Colors.teal,
    factory: CommitteePermission.treasurer,
  ),
  _PresetDef(
    label: 'PR / Notice Officer',
    shortLabel: 'PR Lead',
    icon: Icons.campaign_rounded,
    color: Colors.blue,
    factory: CommitteePermission.prOfficer,
  ),
  _PresetDef(
    label: 'Academic Officer',
    shortLabel: 'Academic',
    icon: Icons.menu_book_rounded,
    color: Colors.orange,
    factory: CommitteePermission.academicOfficer,
  ),
  _PresetDef(
    label: 'HR / Membership',
    shortLabel: 'HR Lead',
    icon: Icons.people_alt_rounded,
    color: Colors.green,
    factory: CommitteePermission.hrManager,
  ),
  _PresetDef(
    label: 'View Only (Reset)',
    shortLabel: 'Reset',
    icon: Icons.lock_reset_rounded,
    color: Colors.red,
    factory: CommitteePermission.viewOnly,
  ),
];

// ─── Main Screen ─────────────────────────────────────────────────────────────

class CommitteePermissionsScreen extends StatefulWidget {
  const CommitteePermissionsScreen({super.key});

  @override
  State<CommitteePermissionsScreen> createState() =>
      _CommitteePermissionsScreenState();
}

class _CommitteePermissionsScreenState
    extends State<CommitteePermissionsScreen> {
  List<ProfileData> _committeeMembers = [];
  List<CommitteePermission> _permissionsList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  bool get _isSuperUser {
    final p = currentProfile.value;
    return p.role == UserRole.superUser ||
        p.designation == 'President' ||
        p.designation == 'Vice President';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool isRefreshed = false}) async {
    if (!isRefreshed) {
      setState(() => _isLoading = true);
    }
    try {
      final members = await AuthService.fetchAllMembers();
      final perms = await PermissionsService.fetchAllPermissions();
      if (!mounted) return;
      setState(() {
        _committeeMembers = members
            .where((m) =>
                m.isApproved &&
                !m.isAlumni &&
                (m.role == UserRole.committeeMember ||
                    m.role == UserRole.superUser))
            .toList();
        _permissionsList = perms;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading permissions: $e')),
      );
    }
  }

  CommitteePermission _getPermissionsForUser(String userId) {
    return _permissionsList.firstWhere(
      (p) => p.userId == userId,
      orElse: () => CommitteePermission(userId: userId),
    );
  }

  int _allowedCount(CommitteePermission p) {
    int c = 0;
    if (p.canManageNotices) c++;
    if (p.canManageJobs) c++;
    if (p.canManageContests) c++;
    if (p.canManageResources) c++;
    if (p.canManageAccounting) c++;
    if (p.canApproveMembers) c++;
    return c;
  }

  // ─── Apply a preset for a member ────────────────────────────────────────
  Future<void> _applyPreset({
    required BuildContext sheetContext,
    required StateSetter setStateSheet,
    required ProfileData member,
    required _PresetDef preset,
    required CommitteePermission current,
  }) async {
    final updated = preset.factory(member.id);
    // Optimistic local update
    setStateSheet(() {
      final idx = _permissionsList.indexWhere((p) => p.userId == member.id);
      if (idx != -1) {
        _permissionsList[idx] = updated;
      } else {
        _permissionsList.add(updated);
      }
    });
    if (mounted) setState(() {});

    final messenger = ScaffoldMessenger.of(sheetContext);
    try {
      await PermissionsService.updatePermissions(updated);
      messenger.showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(preset.icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('${preset.label} preset applied to ${member.name}'),
          ]),
          backgroundColor: preset.color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      // Revert on failure
      setStateSheet(() {
        final idx = _permissionsList.indexWhere((p) => p.userId == member.id);
        if (idx != -1) {
          _permissionsList[idx] = current;
        }
      });
      if (mounted) setState(() {});
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to apply preset: $e')),
      );
    }
  }

  // ─── Toggle a single permission ─────────────────────────────────────────
  Future<void> _togglePermission({
    required BuildContext sheetContext,
    required StateSetter setStateSheet,
    required ProfileData member,
    required CommitteePermission updated,
  }) async {
    setStateSheet(() {
      final idx = _permissionsList.indexWhere((p) => p.userId == member.id);
      if (idx != -1) {
        _permissionsList[idx] = updated;
      } else {
        _permissionsList.add(updated);
      }
    });
    if (mounted) setState(() {});

    final messenger = ScaffoldMessenger.of(sheetContext);
    try {
      await PermissionsService.updatePermissions(updated);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update permission: $e')),
      );
    }
  }

  // ─── Bottom Sheet ────────────────────────────────────────────────────────
  void _showPermissionsBottomSheet(BuildContext context, ProfileData member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) {
          final colors = Theme.of(ctx).colorScheme;
          CommitteePermission activePerms = _getPermissionsForUser(member.id);
          final allowed = _allowedCount(activePerms);

          // ── Permission tile builder ──────────────────────────────────────
          Widget permTile({
            required String key,
            required String title,
            required String subtitle,
            required IconData icon,
            required bool value,
            required CommitteePermission Function(bool) buildUpdated,
          }) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: value
                    ? colors.primary.withValues(alpha: 0.06)
                    : colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value
                      ? colors.primary.withValues(alpha: 0.25)
                      : colors.outline.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: value
                            ? colors.primary.withValues(alpha: 0.15)
                            : colors.onSurface.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: value ? colors.primary : colors.onSurface.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: value ? colors.primary : colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isSuperUser)
                      Switch.adaptive(
                        value: value,
                        activeThumbColor: colors.primary,
                        activeTrackColor: colors.primary.withValues(alpha: 0.5),
                        onChanged: (newVal) async {
                          final updated = buildUpdated(newVal);
                          await _togglePermission(
                            sheetContext: ctx,
                            setStateSheet: setStateSheet,
                            member: member,
                            updated: updated,
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: value
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              value ? Icons.check_circle : Icons.cancel,
                              size: 13,
                              color: value ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              value ? 'Allowed' : 'Denied',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: value ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.97,
            expand: false,
            builder: (_, scrollController) => Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // ── Drag handle ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // ── Header ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              colors.primary.withValues(alpha: 0.12),
                          backgroundImage: member.imagePath != null &&
                                  member.imagePath!.startsWith('http')
                              ? NetworkImage(member.imagePath!)
                                  as ImageProvider
                              : null,
                          child: (member.imagePath == null ||
                                  !member.imagePath!.startsWith('http'))
                              ? Icon(Icons.person,
                                  color: colors.primary, size: 26)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                member.designation,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurface
                                        .withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isSuperUser
                                ? colors.primary.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isSuperUser ? '✏️ Manage' : '👁 View Only',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isSuperUser
                                  ? colors.primary
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Stats strip ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primary.withValues(alpha: 0.08),
                            colors.secondary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded,
                              color: colors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$allowed / 6 permissions active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                          const Spacer(),
                          _PermissionMiniDots(
                            perms: activePerms,
                            primaryColor: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Presets ribbon (superuser only) ──────────────────────
                  if (_isSuperUser) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
                      child: Text(
                        'QUICK PRESETS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final preset = _presets[i];
                          return ActionChip(
                            avatar: Icon(preset.icon,
                                color: preset.color, size: 16),
                            label: Text(
                              preset.shortLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: preset.color,
                              ),
                            ),
                            backgroundColor:
                                preset.color.withValues(alpha: 0.1),
                            side: BorderSide(
                                color: preset.color.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () async {
                              // Capture context before async gap
                              final capturedCtx = ctx;
                              final confirm = await showDialog<bool>(
                                context: capturedCtx,
                                builder: (dialogCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  title: Row(children: [
                                    Icon(preset.icon,
                                        color: preset.color, size: 22),
                                    const SizedBox(width: 10),
                                    Text(preset.label),
                                  ]),
                                  content: Text(
                                    'Apply the "${preset.label}" permission set to ${member.name}?\n\nThis will override all current permission settings.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogCtx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: preset.color,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(dialogCtx, true),
                                      child: const Text('Apply Preset'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && capturedCtx.mounted) {
                                await _applyPreset(
                                  sheetContext: capturedCtx,
                                  setStateSheet: setStateSheet,
                                  member: member,
                                  preset: preset,
                                  current: activePerms,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  // ── Section label ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'MODULE ACCESS PERMISSIONS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: colors.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const Spacer(),
                        if (_isSuperUser)
                          Text(
                            'Toggle to enable',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Scrollable tiles ─────────────────────────────────────
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        permTile(
                          key: 'notices',
                          title: 'Manage Notices',
                          subtitle:
                              'Create, edit, pin, and delete club or departmental notices',
                          icon: Icons.notifications_outlined,
                          value: activePerms.canManageNotices,
                          buildUpdated: (v) => activePerms.copyWith(
                              canManageNotices: v),
                        ),
                        permTile(
                          key: 'jobs',
                          title: 'Manage Jobs',
                          subtitle:
                              'Post career openings, recommend jobs, and verify recruiters',
                          icon: Icons.work_outline,
                          value: activePerms.canManageJobs,
                          buildUpdated: (v) =>
                              activePerms.copyWith(canManageJobs: v),
                        ),
                        permTile(
                          key: 'contests',
                          title: 'Manage Contests',
                          subtitle:
                              'Organize, sync, and publish club programming contests',
                          icon: Icons.emoji_events_outlined,
                          value: activePerms.canManageContests,
                          buildUpdated: (v) =>
                              activePerms.copyWith(canManageContests: v),
                        ),
                        permTile(
                          key: 'resources',
                          title: 'Manage Resources',
                          subtitle:
                              'Upload and edit academic notes, slides, and syllabus files',
                          icon: Icons.folder_copy_outlined,
                          value: activePerms.canManageResources,
                          buildUpdated: (v) =>
                              activePerms.copyWith(canManageResources: v),
                        ),
                        permTile(
                          key: 'accounting',
                          title: 'Manage Accounts',
                          subtitle:
                              'Log club treasury expenses and record student monthly fee payments',
                          icon: Icons.account_balance_wallet_outlined,
                          value: activePerms.canManageAccounting,
                          buildUpdated: (v) =>
                              activePerms.copyWith(canManageAccounting: v),
                        ),
                        permTile(
                          key: 'members',
                          title: 'Approve Members',
                          subtitle:
                              'Review, accept, and reject pending club applicant requests',
                          icon: Icons.assignment_ind_outlined,
                          value: activePerms.canApproveMembers,
                          buildUpdated: (v) =>
                              activePerms.copyWith(canApproveMembers: v),
                        ),
                        if (_isSuperUser) ...[
                          const SizedBox(height: 16),
                          const Divider(thickness: 0.5),
                          const SizedBox(height: 8),
                          Text(
                            'Changes are saved instantly and enforced across the entire app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final filtered = _committeeMembers.where((m) {
      if (_searchQuery.isEmpty) return true;
      final term = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(term) ||
          m.designation.toLowerCase().contains(term) ||
          m.studentFullId.toLowerCase().contains(term);
    }).toList();

    // Summary counts across whole committee
    final totalAllowed = _permissionsList.fold<int>(
        0, (sum, p) => sum + _allowedCount(p));
    final maxPossible = _committeeMembers.length * 6;

    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Committee Permissions'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ── Org-wide stats banner ──────────────────────────────
                  if (_committeeMembers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withValues(alpha: 0.09),
                              colors.secondary.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: colors.primary.withValues(alpha: 0.14)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.groups_2_rounded,
                                color: colors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_committeeMembers.length} committee members',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  if (maxPossible > 0)
                                    Text(
                                      '$totalAllowed / $maxPossible total permissions granted',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isSuperUser)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '✏️ Admin Mode',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // ── Search bar ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText:
                            'Search committee members by name or designation…',
                        prefixIcon:
                            const Icon(Icons.search_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color:
                                  colors.outline.withValues(alpha: 0.25)),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerLowest,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val),
                    ),
                  ),

                  // ── Member list ────────────────────────────────────────
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _loadData(isRefreshed: true),
                      child: filtered.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.5,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shield_outlined,
                                        size: 52,
                                        color: colors.onSurface
                                            .withValues(alpha: 0.2)),
                                    const SizedBox(height: 14),
                                    const Text('No committee members found.',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemBuilder: (context, index) {
                                final member = filtered[index];
                                final p =
                                    _getPermissionsForUser(member.id);
                                final allowed = _allowedCount(p);

                                // Colour the badge based on allowed count
                                Color badgeColor;
                                if (allowed == 6) {
                                  badgeColor = Colors.deepPurple;
                                } else if (allowed >= 3) {
                                  badgeColor = colors.primary;
                                } else if (allowed > 0) {
                                  badgeColor = Colors.orange;
                                } else {
                                  badgeColor = Colors.grey;
                                }

                                return Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                  color: colors.surfaceContainerLowest,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _showPermissionsBottomSheet(
                                        context, member),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: colors.primary
                                                .withValues(alpha: 0.1),
                                            backgroundImage: member.imagePath !=
                                                        null &&
                                                    member.imagePath!
                                                        .startsWith('http')
                                                ? NetworkImage(member.imagePath!)
                                                    as ImageProvider
                                                : null,
                                            child: (member.imagePath == null ||
                                                    !member.imagePath!
                                                        .startsWith('http'))
                                                ? Icon(Icons.person,
                                                    color: colors.primary,
                                                    size: 22)
                                                : null,
                                          ),
                                          const SizedBox(width: 14),

                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  member.name,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  member.designation,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colors.onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    // Permission count badge
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: badgeColor
                                                            .withValues(
                                                                alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                5),
                                                      ),
                                                      child: Text(
                                                        '$allowed / 6',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: badgeColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    // Mini dot indicators
                                                    _PermissionMiniDots(
                                                      perms: p,
                                                      primaryColor:
                                                          colors.primary,
                                                      dotSize: 6,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Chevron
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: colors.onSurface
                                                .withValues(alpha: 0.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}

// ─── Mini dot indicators widget ──────────────────────────────────────────────

class _PermissionMiniDots extends StatelessWidget {
  final CommitteePermission perms;
  final Color primaryColor;
  final double dotSize;

  const _PermissionMiniDots({
    required this.perms,
    required this.primaryColor,
    this.dotSize = 7,
  });

  @override
  Widget build(BuildContext context) {
    final flags = [
      perms.canManageNotices,
      perms.canManageJobs,
      perms.canManageContests,
      perms.canManageResources,
      perms.canManageAccounting,
      perms.canApproveMembers,
    ];
    return Row(
      children: flags.map((f) {
        return Container(
          width: dotSize,
          height: dotSize,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: f
                ? primaryColor.withValues(alpha: 0.8)
                : Colors.grey.withValues(alpha: 0.25),
          ),
        );
      }).toList(),
    );
  }
}
