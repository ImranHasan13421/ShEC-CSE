import 'package:flutter/material.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(context, 'Recommended for You'),
          _buildJobCard(
            context: context,
            company: 'Google',
            role: 'Software Engineer Intern',
            location: 'Mountain View, CA',
            deadline: 'May 30, 2026',
            jobType: 'Internship',
            typeColor: Colors.teal,
            iconColor: Colors.blue,
            icon: Icons.g_mobiledata,
          ),
          _buildJobCard(
            context: context,
            company: 'Microsoft',
            role: 'Machine Learning Engineer',
            location: 'Redmond, WA',
            deadline: 'June 10, 2026',
            jobType: 'Full-time',
            typeColor: Colors.indigo,
            iconColor: Colors.blueAccent,
            icon: Icons.window,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Recently Posted'),
          _buildJobCard(
            context: context,
            company: 'Meta',
            role: 'Frontend Developer',
            location: 'Menlo Park, CA',
            deadline: 'June 5, 2026',
            jobType: 'Full-time',
            typeColor: Colors.indigo,
            iconColor: Colors.blue,
            icon: Icons.facebook,
          ),
          _buildJobCard(
            context: context,
            company: 'Amazon',
            role: 'Data Science Intern',
            location: 'Seattle, WA',
            deadline: 'May 28, 2026',
            jobType: 'Internship',
            typeColor: Colors.teal,
            iconColor: Colors.orange,
            icon: Icons.shopping_cart,
          ),
        ],
      ),
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

  Widget _buildJobCard({
    required BuildContext context,
    required String company,
    required String role,
    required String location,
    required String deadline,
    required String jobType,
    required Color typeColor,
    required Color iconColor,
    required IconData icon,
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
      child: InkWell(
        onTap: () {
          // Future: Navigate to Job Details Screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company,
                          style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: colors.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      jobType,
                      style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 12, color: colors.error.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: $deadline',
                    style: TextStyle(color: colors.error.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}