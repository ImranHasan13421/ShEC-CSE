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

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late List<JobItem> recommendedJobs;
  late List<JobItem> recentJobs;

  @override
  void initState() {
    super.initState();

    // Initialize mock data
    recommendedJobs = [
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
    ];

    recentJobs = [
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
    ];
  }

  void _toggleStar(JobItem job) {
    setState(() {
      job.isStarred = !job.isStarred;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(context, 'Recommended for You'),
          ...recommendedJobs.map((job) => _buildJobCard(job)),
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Recently Posted'),
          ...recentJobs.map((job) => _buildJobCard(job)),
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

  Widget _buildJobCard(JobItem job) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      key: ValueKey(job.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailScreen(job: job),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                      color: job.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(job.icon, color: job.iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.role,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.company,
                          style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // The Star Button
                  IconButton(
                    icon: Icon(
                      job.isStarred ? Icons.star : Icons.star_border,
                      color: job.isStarred ? Colors.amber : colors.onSurface.withOpacity(0.3),
                    ),
                    onPressed: () => _toggleStar(job),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: colors.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    job.location,
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
                      color: job.typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: job.typeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      job.jobType,
                      style: TextStyle(color: job.typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 12, color: colors.error.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${job.deadline}',
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


// --- Job Details Screen ---
// Added directly in the same file to keep your structure simple!

class JobDetailScreen extends StatelessWidget {
  final JobItem job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Header Card
                Card(
                  elevation: 0,
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.outline.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.role, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.business, size: 16, color: colors.onSurface.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Text(job.company, style: TextStyle(fontSize: 16, color: colors.onSurface.withOpacity(0.8))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: colors.onSurface.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Text(job.location, style: TextStyle(fontSize: 14, color: colors.onSurface.withOpacity(0.8))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.monetization_on, size: 16, color: colors.onSurface.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Text(job.salary, style: TextStyle(fontSize: 14, color: colors.onSurface.withOpacity(0.8))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: job.typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(job.jobType, style: TextStyle(color: job.typeColor, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Deadline: ${job.deadline}', style: TextStyle(color: colors.error, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Responsibilities Card
                _buildInfoSection(
                  context,
                  title: 'Responsibilities',
                  icon: Icons.check_circle,
                  iconColor: Colors.teal,
                  items: [
                    'Design and implement software solutions for complex problems',
                    'Collaborate with team members on product development',
                    'Write clean, maintainable, and efficient code',
                    'Participate in code reviews and technical discussions',
                    'Contribute to documentation and testing efforts',
                  ],
                ),
                const SizedBox(height: 16),

                // Requirements Card
                _buildInfoSection(
                  context,
                  title: 'Requirements',
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  items: [
                    'Currently pursuing BS/MS in Computer Science or related field',
                    'Strong programming skills in Java, C++, or Python',
                    'Understanding of data structures and algorithms',
                    'Experience with software development and coding',
                    'Excellent problem-solving and analytical skills',
                  ],
                ),
                const SizedBox(height: 16),

                // Benefits Card
                _buildInfoSection(
                  context,
                  title: 'Benefits',
                  icon: Icons.card_giftcard,
                  iconColor: Colors.blue,
                  items: [
                    'Competitive compensation package',
                    'Housing stipend for relocation',
                    'Free meals and snacks',
                    'Mentorship from experienced engineers',
                    'Networking opportunities with industry leaders',
                  ],
                ),
              ],
            ),
          ),

          // Bottom Apply Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Action for Apply Now
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Application feature coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, {required String title, required IconData icon, required Color iconColor, required List<String> items}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item, style: TextStyle(color: colors.onSurface.withOpacity(0.8), height: 1.4)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}