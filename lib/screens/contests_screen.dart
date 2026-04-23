import 'package:flutter/material.dart';

class ContestsScreen extends StatelessWidget {
  const ContestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Extra Curriculum'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Contests'),
              Tab(text: 'Events & Courses'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContestsTab(context),
            _buildCoursesTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContestsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildContestCard(
          context: context,
          iconColor: Colors.blue,
          title: 'Codeforces Round #912 (Div. 2)',
          platform: 'Codeforces',
          level: '1600-2100',
          date: 'Dec 28, 2026 • 8:35 PM',
        ),
        _buildContestCard(
          context: context,
          iconColor: Colors.orange,
          title: 'Weekly Contest 378',
          platform: 'LeetCode',
          level: 'All Levels',
          date: 'Dec 29, 2026 • 8:00 AM',
        ),
        _buildContestCard(
          context: context,
          iconColor: Colors.teal,
          title: 'ICPC Asia Regional Contest',
          platform: 'ICPC',
          level: 'Advanced',
          date: 'Jan 15, 2027',
        ),
      ],
    );
  }

  Widget _buildCoursesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildCourseCard(
          context: context,
          icon: Icons.school,
          iconColor: Colors.indigo,
          title: 'Machine Learning Specialization',
          provider: 'Coursera',
          tag: 'Certificate',
        ),
        _buildCourseCard(
          context: context,
          icon: Icons.computer,
          iconColor: Colors.purple,
          title: 'Web Development Bootcamp',
          provider: 'Udemy',
          tag: 'Course',
        ),
      ],
    );
  }

  Widget _buildContestCard({
    required BuildContext context,
    required Color iconColor,
    required String title,
    required String platform,
    required String level,
    required String date,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emoji_events, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(platform, style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(level, style: TextStyle(color: colors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colors.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text(date, style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Join Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String provider,
    required String tag,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Text(provider),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.surfaceContainerHighest,
            foregroundColor: colors.primary,
            elevation: 0,
          ),
          child: const Text('Details'),
        ),
      ),
    );
  }
}