import 'package:flutter/material.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notice Board'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Club Notices'),
              Tab(text: 'Department Notices'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClubNotices(context, colors),
            _buildDepartmentNotices(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildClubNotices(BuildContext context, ColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle(context, '📌 Pinned Notices'),
        _buildNoticeCard(
          context: context,
          isPinned: true,
          icon: Icons.lightbulb,
          iconColor: Colors.amber,
          title: 'Workshop on Machine Learning Basics',
          subtitle: 'Join us for an introductory workshop on ML fundamentals and practical applications. Learn from industry experts.',
          tag: 'Workshop',
          tagColor: Colors.blue,
          date: 'May 15, 2026',
        ),
        _buildNoticeCard(
          context: context,
          isPinned: true,
          icon: Icons.code,
          iconColor: Colors.amber,
          title: 'Hackathon Registration Open',
          subtitle: 'Annual coding hackathon registration is now open. Form your teams and register today!',
          tag: 'Event',
          tagColor: Colors.indigo,
          date: 'May 20, 2026',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle(context, 'All Notices'),
        _buildNoticeCard(
          context: context,
          isPinned: false,
          icon: Icons.record_voice_over,
          iconColor: Colors.teal,
          title: 'Guest Lecture: AI in Healthcare',
          subtitle: 'Dr. Sarah Johnson will discuss the applications of AI in modern healthcare systems.',
          tag: 'Lecture',
          tagColor: Colors.teal,
          date: 'May 18, 2026',
        ),
      ],
    );
  }

  Widget _buildDepartmentNotices(BuildContext context, ColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle(context, '📌 Pinned Notices'),
        _buildNoticeCard(
          context: context,
          isPinned: true,
          icon: Icons.assignment,
          iconColor: Colors.amber,
          title: 'Mid-term Examination Schedule',
          subtitle: 'The mid-term examination schedule for all CSE courses has been published.',
          tag: 'Academic',
          tagColor: Colors.purple,
          date: 'May 12, 2026',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle(context, 'All Notices'),
        _buildNoticeCard(
          context: context,
          isPinned: false,
          icon: Icons.build,
          iconColor: Colors.cyan,
          title: 'Lab Equipment Maintenance',
          subtitle: 'Computer labs will be closed for maintenance on May 16-17.',
          tag: 'Maintenance',
          tagColor: Colors.cyan,
          date: 'May 10, 2026',
        ),
        _buildNoticeCard(
          context: context,
          isPinned: false,
          icon: Icons.article,
          iconColor: Colors.deepPurple,
          title: 'Research Paper Submission Deadline',
          subtitle: 'Final year students must submit their research papers by May 25.',
          tag: 'Academic',
          tagColor: Colors.purple,
          date: 'May 8, 2026',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildNoticeCard({
    required BuildContext context,
    required bool isPinned,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required String date,
  }) {
    final colors = Theme.of(context).colorScheme;

    // Pinned cards get a subtle yellowish background tint in light mode
    final backgroundColor = isPinned
        ? (Theme.of(context).brightness == Brightness.light ? Colors.amber.shade50 : colors.surfaceContainerHighest)
        : colors.surface;

    final borderColor = isPinned ? Colors.amber.withOpacity(0.5) : colors.outline.withOpacity(0.1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isPinned ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPinned ? Colors.white : iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                            ),
                          ),
                          if (isPinned)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.push_pin, color: Colors.redAccent, size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPinned ? Colors.white : tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tagColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 12, color: colors.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(color: colors.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}