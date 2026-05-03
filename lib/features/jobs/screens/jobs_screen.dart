import 'package:flutter/material.dart';
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

  void _toggleStar(JobItem job) async {
    try {
      job.isStarred = !job.isStarred;
      jobsState.value = List.from(jobsState.value);
      await JobService.updateJobInDB(job);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating star: $e')));
    }
  }

  void _deleteJob(JobItem job) async {
    try {
      await JobService.deleteJobFromDB(job.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting job: $e')));
    }
  }

  void _showJobForm(BuildContext context, {JobItem? existingJob}) {
    final roleController = TextEditingController(text: existingJob?.role ?? '');
    final companyController = TextEditingController(text: existingJob?.company ?? '');
    final locationController = TextEditingController(text: existingJob?.location ?? '');
    final salaryController = TextEditingController(text: existingJob?.salary ?? '');
    final deadlineController = TextEditingController(text: existingJob?.deadline ?? '');
    final descriptionController = TextEditingController(text: existingJob?.description ?? '');
    final applyUrlController = TextEditingController(text: existingJob?.applyUrl ?? '');
    
    String? selectedJobType = existingJob?.jobType ?? 'Full Time';
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
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
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

                          _buildTextField('Apply URL', applyUrlController, Icons.link, 'LinkedIn/Google Form link'),
                          const SizedBox(height: 16),
                          
                          _buildTextField('Description', descriptionController, Icons.description_outlined, 'Summary of the job...', maxLines: 4),
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: colors.primaryContainer.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: SwitchListTile(
                              title: const Text('Visible to Public Members', style: TextStyle(fontWeight: FontWeight.w600)),
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
                                      isVisible: isVisible,
                                      createdByName: currentProfile.value.name,
                                    );
                                    
                                    if (existingJob == null) {
                                      await JobService.addJobToDB(jobData);
                                      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Job posted successfully!')));
                                    } else {
                                      await JobService.updateJobInDB(jobData);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Board'),
      ),
      body: RefreshIndicator(
        onRefresh: () => JobService.fetchJobs(),
        child: ValueListenableBuilder<List<JobItem>>(
          valueListenable: jobsState,
          builder: (context, jobs, _) {
            final profile = currentProfile.value;
            final isAdmin = profile.role != UserRole.student;
            final visibleJobs = jobs.where((j) {
              if (isAdmin) return true;
              return j.isApproved && j.isVisible;
            }).toList();

            if (visibleJobs.isEmpty) {
              return const Center(child: Text('No jobs posted yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleJobs.length,
              itemBuilder: (context, index) => _buildJobCard(visibleJobs[index]),
            );
          },
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

  Widget _buildJobCard(JobItem job) {
    final colors = Theme.of(context).colorScheme;
    const iconColor = Colors.blue;
    const typeColor = Colors.teal;

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
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.work, color: iconColor, size: 28),
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
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                job.isStarred ? Icons.star : Icons.star_border,
                                color: job.isStarred ? Colors.amber : colors.onSurface.withValues(alpha: 0.3),
                              ),
                              onPressed: () => _toggleStar(job),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            ValueListenableBuilder<ProfileData>(
                              valueListenable: currentProfile,
                              builder: (context, profile, _) {
                                if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
                                  return PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showJobForm(context, existingJob: job);
                                      } else if (value == 'delete') {
                                        _deleteJob(job);
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
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      job.jobType,
                      style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold),
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