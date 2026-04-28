import 'package:flutter/material.dart';

// --- Data Model for Jobs ---
class JobItem {
  final String id;
  final String company;
  final String role;
  final String location;
  final String salary;
  final String deadline;
  final String jobType;
  final Color typeColor;
  final Color iconColor;
  final IconData icon;
  bool isStarred;

  JobItem({
    required this.id,
    required this.company,
    required this.role,
    required this.location,
    required this.salary,
    required this.deadline,
    required this.jobType,
    required this.typeColor,
    required this.iconColor,
    required this.icon,
    this.isStarred = false,
  });
}

// Global Notifiers for Jobs
final ValueNotifier<List<JobItem>> recommendedJobsState = ValueNotifier([
  JobItem(
    id: 'j1',
    company: 'Google',
    role: 'Software Engineer Intern',
    location: 'Mountain View, CA',
    salary: '\$8,000 - \$10,000/month',
    deadline: 'May 30, 2026',
    jobType: 'Internship',
    typeColor: Colors.teal,
    iconColor: Colors.blue,
    icon: Icons.g_mobiledata,
  ),
  JobItem(
    id: 'j2',
    company: 'Microsoft',
    role: 'Machine Learning Engineer',
    location: 'Redmond, WA',
    salary: '\$110k - \$150k/year',
    deadline: 'June 10, 2026',
    jobType: 'Full-time',
    typeColor: Colors.indigo,
    iconColor: Colors.blueAccent,
    icon: Icons.window,
  ),
]);

final ValueNotifier<List<JobItem>> recentJobsState = ValueNotifier([
  JobItem(
    id: 'j3',
    company: 'Meta',
    role: 'Frontend Developer',
    location: 'Menlo Park, CA',
    salary: '\$120k - \$160k/year',
    deadline: 'June 5, 2026',
    jobType: 'Full-time',
    typeColor: Colors.indigo,
    iconColor: Colors.blue,
    icon: Icons.facebook,
  ),
  JobItem(
    id: 'j4',
    company: 'Amazon',
    role: 'Data Science Intern',
    location: 'Seattle, WA',
    salary: '\$7,500 - \$9,000/month',
    deadline: 'May 28, 2026',
    jobType: 'Internship',
    typeColor: Colors.teal,
    iconColor: Colors.orange,
    icon: Icons.shopping_cart,
  ),
]);
