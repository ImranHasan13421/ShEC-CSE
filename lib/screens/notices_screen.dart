import 'package:flutter/material.dart';

// --- Data Model for Notices ---
class NoticeItem {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final String date;
  bool isPinned;

  NoticeItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.date,
    this.isPinned = false,
  });
}

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  // --- Dynamic State Data ---
  late List<NoticeItem> clubNotices;
  late List<NoticeItem> deptNotices;

  @override
  void initState() {
    super.initState();
    // Initialize Club Notices
    clubNotices = [
      NoticeItem(
        id: 'c1',
        icon: Icons.lightbulb,
        iconColor: Colors.amber,
        title: 'Workshop on Machine Learning Basics',
        subtitle: 'Join us for an introductory workshop on ML fundamentals and practical applications. Learn from industry experts.',
        tag: 'Workshop',
        tagColor: Colors.blue,
        date: 'May 15, 2026',
        isPinned: true,
      ),
      NoticeItem(
        id: 'c2',
        icon: Icons.code,
        iconColor: Colors.amber,
        title: 'Hackathon Registration Open',
        subtitle: 'Annual coding hackathon registration is now open. Form your teams and register today!',
        tag: 'Event',
        tagColor: Colors.indigo,
        date: 'May 20, 2026',
        isPinned: true,
      ),
      NoticeItem(
        id: 'c3',
        icon: Icons.record_voice_over,
        iconColor: Colors.teal,
        title: 'Guest Lecture: AI in Healthcare',
        subtitle: 'Dr. Sarah Johnson will discuss the applications of AI in modern healthcare systems.',
        tag: 'Lecture',
        tagColor: Colors.teal,
        date: 'May 18, 2026',
        isPinned: false,
      ),
    ];

    // Initialize Department Notices
    deptNotices = [
      NoticeItem(
        id: 'd1',
        icon: Icons.assignment,
        iconColor: Colors.amber,
        title: 'Mid-term Examination Schedule',
        subtitle: 'The mid-term examination schedule for all CSE courses has been published.',
        tag: 'Academic',
        tagColor: Colors.purple,
        date: 'May 12, 2026',
        isPinned: true,
      ),
      NoticeItem(
        id: 'd2',
        icon: Icons.build,
        iconColor: Colors.cyan,
        title: 'Lab Equipment Maintenance',
        subtitle: 'Computer labs will be closed for maintenance on May 16-17.',
        tag: 'Maintenance',
        tagColor: Colors.cyan,
        date: 'May 10, 2026',
        isPinned: false,
      ),
      NoticeItem(
        id: 'd3',
        icon: Icons.article,
        iconColor: Colors.deepPurple,
        title: 'Research Paper Submission Deadline',
        subtitle: 'Final year students must submit their research papers by May 25.',
        tag: 'Academic',
        tagColor: Colors.purple,
        date: 'May 8, 2026',
        isPinned: false,
      ),
    ];
  }

  // --- Toggle Logic ---
  void _togglePin(NoticeItem notice) {
    setState(() {
      notice.isPinned = !notice.isPinned;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column( // Replaced Scaffold with Column
        children: [
          // 1. The TabBar
          Container(
            color: colors.primary, // Matches your original AppBar background
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Club Notices'),
                Tab(text: 'Department Notices'),
              ],
            ),
          ),

          // 2. The Tab Views
          Expanded( // Expanded is required so TabBarView knows how much space to take
            child: TabBarView(
              children: [
                _buildNoticesList(clubNotices),
                _buildNoticesList(deptNotices),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesList(List<NoticeItem> notices) {
    // Dynamically filter lists based on their current pinned status
    final pinnedNotices = notices.where((n) => n.isPinned).toList();
    final unpinnedNotices = notices.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (pinnedNotices.isNotEmpty) ...[
          _buildSectionTitle('📌 Pinned Notices'),
          ...pinnedNotices.map((notice) => _buildNoticeCard(notice)),
          const SizedBox(height: 16),
        ],
        if (unpinnedNotices.isNotEmpty) ...[
          _buildSectionTitle('All Notices'),
          ...unpinnedNotices.map((notice) => _buildNoticeCard(notice)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
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

  Widget _buildNoticeCard(NoticeItem notice) {
    final colors = Theme.of(context).colorScheme;

    // Pinned cards get a subtle yellowish background tint in light mode
    final backgroundColor = notice.isPinned
        ? (Theme.of(context).brightness == Brightness.light ? Colors.amber.shade50 : colors.surfaceContainerHighest)
        : colors.surface;

    final borderColor = notice.isPinned ? Colors.amber.withOpacity(0.5) : colors.outline.withOpacity(0.1);

    return Card(
      key: ValueKey(notice.id), // Helps Flutter animate list changes smoothly
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: notice.isPinned ? 1.5 : 1.0),
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
                    color: notice.isPinned ? Colors.white : notice.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notice.icon, color: notice.iconColor, size: 24),
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
                              notice.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                            ),
                          ),
                          // The Interactive Pin Button
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: Icon(
                                notice.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: notice.isPinned ? Colors.redAccent : colors.onSurface.withOpacity(0.3),
                                size: 22,
                              ),
                              onPressed: () => _togglePin(notice),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(), // Removes default padding around IconButton
                              splashRadius: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notice.subtitle,
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
                    color: notice.isPinned ? Colors.white : notice.tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: notice.tagColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    notice.tag,
                    style: TextStyle(color: notice.tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 12, color: colors.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  notice.date,
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