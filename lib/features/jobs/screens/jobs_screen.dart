import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/job_state.dart';
import 'job_detail_screen.dart';
import '../../../backend/services/job_service.dart';
import 'package:intl/intl.dart';

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
    final descriptionController = TextEditingController(text: existingJob?.description ?? '');
    final applyUrlController = TextEditingController(text: existingJob?.applyUrl ?? '');
    final reqController = TextEditingController();
    final respController = TextEditingController();
    
    String? selectedJobType = existingJob?.jobType ?? 'Full Time';
    String? selectedCategory = existingJob?.category ?? (defaultStateNotifier == recommendedJobsState ? 'recommended' : 'recent');
    
    List<String> requirements = List.from(existingJob?.requirements ?? []);
    List<String> responsibilities = List.from(existingJob?.responsibilities ?? []);
    bool isVisible = existingJob?.isVisible ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            Future<void> _selectDate() async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setModalState(() {
                  deadlineController.text = DateFormat('dd/MM/yyyy').format(picked);
                });
              }
            }

            final colors = Theme.of(context).colorScheme;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: colors.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(existingJob == null ? 'Post a New Job' : 'Edit Job Posting', 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Fill in the details for the position', style: TextStyle(color: colors.onSurface.withOpacity(0.6))),
                          const SizedBox(height: 24),
                          
                          _buildTextField('Job Role', roleController, Icons.work_outline, 'e.g. Software Engineer'),
                          const SizedBox(height: 16),
                          _buildTextField('Company', companyController, Icons.business, 'e.g. Google'),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Location', locationController, Icons.location_on_outlined, 'e.g. Dhaka (Remote)')),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField('Salary/Stipend', salaryController, Icons.payments_outlined, 'e.g. 30k - 40k')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _selectDate,
                                  child: AbsorbPointer(
                                    child: _buildTextField('Deadline', deadlineController, Icons.calendar_today_outlined, 'Select Date'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedJobType,
                                  decoration: _inputDecoration('Job Type', Icons.access_time),
                                  items: ['Full Time', 'Part Time', 'Internship'].map((String type) {
                                    return DropdownMenuItem<String>(value: type, child: Text(type));
                                  }).toList(),
                                  onChanged: (value) => setModalState(() => selectedJobType = value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: _inputDecoration('Target Category', Icons.category_outlined),
                            items: [
                              const DropdownMenuItem(value: 'recent', child: Text('Regular (Recent)')),
                              const DropdownMenuItem(value: 'recommended', child: Text('Featured (Recommended)')),
                            ],
                            onChanged: (value) => setModalState(() => selectedCategory = value),
                          ),
                          const SizedBox(height: 16),

                          _buildTextField('Apply URL', applyUrlController, Icons.link, 'LinkedIn/Google Form link'),
                          const SizedBox(height: 16),
                          
                          _buildTextField('Description', descriptionController, Icons.description_outlined, 'Summary of the job...', maxLines: 4),
                          const SizedBox(height: 24),
                          
                          _buildListInput('Requirements', reqController, requirements, (val) => setModalState(() => requirements.add(val)), (idx) => setModalState(() => requirements.removeAt(idx)), colors),
                          const SizedBox(height: 24),
                          
                          _buildListInput('Responsibilities', respController, responsibilities, (val) => setModalState(() => responsibilities.add(val)), (idx) => setModalState(() => responsibilities.removeAt(idx)), colors),
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: colors.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                            child: SwitchListTile(
                              title: const Text('Visible to Public Members', style: TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: const Text('Hide this job if it\'s no longer active'),
                              value: isVisible,
                              onChanged: (val) => setModalState(() => isVisible = val),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (roleController.text.isNotEmpty && companyController.text.isNotEmpty) {
                                  final messenger = ScaffoldMessenger.of(context);
                                  Navigator.pop(modalContext);
                                  try {
                                    final jobData = JobItem(
                                      id: existingJob?.id ?? '',
                                      company: companyController.text.trim(),
                                      role: roleController.text.trim(),
                                      location: locationController.text.trim(),
                                      salary: salaryController.text.trim(),
                                      deadline: deadlineController.text.trim(),
                                      jobType: selectedJobType!,
                                      description: descriptionController.text.trim(),
                                      applyUrl: applyUrlController.text.trim(),
                                      typeColor: Colors.teal,
                                      iconColor: Colors.blue,
                                      icon: Icons.work,
                                      isVisible: isVisible,
                                      createdByName: currentProfile.value.name,
                                      requirements: requirements,
                                      responsibilities: responsibilities,
                                      category: selectedCategory!,
                                    );
                                    
                                    if (existingJob == null) {
                                      await JobService.addJobToDB(jobData, selectedCategory!);
                                      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Job posted successfully!')));
                                    } else {
                                      await JobService.updateJobInDB(jobData, selectedCategory!);
                                      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Job updated successfully!')));
                                    }
                                  } catch (e) {
                                    if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(existingJob == null ? 'Post Job' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
    );
  }

  Widget _buildListInput(String label, TextEditingController controller, List<String> items, Function(String) onAdd, Function(int) onRemove, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: colors.outline.withOpacity(0.1)),
              itemBuilder: (context, index) => ListTile(
                dense: true,
                title: Text(items[index], style: const TextStyle(fontSize: 14)),
                trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red), onPressed: () => onRemove(index)),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: _inputDecoration('Add $label', Icons.add_circle_outline).copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAdd(controller.text.trim());
                  controller.clear();
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Board'),
      ),
      body: RefreshIndicator(
        onRefresh: () => JobService.fetchJobs(),
        child: ListView(
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
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No recommended jobs.')));
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
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No recent jobs.')));
                }
                return Column(
                  children: visibleJobs.map((job) => _buildJobCard(job, recentJobsState)).toList(),
                );
              },
            ),
          ],
        ),
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