import 'package:flutter/material.dart';
import '../../../backend/services/auth_service.dart';
import '../../profile/models/profile_state.dart';

class ClubMembersScreen extends StatefulWidget {
  const ClubMembersScreen({super.key});

  @override
  State<ClubMembersScreen> createState() => _ClubMembersScreenState();
}

class _ClubMembersScreenState extends State<ClubMembersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProfileData> _allMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Members, Committees, Superusers, Pending
    // Only show 4 tabs if user is committee/superuser. Otherwise 3 tabs.
    int tabCount = currentProfile.value.role != UserRole.student ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await AuthService.fetchAllMembers();
      if (mounted) setState(() => _allMembers = members);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMemberDetails(ProfileData member) {
    final colors = Theme.of(context).colorScheme;
    final isSuperuser = currentProfile.value.role == UserRole.superUser;
    final isCommittee = currentProfile.value.role == UserRole.committeeMember;
    final canManage = isSuperuser || isCommittee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: member.imagePath != null && member.imagePath!.isNotEmpty 
                      ? NetworkImage(member.imagePath!) 
                      : null,
                  child: member.imagePath == null || member.imagePath!.isEmpty
                      ? Text(member.name[0].toUpperCase(), style: const TextStyle(fontSize: 40))
                      : null,
                ),
                const SizedBox(height: 16),
                Text(member.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(member.role.name.toUpperCase(), style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                
                _buildInfoRow(Icons.badge, 'Class ID', member.studentId),
                _buildInfoRow(Icons.school, 'Session', member.session),
                _buildInfoRow(Icons.numbers, 'DU Reg', member.duRegNo),
                _buildInfoRow(Icons.phone, 'Phone', member.phone),
                
                if (canManage && member.id != currentProfile.value.id) ...[
                  const Divider(height: 32),
                  const Text('Manage Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  
                  if (!member.isApproved)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve Registration'),
                      onPressed: () async {
                        Navigator.pop(context);
                        await AuthService.approveUser(member.id);
                        _fetchMembers();
                      },
                    ),
                  
                  // Only superusers can change designations or delete
                  if (isSuperuser && member.isApproved)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (member.role != UserRole.student)
                          ActionChip(label: const Text('Make Member'), onPressed: () => _changeRole(member, UserRole.student)),
                        if (member.role != UserRole.committeeMember)
                          ActionChip(label: const Text('Make Committee'), onPressed: () => _changeRole(member, UserRole.committeeMember)),
                        if (member.role != UserRole.superUser)
                          ActionChip(label: const Text('Make Superuser'), onPressed: () => _changeRole(member, UserRole.superUser)),
                      ],
                    ),
                    
                  if (isSuperuser)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Account'),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMember(member);
                      },
                    ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _changeRole(ProfileData member, UserRole newRole) async {
    Navigator.pop(context); // close bottom sheet
    try {
      await AuthService.updateUserRole(member.id, newRole);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated successfully')));
      _fetchMembers();
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
    final isAdmin = currentProfile.value.role != UserRole.student;

    final members = _allMembers.where((m) => m.role == UserRole.student && m.isApproved).toList();
    final committees = _allMembers.where((m) => m.role == UserRole.committeeMember && m.isApproved).toList();
    final superusers = _allMembers.where((m) => m.role == UserRole.superUser && m.isApproved).toList();
    final pending = _allMembers.where((m) => !m.isApproved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Directory'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMembers),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Members'),
            const Tab(text: 'Committee'),
            const Tab(text: 'Superusers'),
            if (isAdmin)
              Tab(
                child: Row(
                  children: [
                    const Text('Pending '),
                    if (pending.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${pending.length}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      )
                  ],
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(members),
                _buildList(committees),
                _buildList(superusers),
                if (isAdmin) _buildList(pending, isPendingList: true),
              ],
            ),
    );
  }

  Widget _buildList(List<ProfileData> list, {bool isPendingList = false}) {
    if (list.isEmpty) {
      return const Center(child: Text('No users found in this category.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final member = list[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: isPendingList ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12)
          ),
          child: ListTile(
            onTap: () => _showMemberDetails(member),
            leading: CircleAvatar(
              backgroundImage: member.imagePath != null && member.imagePath!.isNotEmpty 
                ? NetworkImage(member.imagePath!) 
                : null,
              child: member.imagePath == null || member.imagePath!.isEmpty
                ? Text(member.name[0].toUpperCase())
                : null,
            ),
            title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${member.studentId} | Session: ${member.session}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
