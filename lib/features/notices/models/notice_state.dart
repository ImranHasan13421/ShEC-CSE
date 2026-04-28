import 'package:flutter/material.dart';

class NoticeItem {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> tags;
  final Color tagColor;
  final String date;
  bool isPinned;

  NoticeItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.tagColor,
    required this.date,
    this.isPinned = false,
  });
}

// Global Notifiers for Notices
final ValueNotifier<List<NoticeItem>> clubNoticesState = ValueNotifier([
  NoticeItem(
    id: 'c1',
    icon: Icons.lightbulb,
    iconColor: Colors.amber,
    title: 'Workshop on Machine Learning Basics',
    subtitle: 'Join us for an introductory workshop on ML fundamentals and practical applications. Learn from industry experts.',
    tags: ['Workshop', 'Machine Learning'],
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
    tags: ['Event', 'Hackathon'],
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
    tags: ['Lecture', 'AI'],
    tagColor: Colors.teal,
    date: 'May 18, 2026',
    isPinned: false,
  ),
]);

final ValueNotifier<List<NoticeItem>> deptNoticesState = ValueNotifier([
  NoticeItem(
    id: 'd1',
    icon: Icons.assignment,
    iconColor: Colors.amber,
    title: 'Mid-term Examination Schedule',
    subtitle: 'The mid-term examination schedule for all CSE courses has been published.',
    tags: ['Academic', 'Exam'],
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
    tags: ['Maintenance', 'Lab'],
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
    tags: ['Academic', 'Research'],
    tagColor: Colors.purple,
    date: 'May 8, 2026',
    isPinned: false,
  ),
]);
