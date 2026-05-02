import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/job_state.dart';
import '../../../backend/services/job_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  @override
  void initState() {
    super.initState();
    JobService.fetchJobs();
  }
  void _toggleStar(JobItem job, ValueNotifier<List<JobItem>> stateNotifier) async {
    try {
      job.isStarred = !job.isStarred;
      stateNotifier.value = List.from(stateNotifier.value);
      
      String category = stateNotifier == recommendedJobsState ? 'recommended' : 'recent';
      await JobService.updateJobInDB(job, category);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating star: $e')));
    }
  }

  void _deleteJob(JobItem job, ValueNotifier<List<JobItem>> stateNotifier) async {
    try {
      String category = stateNotifier == recommendedJobsState ? 'recommended' : 'recent';
      await JobService.deleteJobFromDB(job.id, category);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting job: $e')));
    }
  }

  void _showJobForm(BuildContext context, {JobItem? existingJob, ValueNotifier<List<JobItem>>? defaultStateNotifier}) {
    final roleController = TextEditingController(text: existingJob?.role ?? '');
    final companyController = TextEditingController(text: existingJob?.company ?? '');
    final locationController = TextEditingController(text: existingJob?.location ?? '');
    final salaryController = TextEditingController(text: existingJob?.salary ?? '');
    final deadlineController = TextEditingController(text: existingJob?.deadline ?? '');
    final jobTypeController = TextEditingController(text: existingJob?.jobType ?? '');
    bool isVisible = existingJob?.isVisible ?? true;

    ValueNotifier<List<JobItem>> selectedNotifier = defaultStateNotifier ?? recommendedJobsState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
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
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Visible to Members'),
                      value: isVisible,
                      onChanged: (val) => setModalState(() => isVisible = val),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (roleController.text.isNotEmpty && companyController.text.isNotEmpty) {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(modalContext);
                            try {
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
                                  isVisible: isVisible,
                                  createdByName: currentProfile.value.name,
                                );
                                String category = selectedNotifier == recommendedJobsState ? 'recommended' : 'recent';
                                await JobService.addJobToDB(newJob, category);
                                if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Job created successfully')));
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
                                  isVisible: isVisible,
                                  createdByName: existingJob.createdByName,
                                );
                                final index = targetNotifier.value.indexOf(existingJob);
                                if (index != -1) {
                                  final updatedList = List<JobItem>.from(targetNotifier.value);
                                  updatedList[index] = updatedJob;
                                  targetNotifier.value = updatedList;
                                }
                                String category = targetNotifier == recommendedJobsState ? 'recommended' : 'recent';
                                await JobService.updateJobInDB(updatedJob, category);
                                if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Job updated successfully')));
                              }
                            } catch (e) {
                              if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
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
              final profile = currentProfile.value;
              final isAdmin = profile.role != UserRole.student;
              final visibleJobs = jobs.where((j) {
                if (isAdmin) return true;
                return j.isApproved && j.isVisible;
              }).toList();

              if (visibleJobs.isEmpty) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No recommended jobs.')));
              }
              return Column(
                children: visibleJobs.map((job) => _buildJobCard(job, recommendedJobsState)).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(context, 'Recently Posted'),
          ValueListenableBuilder<List<JobItem>>(
            valueListenable: recentJobsState,
            builder: (context, jobs, _) {
              final profile = currentProfile.value;
              final isAdmin = profile.role != UserRole.student;
              final visibleJobs = jobs.where((j) {
                if (isAdmin) return true;
                return j.isApproved && j.isVisible;
              }).toList();

              if (visibleJobs.isEmpty) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No recent jobs.')));
              }
              return Column(
                children: visibleJobs.map((job) => _buildJobCard(job, recentJobsState)).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
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
                      color: job.iconColor.withValues(alpha: 0.1),
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      job.role,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  if (!job.isApproved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  if (!job.isVisible)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Text('HIDDEN', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                            // The Star Button
                            IconButton(
                              icon: Icon(
                                job.isStarred ? Icons.star : Icons.star_border,
                                color: job.isStarred ? Colors.amber : colors.onSurface.withValues(alpha: 0.3),
                              ),
                              onPressed: () => _toggleStar(job, stateNotifier),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            // Edit/Delete for Committee Members
                            ValueListenableBuilder<ProfileData>(
                              valueListenable: currentProfile,
                              builder: (context, profile, _) {
                                if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
                                  return PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showJobForm(context, existingJob: job, defaultStateNotifier: stateNotifier);
                                      } else if (value == 'delete') {
                                        _deleteJob(job, stateNotifier);
                                      } else if (value == 'approve') {
                                        JobService.approveJob(job.id);
                                      } else if (value == 'visibility') {
                                        JobService.toggleJobVisibility(job.id, !job.isVisible);
                                      }
                                    },
                                      itemBuilder: (context) => [
                                        if (!job.isApproved && (profile.designation == 'President' || profile.designation == 'Vice President'))
                                          const PopupMenuItem(value: 'approve', child: Text('Approve', style: TextStyle(color: Colors.green))),
                                        PopupMenuItem(value: 'visibility', child: Text(job.isVisible ? 'Hide' : 'Show')),
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
                          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    job.location,
                    style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: job.typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: job.typeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      job.jobType,
                      style: TextStyle(color: job.typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 12, color: colors.error.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${job.deadline}',
                    style: TextStyle(color: colors.error.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
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
                    side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
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
                            Icon(Icons.business, size: 16, color: colors.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(width: 8),
                            Text(job.company, style: TextStyle(fontSize: 16, color: colors.onSurface.withValues(alpha: 0.8))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: colors.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(width: 8),
                            Text(job.location, style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.8))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.monetization_on, size: 16, color: colors.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(width: 8),
                            Text(job.salary, style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.8))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: job.typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(job.jobType, style: TextStyle(color: job.typeColor, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.1),
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

                 // Description
                 if (job.description.isNotEmpty)
                   _buildTextSection(context, title: 'About the Role', content: job.description),
                 if (job.description.isNotEmpty) const SizedBox(height: 16),

                 // Responsibilities Card
                 if (job.responsibilities.isNotEmpty)
                   _buildInfoSection(
                     context,
                     title: 'Responsibilities',
                     icon: Icons.check_circle,
                     iconColor: Colors.teal,
                     items: job.responsibilities,
                   ),
                 if (job.responsibilities.isNotEmpty) const SizedBox(height: 16),

                 // Requirements Card
                 if (job.requirements.isNotEmpty)
                   _buildInfoSection(
                     context,
                     title: 'Requirements',
                     icon: Icons.star,
                     iconColor: Colors.amber,
                     items: job.requirements,
                   ),
                 if (job.requirements.isEmpty && job.responsibilities.isEmpty && job.description.isEmpty)
                   Padding(
                     padding: const EdgeInsets.all(24),
                     child: Center(
                       child: Text('No additional details provided.', style: TextStyle(color: Colors.grey.shade500)),
                     ),
                   ),
               ],
             ),
           ),

           // Bottom Apply Button
           Container(
             padding: const EdgeInsets.all(16.0),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surface,
               boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
               ],
             ),
             child: SafeArea(
               child: SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () async {
                     if (job.applyUrl.isNotEmpty) {
                       final uri = Uri.parse(job.applyUrl);
                       if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open apply link.')));
                         }
                       }
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No apply link provided.')));
                     }
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.primary,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
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

  Widget _buildTextSection(BuildContext context, {required String title, required String content}) {
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(content, style: TextStyle(color: colors.onSurface.withOpacity(0.8), height: 1.6)),
          ],
        ),
      ),
    );
  }
}