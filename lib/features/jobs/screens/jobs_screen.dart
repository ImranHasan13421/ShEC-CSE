import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/job_state.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  @override
  void initState() {
    super.initState();
    fetchJobs();
  }
  void _toggleStar(JobItem job, ValueNotifier<List<JobItem>> stateNotifier) async {
    job.isStarred = !job.isStarred;
    stateNotifier.value = List.from(stateNotifier.value);
    
    String category = stateNotifier == recommendedJobsState ? 'recommended' : 'recent';
    await updateJobInDB(job, category);
  }

  void _deleteJob(JobItem job, ValueNotifier<List<JobItem>> stateNotifier) async {
    String category = stateNotifier == recommendedJobsState ? 'recommended' : 'recent';
    await deleteJobFromDB(job.id, category);
  }

  void _showJobForm(BuildContext context, {JobItem? existingJob, ValueNotifier<List<JobItem>>? defaultStateNotifier}) {
    final roleController = TextEditingController(text: existingJob?.role ?? '');
    final companyController = TextEditingController(text: existingJob?.company ?? '');
    final locationController = TextEditingController(text: existingJob?.location ?? '');
    final salaryController = TextEditingController(text: existingJob?.salary ?? '');
    final deadlineController = TextEditingController(text: existingJob?.deadline ?? '');
    final jobTypeController = TextEditingController(text: existingJob?.jobType ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            ValueNotifier<List<JobItem>> selectedNotifier = defaultStateNotifier ?? recommendedJobsState;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existingJob == null ? 'Add Job' : 'Edit Job', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (existingJob == null) ...[
                      const Text('Job Category', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SegmentedButton<ValueNotifier<List<JobItem>>>(
                        segments: [
                          ButtonSegment(value: recommendedJobsState, label: const Text('Recommended')),
                          ButtonSegment(value: recentJobsState, label: const Text('Recent')),
                        ],
                        selected: {selectedNotifier},
                        onSelectionChanged: (Set<ValueNotifier<List<JobItem>>> newSelection) {
                          setModalState(() {
                            selectedNotifier = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: roleController,
                      decoration: const InputDecoration(labelText: 'Job Role', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: companyController,
                      decoration: const InputDecoration(labelText: 'Company', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: salaryController,
                      decoration: const InputDecoration(labelText: 'Salary/Stipend', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deadlineController,
                      decoration: const InputDecoration(labelText: 'Deadline', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: jobTypeController,
                      decoration: const InputDecoration(labelText: 'Job Type (e.g., Internship)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (roleController.text.isNotEmpty && companyController.text.isNotEmpty) {
                            if (existingJob == null) {
                              final newJob = JobItem(
                                id: '',
                                company: companyController.text,
                                role: roleController.text,
                                location: locationController.text,
                                salary: salaryController.text,
                                deadline: deadlineController.text,
                                jobType: jobTypeController.text,
                                typeColor: Colors.teal,
                                iconColor: Colors.blue,
                                icon: Icons.work,
                              );
                              String category = selectedNotifier == recommendedJobsState ? 'recommended' : 'recent';
                              addJobToDB(newJob, category);
                            } else {
                              final targetNotifier = defaultStateNotifier!;
                              final updatedJob = JobItem(
                                id: existingJob.id,
                                company: companyController.text,
                                role: roleController.text,
                                location: locationController.text,
                                salary: salaryController.text,
                                deadline: deadlineController.text,
                                jobType: jobTypeController.text,
                                typeColor: existingJob.typeColor,
                                iconColor: existingJob.iconColor,
                                icon: existingJob.icon,
                                isStarred: existingJob.isStarred,
                              );
                              final index = targetNotifier.value.indexOf(existingJob);
                              if (index != -1) {
                                final updatedList = List<JobItem>.from(targetNotifier.value);
                                updatedList[index] = updatedJob;
                                targetNotifier.value = updatedList;
                              }
                              String category = targetNotifier == recommendedJobsState ? 'recommended' : 'recent';
                              updateJobInDB(updatedJob, category);
                            }
                            Navigator.pop(context);
                          }
                        },
                        child: Text(existingJob == null ? 'Create' : 'Update'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(context, 'Recommended for You'),
          ValueListenableBuilder<List<JobItem>>(
            valueListenable: recommendedJobsState,
            builder: (context, jobs, _) {
              if (jobs.isEmpty) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No recommended jobs.')));
              }
              return Column(
                children: jobs.map((job) => _buildJobCard(job, recommendedJobsState)).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Recently Posted'),
          ValueListenableBuilder<List<JobItem>>(
            valueListenable: recentJobsState,
            builder: (context, jobs, _) {
              if (jobs.isEmpty) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No recent jobs.')));
              }
              return Column(
                children: jobs.map((job) => _buildJobCard(job, recentJobsState)).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role == UserRole.committeeMember) {
            return FloatingActionButton(
              onPressed: () => _showJobForm(context),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
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

  Widget _buildJobCard(JobItem job, ValueNotifier<List<JobItem>> stateNotifier) {
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                job.role,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            // The Star Button
                            IconButton(
                              icon: Icon(
                                job.isStarred ? Icons.star : Icons.star_border,
                                color: job.isStarred ? Colors.amber : colors.onSurface.withOpacity(0.3),
                              ),
                              onPressed: () => _toggleStar(job, stateNotifier),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            // Edit/Delete for Committee Members
                            ValueListenableBuilder<ProfileData>(
                              valueListenable: currentProfile,
                              builder: (context, profile, _) {
                                if (profile.role == UserRole.committeeMember) {
                                  return PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showJobForm(context, existingJob: job, defaultStateNotifier: stateNotifier);
                                      } else if (value == 'delete') {
                                        _deleteJob(job, stateNotifier);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.company,
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