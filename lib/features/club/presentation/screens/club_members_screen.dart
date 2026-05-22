import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../backend/services/auth_service.dart';
import '../../../profile/models/profile_state.dart';
import '../widgets/member_card.dart';
import '../widgets/member_details_sheet.dart';
import '../widgets/role_management_dialog.dart';

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
    int tabCount = currentProfile.value.role != UserRole.student ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    _fetchMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _confirmAndMakeCall(ProfileData member) async {
    final colors = Theme.of(context).colorScheme;
    final phone = member.phone;
    if (phone.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_forwarded, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Phone Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Would you like to call ${member.name}?\n\nPhone: $phone',
          style: TextStyle(color: colors.onSurface, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HapticFeedback.lightImpact();
      final Uri launchUri = Uri(scheme: 'tel', path: phone);
      try {
        bool launched = await launchUrl(launchUri, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw 'App launch returned false';
        }
      } catch (e) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: colors.surface,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, color: colors.error),
                ),
                const SizedBox(width: 12),
                const Text('Could Not Open Dialer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              'No phone dialer app could be opened automatically on this device. This is common on simulators or devices without mobile network hardware.\n\nPhone Number: $phone',
              style: TextStyle(color: colors.onSurface, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Dismiss', style: TextStyle(color: colors.onSurfaceVariant)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Phone number copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: const Text('Copy Number'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _confirmAndSendEmail(ProfileData member) async {
    final colors = Theme.of(context).colorScheme;
    final email = member.email;
    if (email.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mail_outline, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Would you like to send an email to ${member.name}?\n\nEmail: $email',
          style: TextStyle(color: colors.onSurface, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Email'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HapticFeedback.lightImpact();
      final Uri launchUri = Uri(scheme: 'mailto', path: email);
      try {
        bool launched = await launchUrl(launchUri, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw 'App launch returned false';
        }
      } catch (e) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: colors.surface,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, color: colors.error),
                ),
                const SizedBox(width: 12),
                const Text('Could Not Open Mail App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              'No default email application could be opened on this device. This is common if no email accounts are set up or if no mail client is installed.\n\nEmail: $email',
              style: TextStyle(color: colors.onSurface, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Dismiss', style: TextStyle(color: colors.onSurfaceVariant)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: email));
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Email address copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: const Text('Copy Email'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _changeRole(ProfileData member, UserRole newRole, {String? designation}) async {
    try {
      await AuthService.updateUserRole(member.id, newRole, designation: designation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully')));
        _fetchMembers();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _deleteMember(ProfileData member) async {
    final confirm = await _showConfirmDialog('Delete Member', 'Are you sure you want to delete ${member.name}?');
    if (confirm == true) {
      try {
        await AuthService.deleteUser(member.id);
        _fetchMembers();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
  }

  void _showDesignationPicker(ProfileData member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DesignationPickerSheet(
        member: member,
        onSelect: (selectedDesignation) {
          Navigator.pop(context);
          _changeRole(
            member, 
            selectedDesignation == 'Member' ? UserRole.student : UserRole.committeeMember, 
            designation: selectedDesignation
          );
        },
      ),
    );
  }

  void _showEditMemberSheet(ProfileData member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditMemberSheet(
        member: member,
        onSave: (updatedMember) async {
          try {
            await AuthService.updateAnyProfile(updatedMember);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Info updated successfully')));
              _fetchMembers();
            }
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  void _showMemberDetails(ProfileData member) {
    final currentP = currentProfile.value;
    final isSuperuser = currentP.designation == 'President' || currentP.designation == 'Vice President';
    final isCommittee = currentP.role == UserRole.committeeMember;
    final canManage = isSuperuser || isCommittee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MemberDetailsSheet(
          member: member,
          canManage: canManage,
          isSuperuser: isSuperuser,
          currentProfileData: currentP,
          onApprove: () async {
            Navigator.pop(context);
            await AuthService.approveUser(member.id);
            _fetchMembers();
          },
          onUpdateInfo: () {
            Navigator.pop(context);
            _showEditMemberSheet(member);
          },
          onChangeRank: () {
            Navigator.pop(context);
            _showDesignationPicker(member);
          },
          onMoveToAlumni: () async {
            final confirm = await _showConfirmDialog(
              'Move to Alumni',
              'Move ${member.name} to the Alumni list?'
            );
            if (confirm == true) {
              if (!context.mounted) return;
              Navigator.pop(context);
              try {
                await AuthService.moveToAlumni(member);
                _fetchMembers();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          onDemote: () {
            Navigator.pop(context);
            _changeRole(member, UserRole.student, designation: 'Member');
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteMember(member);
          },
          onCall: () {
            Navigator.pop(context);
            _confirmAndMakeCall(member);
          },
          onEmail: () {
            Navigator.pop(context);
            _confirmAndSendEmail(member);
          },
        );
      },
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
        return MemberCard(
          member: member,
          isPendingList: isPendingList,
          onTap: () => _showMemberDetails(member),
          onCallTap: () => _confirmAndMakeCall(member),
          onEmailTap: () => _confirmAndSendEmail(member),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabLabelColor = isDark ? colors.primary : Colors.white;
    final tabUnselectedColor = isDark ? colors.onSurface.withOpacity(0.6) : Colors.white.withOpacity(0.7);
    final tabIndicatorColor = isDark ? colors.primary : Colors.white;

    final filteredAll = _allMembers.where((m) => 
      m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      m.studentFullId.contains(_searchQuery)
    ).toList();

    final members = filteredAll.where((m) => m.role == UserRole.student && m.isApproved).toList();
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
                labelColor: tabLabelColor,
                unselectedLabelColor: tabUnselectedColor,
                indicatorColor: tabIndicatorColor,
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
}
