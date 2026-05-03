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

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await AuthService.fetchAllMembers();
      if (mounted) setState(() => _members = members);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(ProfileData member, UserRole newRole) async {
    try {
      await AuthService.updateUserRole(member.id, newRole);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated successfully')));
      _fetchMembers(); // Refresh list
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating role: $e')));
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member deleted successfully')));
        _fetchMembers();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting member: $e')));
      }
    }
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
          : ListView.builder(
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
                  child: ListTile(
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
                        Text('Class ID: ${member.studentId} | Session: ${member.session}'),
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
                    trailing: isSelf ? null : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteMember(member);
                        } else if (value == 'make_member') {
                          _changeRole(member, UserRole.student);
                        } else if (value == 'make_committee') {
                          _changeRole(member, UserRole.committeeMember);
                        } else if (value == 'make_superuser') {
                          _changeRole(member, UserRole.superUser);
                        }
                      },
                      itemBuilder: (context) => [
                        if (member.role != UserRole.student) const PopupMenuItem(value: 'make_member', child: Text('Demote to Member')),
                        if (member.role != UserRole.committeeMember) const PopupMenuItem(value: 'make_committee', child: Text('Promote to Committee')),
                        if (member.role != UserRole.superUser) const PopupMenuItem(value: 'make_superuser', child: Text('Promote to Superuser')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Member', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
