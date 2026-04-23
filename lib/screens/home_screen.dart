//lib/screens/home_screen.dart/
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Welcome Back!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Stay updated with departmental & club activities.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 24),

        const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAccessIcon(context, Icons.message, 'Messenger', Colors.blue),
            _buildQuickAccessIcon(context, Icons.notifications, 'Notices', Colors.amber),
            _buildQuickAccessIcon(context, Icons.work, 'Jobs', Colors.green),
            _buildQuickAccessIcon(context, Icons.emoji_events, 'Contests', Colors.redAccent),
          ],
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('Latest Notices', () {}),
        _buildListCard(
          context,
          icon: Icons.lightbulb,
          iconColor: Colors.blue,
          title: 'Workshop on Machine Learning Basics',
          subtitle: 'Join us for an introductory workshop on ML fundamentals.',
          tag: 'Workshop',
          date: 'May 15, 2026',
        ),
        _buildListCard(
          context,
          icon: Icons.code,
          iconColor: Colors.blueAccent,
          title: 'Hackathon Registration Open',
          subtitle: 'Annual coding hackathon registration is now open.',
          tag: 'Event',
          date: 'May 20, 2026',
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Upcoming Contests', () {}),
        _buildListCard(
          context,
          icon: Icons.emoji_events,
          iconColor: Colors.orange,
          title: 'Codeforces Round #892',
          subtitle: 'Div. 2 competitive programming contest.',
          tag: 'Contest',
          date: 'Tomorrow',
        ),
      ],
    );
  }

  Widget _buildQuickAccessIcon(BuildContext context, IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildListCard(BuildContext context, {
    required IconData icon, required Color iconColor,
    required String title, required String subtitle,
    required String tag, required String date,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(tag, style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text(date, style: TextStyle(color: colors.onSurface.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}