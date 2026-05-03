import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../profile/models/profile_state.dart';
import '../../../backend/services/auth_service.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  List<ProfileData> _committeeMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCommittee();
  }

  Future<void> _fetchCommittee() async {
    try {
      final all = await AuthService.fetchAllMembers();
      // Filter for committee or superuser roles
      final filtered = all.where((m) => 
        (m.role == UserRole.committeeMember || m.role == UserRole.superUser) && 
        m.isApproved && 
        m.designation != 'Student'
      ).toList();
      
      // Sort by some priority if possible, but for now just use the list
      if (mounted) {
        setState(() {
          _committeeMembers = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programming Club'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCommittee,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildAboutCard(context),
            const SizedBox(height: 16),
            _buildMissionVisionCard(context),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Club Activities'),
            _buildActivitiesCard(context),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Committee Members 2026'),
            _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              : _buildCommitteeCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24, // Optional: adjust the size if needed
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  backgroundImage: const AssetImage('assets/branding/cpc.jpg'),
                ),
                const SizedBox(width: 12),
                const Text('ShEC CPC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The Shyamoli Engineering College Computer Programming Club (ShEC CPC) is a vibrant community of passionate students dedicated to fostering excellence in computer science and programming. Founded in 2015, our club has grown to become one of the most active student organizations on campus.\n\nWe organize regular workshops, hackathons, coding competitions, and tech talks to help students enhance their programming skills, stay updated with industry trends, and build a strong professional network.',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.8), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionVisionCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 8),
            Text(
              'To create a collaborative learning environment where students can develop their technical skills, work on innovative projects, and prepare for successful careers in technology.',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.8), height: 1.4),
            ),

            const Divider(height: 32),
            const Text('Vision', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 8),
            Text(
              "To be the leading student programming community that produces skilled software engineers and innovators who contribute to Bangladesh's growing tech industry.",
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.8), height: 1.4),
            ),

            const Divider(height: 32),
            const Text('Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            Text(
            "Stay updated with our latest events, ongoing workshops, and community discussions by connecting with us on our official social media channels.",
            style: TextStyle(color: colors.onSurface.withOpacity(0.8), height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchURL('https://www.facebook.com/SHEC.CPC'),
              icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)), // Official Facebook Blue
              label: const Text(
                  'Follow Our Page',
                  style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.bold)
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF1877F2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],),
      ),
    );
  }

  Widget _buildActivitiesCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildActivityItem(context, Icons.laptop_chromebook, Colors.blue, 'Weekly Coding Sessions', 'Regular problem-solving focusing on competitive programming and algorithms.'),
          _buildDivider(colors),
          _buildActivityItem(context, Icons.build, Colors.teal, 'Technical Workshops', 'Monthly workshops on trending technologies like ML, Web Dev, and Cloud Computing.'),
          _buildDivider(colors),
          _buildActivityItem(context, Icons.emoji_events, Colors.orange, 'Hackathons', 'Annual 24-hour hackathons where students build innovative projects and compete for prizes.'),
          _buildDivider(colors),
          _buildActivityItem(context, Icons.lightbulb, Colors.amber, 'Project Showcases', 'Semester-end exhibitions where members present their innovative software projects.'),
          _buildDivider(colors),
          _buildActivityItem(context, Icons.record_voice_over, Colors.indigo, 'Industry Talks', 'Guest lectures from industry professionals sharing real-world experiences and insights.'),
          _buildDivider(colors),
          _buildActivityItem(context, Icons.group, Colors.purple, 'Study Groups', 'Collaborative learning groups for exam preparation and concept clarification.'),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, IconData icon, Color iconColor, String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 13, height: 1.3)),
      ),
    );
  }

  Widget _buildCommitteeCard(BuildContext context) {
    if (_committeeMembers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: Text('No committee members found.')),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _committeeMembers.length; i++) ...[
            _buildMemberItem(context, _committeeMembers[i]),
            if (i < _committeeMembers.length - 1) _buildDivider(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, ProfileData member) {
    final colors = Theme.of(context).colorScheme;
    // Simple color logic based on designation
    Color roleColor = colors.primary;
    if (member.designation.contains('President')) roleColor = Colors.blue;
    if (member.designation.contains('Secretary')) roleColor = Colors.indigo;
    if (member.designation.contains('Treasurer')) roleColor = Colors.orange;
    if (member.designation.contains('Joint')) roleColor = Colors.redAccent;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: colors.primary.withOpacity(0.1),
        backgroundImage: member.imagePath != null && member.imagePath!.isNotEmpty 
            ? NetworkImage(member.imagePath!) 
            : null,
        child: member.imagePath == null || member.imagePath!.isEmpty
            ? Text(member.firstName[0].toUpperCase())
            : null,
      ),
      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                member.designation,
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('• ${member.batch} th Batch', style: TextStyle(color: colors.onSurface.withOpacity(0.5), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colors) {
    return Divider(height: 1, indent: 70, endIndent: 16, color: colors.outline.withValues(alpha: 0.1));
  }
}