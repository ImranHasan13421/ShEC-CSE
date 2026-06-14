import 'package:flutter/material.dart';
import '../../../backend/services/auth_service.dart';
import '../../profile/models/profile_state.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<ProfileData> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers({bool isRefreshed = false}) async {
    if (!isRefreshed) {
      setState(() => _isLoading = true);
    }
    try {
      final members = await AuthService.fetchAllMembers();
      if (mounted) setState(() => _members = members);
    } catch (e) {
      if (mounted) _showToast('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(ProfileData member, UserRole newRole) async {
    try {
      await AuthService.updateUserRole(member.id, newRole);
      if (mounted) {
        _showToast('Role updated successfully', isError: false);
        if (newRole == UserRole.committeeMember) {
          _showCommitteePrivilegesDialog(member);
        }
      }
      _fetchMembers(); // Refresh list
    } catch (e) {
      if (mounted) _showToast('Error updating role: $e', isError: true);
    }
  }

  Future<void> _deleteMember(ProfileData member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService.deleteUser(member.id);
        if (mounted) _showToast('Member deleted successfully', isError: false);
        _fetchMembers();
      } catch (e) {
        if (mounted) _showToast('Error deleting member: $e', isError: true);
      }
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMembers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchMembers(isRefreshed: true),
              child: _members.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: const Text('No members found.'),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        
                        // Don't allow superusers to delete themselves from this list easily
                        final isSelf = member.id == currentProfile.value.id;

                        String roleText;
                        Color roleColor;
                        switch (member.role) {
                          case UserRole.superUser:
                            roleText = 'Superuser';
                            roleColor = Colors.purple;
                            break;
                          case UserRole.committeeMember:
                            roleText = 'Committee';
                            roleColor = Colors.orange;
                            break;
                          case UserRole.student:
                          default:
                            roleText = 'Member';
                            roleColor = Colors.green;
                            break;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: member.imagePath != null && member.imagePath!.isNotEmpty 
                                    ? NetworkImage(member.imagePath!) 
                                    : null,
                                  child: member.imagePath == null || member.imagePath!.isEmpty
                                    ? Text(member.name[0].toUpperCase())
                                    : null,
                                ),
                                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Student ID: ${member.studentFullId} | Session: ${member.session}'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: roleColor.withOpacity(0.5)),
                                      ),
                                      child: Text(roleText, style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isSelf) ...[
                                const Divider(height: 8, thickness: 0.5),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 12, bottom: 8, top: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Member Management',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (member.role != UserRole.student)
                                        IconButton(
                                          icon: const Icon(Icons.school, color: Colors.green, size: 20),
                                          tooltip: 'Demote to Member',
                                          onPressed: () => _changeRole(member, UserRole.student),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      if (member.role != UserRole.committeeMember)
                                        IconButton(
                                          icon: const Icon(Icons.group, color: Colors.orange, size: 20),
                                          tooltip: 'Promote to Committee',
                                          onPressed: () => _changeRole(member, UserRole.committeeMember),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      if (member.role != UserRole.superUser)
                                        IconButton(
                                          icon: const Icon(Icons.shield, color: Colors.purple, size: 20),
                                          tooltip: 'Promote to Superuser',
                                          onPressed: () => _changeRole(member, UserRole.superUser),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        tooltip: 'Delete Member',
                                        onPressed: () => _deleteMember(member),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  void _showCommitteePrivilegesDialog(ProfileData member) {
    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.primary),
              const SizedBox(width: 12),
              const Text('Committee Privileges', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${member.name} has been promoted to a Committee Member! They now have access to administrative controls across the app. Here are their newly unlocked functional tooltips:',
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 16),
                _buildPrivilegeItem(colors, Icons.auto_awesome, 'Notice Board', 'Approve, Pinned/Unpinned, Hide/Show, Edit, and Delete notices.'),
                _buildPrivilegeItem(colors, Icons.school, 'Faculty Directory', 'Add, Edit, Hide/Show, and Delete teacher contact cards.'),
                _buildPrivilegeItem(colors, Icons.emoji_events, 'Contest Portal', 'Add, Edit, Hide/Show, and Delete programming contests.'),
                _buildPrivilegeItem(colors, Icons.people, 'Alumni Directory', 'Add, Edit, Hide/Show, and Delete alumni listings.'),
                _buildPrivilegeItem(colors, Icons.work_outline, 'Career Board', 'Add, Edit, Hide/Show, and Delete job listings.'),
                _buildPrivilegeItem(colors, Icons.folder_open, 'Academic Resources', 'Upload, modify, and delete resources or course folders.'),
                _buildPrivilegeItem(colors, Icons.account_balance, 'Club Accounts', 'Access accounting logs, log income/expenses, and view dues.'),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivilegeItem(ColorScheme colors, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 11, color: colors.onSurface.withOpacity(0.6), height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
