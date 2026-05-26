import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/guided_tour_overlay.dart';
import '../models/job_state.dart';
import '../presentation/bloc/job_bloc.dart';
import '../presentation/bloc/job_event.dart';
import '../presentation/bloc/job_state.dart' as bloc_state;
import 'job_detail_screen.dart';
import '../../../backend/services/job_service.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/validation_rules.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final GlobalKey _jobsHeaderKey = GlobalKey();
  final GlobalKey _addJobFabKey = GlobalKey();
  bool _showTour = false;

  @override
  void initState() {
    super.initState();
    context.read<JobBloc>().add(const FetchJobsRequested());
    TourService.instance.hasCompletedScreenTour('jobs').then((completed) {
      if (!completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _showTour = true;
              });
            }
          });
        });
      }
    });
  }

  void _toggleStar(JobItem job) {
    context.read<JobBloc>().add(UpdateJobRequested(job: job.copyWith(isStarred: !job.isStarred)));
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
    final formKey = GlobalKey<FormState>();

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
              height: MediaQuery.of(context).size.height * 0.75,
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
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(existingJob == null ? 'Post a New Job' : 'Edit Job Posting', 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            
                            _buildTextField(
                              'Job Role', roleController, Icons.work_outline, 'e.g. Software Engineer',
                              validator: (v) => ValidationRules.validateRequired(v, 'Job role'),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Company', companyController, Icons.business, 'e.g. Google',
                              validator: (v) => ValidationRules.validateRequired(v, 'Company name'),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildTextField(
                                  'Location', locationController, Icons.location_on_outlined, 'e.g. Dhaka (Remote)',
                                  validator: (v) => ValidationRules.validateRequired(v, 'Location'),
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(
                                  'Salary/Stipend', salaryController, Icons.payments_outlined, 'e.g. 30k - 40k',
                                  validator: (v) => ValidationRules.validateRequired(v, 'Salary/Stipend'),
                                )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDate,
                                    child: AbsorbPointer(
                                      child: _buildTextField(
                                        'Deadline', deadlineController, Icons.calendar_today_outlined, 'Select Date',
                                        validator: (v) => ValidationRules.validateRequired(v, 'Deadline'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedJobType,
                                    decoration: _inputDecoration('Job Type', Icons.access_time),
                                    validator: (v) => ValidationRules.validateRequired(v, 'Job type'),
                                    items: ['Full Time', 'Part Time', 'Internship'].map((String type) {
                                      return DropdownMenuItem<String>(value: type, child: Text(type));
                                    }).toList(),
                                    onChanged: (value) => setModalState(() => selectedJobType = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
  
                            _buildTextField(
                              'Apply URL', applyUrlController, Icons.link, 'LinkedIn/Google Form link',
                              validator: (v) => ValidationRules.validateUrl(v, 'Apply link'),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              'Description', descriptionController, Icons.description_outlined, 'Summary of the job...', maxLines: 4,
                              validator: (v) => ValidationRules.validateRequired(v, 'Description'),
                            ),
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
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) return;
                                  
                                  Navigator.pop(modalContext);
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
                                    createdByName: existingJob?.createdByName ?? currentProfile.value.name,
                                  );
                                  
                                  if (existingJob == null) {
                                    context.read<JobBloc>().add(AddJobRequested(job: jobData));
                                  } else {
                                    context.read<JobBloc>().add(UpdateJobRequested(job: jobData));
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
      errorStyle: const TextStyle(fontSize: 10, height: 0.8),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    String hint, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = currentProfile.value;
    final isStaff = profile.role == UserRole.committeeMember || profile.role == UserRole.superUser;

    return Stack(
      children: [
        AmbientTimeBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Job Board', key: _jobsHeaderKey),
            ),
            body: BlocListener<JobBloc, bloc_state.JobState>(
            listener: (context, state) {
              if (state is bloc_state.JobError) {
                _showToast(context, state.message, isError: true);
              } else if (state is bloc_state.JobOperationSuccess) {
                _showToast(context, 'Operation successful!', isError: false);
              }
            },
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<JobBloc>().add(const FetchJobsRequested(forceRefresh: true));
              },
              child: BlocBuilder<JobBloc, bloc_state.JobState>(
                builder: (context, state) {
                  List<JobItem> jobs = [];
                  if (state is bloc_state.JobLoading && jobs.isEmpty) {
                    if (JobService.jobItems.isNotEmpty) {
                      jobs = JobService.jobItems;
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  } else if (state is bloc_state.JobLoaded) {
                    jobs = state.items;
                  } else if (state is bloc_state.JobError) {
                    if (JobService.jobItems.isNotEmpty) {
                      jobs = JobService.jobItems;
                    } else {
                      return Center(child: Text('Error loading jobs: ${state.message}'));
                    }
                  }
    
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
          ),
          floatingActionButton: ValueListenableBuilder<ProfileData>(
            valueListenable: currentProfile,
            builder: (context, profile, _) {
              if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
                return FloatingActionButton(
                  key: _addJobFabKey,
                  tooltip: 'Post a new job',
                  onPressed: () => _showJobForm(context),
                  child: const Icon(Icons.add),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      if (_showTour)
        GuidedTourOverlay(
          steps: [
            TourStep(
              targetKey: _jobsHeaderKey,
              title: 'CSE Job & Career Board',
              description: 'Find exciting internship opportunities, fresh graduate jobs, and corporate hiring posts relevant to CSE candidates here.',
            ),
            if (isStaff)
              TourStep(
                targetKey: _addJobFabKey,
                title: 'Add Job Listing',
                description: 'Tapping this button allows committee members and admins to instantly post a new career listing, with editable descriptions and deadlines.',
              ),
          ],
          onComplete: () {
            setState(() => _showTour = false);
            TourService.instance.completeScreenTour('jobs');
          },
          onSkip: () {
            setState(() => _showTour = false);
            TourService.instance.completeScreenTour('jobs');
          },
        ),
    ],
  );
}

  Widget _buildJobCard(JobItem job) {
    final colors = Theme.of(context).colorScheme;
    final profile = currentProfile.value;
    final isAdmin = profile.role == UserRole.committeeMember || profile.role == UserRole.superUser;
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
               if (isAdmin) ...[
                 const Divider(height: 24, thickness: 0.5),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     Text(
                       'Admin Actions',
                       style: TextStyle(
                         fontSize: 11,
                         fontWeight: FontWeight.bold,
                         color: colors.onSurface.withValues(alpha: 0.4),
                         letterSpacing: 0.5,
                       ),
                     ),
                     const Spacer(),
                     _buildJobAdminMenu(context, job, profile),
                   ],
                 ),
               ],
             ],
           ),
         ),
       ),
     );
   }

  Widget _buildJobAdminMenu(BuildContext context, JobItem job, ProfileData profile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!job.isApproved && (profile.designation == 'President' || profile.designation == 'Vice President')) ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Approve Job',
            onPressed: () {
              context.read<JobBloc>().add(ApproveJobRequested(itemId: job.id));
            },
          ),
          const SizedBox(width: 12),
        ],
        IconButton(
          icon: Icon(job.isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.orange, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: job.isVisible ? 'Hide Job' : 'Show Job',
          onPressed: () {
            context.read<JobBloc>().add(ToggleJobVisibilityRequested(itemId: job.id, isVisible: !job.isVisible));
          },
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Edit Job',
          onPressed: () => _showJobForm(context, existingJob: job),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Delete Job',
          onPressed: () {
            context.read<JobBloc>().add(DeleteJobRequested(itemId: job.id));
          },
        ),
      ],
    );
  }

  void _showToast(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}