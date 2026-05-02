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
  String _searchQuery = '';
  bool _isLoading = true;

  bool get isAdmin => currentProfile.value.role != UserRole.student;

  @override
  void initState() {
    super.initState();
    // 3 Tabs: Members, Committees, Pending (if admin)
    int tabCount = currentProfile.value.role != UserRole.student ? 3 : 2;
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
    final currentP = currentProfile.value;
    final isSuperuser = currentP.designation == 'President' || currentP.designation == 'Vice President';
    final isCommittee = currentP.role == UserRole.committeeMember;
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
                Text(member.designation, style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  
                  if (isSuperuser) ...[
                    ElevatedButton(
                      onPressed: () => _showDesignationPicker(member),
                      child: const Text('Change Designation / Promote'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: colors.secondary, foregroundColor: Colors.white),
                      icon: const Icon(Icons.school),
                      label: const Text('Move to Alumni'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Move to Alumni'),
                            content: Text('Are you sure you want to move ${member.name} to the Alumni list? This will remove them from current members.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Move')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          if (!context.mounted) return;
                          Navigator.pop(context); // Close details
                          try {
                            await AuthService.moveToAlumni(member);
                            _fetchMembers();
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Alumni')));
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  ],
                  
                  if (isSuperuser && member.designation != 'Student')
                    TextButton(
                      onPressed: () => _changeRole(member, UserRole.student, designation: 'Student'),
                      child: const Text('Remove from Committee', style: TextStyle(color: Colors.orange)),
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

  void _showDesignationPicker(ProfileData member) {
    final List<String> standardDesignations = [
      'President', 'Vice President', 'General Secretary', 'Joint Secretary', 
      'Treasurer', 'Press Secretary', 'Executive Member', 'Member'
    ];
    String? selected = standardDesignations.contains(member.designation) ? member.designation : null;
    final customController = TextEditingController(text: selected == null ? member.designation : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Designation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selected,
              items: standardDesignations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) => setState(() => selected = val),
              decoration: const InputDecoration(labelText: 'Designation List', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final finalDesignation = selected ?? 'Student';
              Navigator.pop(context);
              UserRole role = UserRole.student;
              if (finalDesignation != 'Student') {
                role = (finalDesignation == 'President' || finalDesignation == 'Vice President') 
                    ? UserRole.superUser 
                    : UserRole.committeeMember;
              }
              _changeRole(member, role, designation: finalDesignation);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(ProfileData member, UserRole newRole, {String? designation}) async {
    try {
      await AuthService.updateUserRole(member.id, newRole, designation: designation);
      if (mounted) {
        Navigator.pop(context); // Close details sheet if open
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
      _fetchMembers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating: $e')));
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
    final filteredAll = _allMembers.where((m) => 
      m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      m.studentId.contains(_searchQuery)
    ).toList();

    final members = filteredAll.where((m) => m.role == UserRole.student && m.isApproved && m.designation == 'Student').toList();
    final committees = filteredAll.where((m) => (m.role == UserRole.committeeMember || m.role == UserRole.superUser) && m.isApproved).toList();
    final pending = filteredAll.where((m) => !m.isApproved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  const Tab(text: 'Members'),
                  const Tab(text: 'Committee'),
                  if (isAdmin)
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Pending '),
                          if (pending.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text('${pending.length}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                            )
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(members),
                _buildList(committees),
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
            subtitle: Text('${member.designation} • ID: ${member.studentId}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
