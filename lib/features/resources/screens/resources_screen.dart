import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/permissions/services/permissions_service.dart';
import 'package:ShEC_CSE/features/permissions/models/committee_permission.dart';
import '../models/resource_state.dart';
import '../presentation/bloc/resource_bloc.dart';
import '../presentation/bloc/resource_event.dart';
import '../presentation/bloc/resource_state.dart' as bloc_state;
import '../../../backend/services/resource_service.dart';
import 'package:ShEC_CSE/core/utils/validation_rules.dart';

// ==========================================
// 1. YEARS SCREEN
// ==========================================
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/guided_tour_overlay.dart';

// ==========================================
// 1. YEARS SCREEN
// ==========================================
class YearsScreen extends StatefulWidget {
  const YearsScreen({super.key});

  @override
  State<YearsScreen> createState() => _YearsScreenState();
}

class _YearsScreenState extends State<YearsScreen> {
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _yearCardKey = GlobalKey();
  bool _showTour = false;

  @override
  void initState() {
    super.initState();
    TourService.instance.hasCompletedScreenTour('resources_years').then((completed) {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Academic Resources')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Padding(
                key: _headerKey,
                padding: const EdgeInsets.only(bottom: 20.0, left: 4.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Academic Year',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Find question papers, notes and more',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _buildYearCard(context, 1, '1st Year', Colors.blue, 'Semesters 1 & 2', key: _yearCardKey),
              _buildYearCard(context, 2, '2nd Year', Colors.teal, 'Semesters 3 & 4'),
              _buildYearCard(context, 3, '3rd Year', Colors.indigo, 'Semesters 5 & 6'),
              _buildYearCard(context, 4, '4th Year', Colors.orange, 'Semesters 7 & 8'),
            ],
          ),
        ),
        if (_showTour)
          GuidedTourOverlay(
            steps: [
              TourStep(
                targetKey: _headerKey,
                title: 'Academic Resources Portal',
                description: 'Welcome! This portal contains curated previous year questions, lecture notes, syllabus updates, and course guides.',
              ),
              TourStep(
                targetKey: _yearCardKey,
                title: 'Year-Specific Directories',
                description: 'Tap on any academic year to explore session folders, choose your specific semester, and view the file listing.',
              ),
            ],
            onComplete: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('resources_years');
            },
            onSkip: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('resources_years');
            },
          ),
      ],
    );
  }

  Widget _buildYearCard(BuildContext context, int yearIndex, String title, Color color, String subtitle, {Key? key}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SemestersScreen(yearIndex: yearIndex, yearName: title, color: color)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. SEMESTERS SCREEN
// ==========================================
class SemestersScreen extends StatelessWidget {
  final int yearIndex;
  final String yearName;
  final Color color;

  const SemestersScreen({super.key, required this.yearIndex, required this.yearName, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(yearName)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0, left: 4.0),
            child: Text(
              'Select Semester',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
          ),
          _buildSemesterCard(context, 1, colors),
          _buildSemesterCard(context, 2, colors),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(BuildContext context, int semIndex, ColorScheme colors) {
    final int actualSem = ((yearIndex - 1) * 2) + semIndex;
    final String semTitle = '$semIndex${semIndex == 1 ? "st" : "nd"} Semester';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.layers_rounded, color: color),
        ),
        title: Text(semTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text('Full resource list for semester $actualSem'),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionsScreen(
                yearIndex: yearIndex, 
                yearName: yearName, 
                semIndex: semIndex, 
                semTitle: semTitle,
                color: color
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. SESSIONS SCREEN
// ==========================================
class SessionsScreen extends StatelessWidget {
  final int yearIndex;
  final String yearName;
  final int semIndex;
  final String semTitle;
  final Color color;

  const SessionsScreen({
    super.key,
    required this.yearIndex,
    required this.yearName,
    required this.semIndex,
    required this.semTitle,
    required this.color,
  });

  List<String> _getValidSessions() {
    return ['24-25', '23-24', '22-23', '21-22', '20-21', '19-20'];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sessions = _getValidSessions();

    return Scaffold(
      appBar: AppBar(title: Text(semTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0, left: 4.0),
            child: Text(
              'Select Session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
          ),
          ...sessions.map((session) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              leading: Icon(Icons.calendar_today_rounded, color: color),
              title: Text('Session $session', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfsScreen(
                      title: 'Session $session Resources',
                      session: session,
                      semester: semTitle,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================
// 4. PDFs (FILES) SCREEN
// ==========================================
class PdfsScreen extends StatefulWidget {
  final String title;
  final String session;
  final String semester;
  final Color color;

  const PdfsScreen({
    super.key, 
    required this.title, 
    required this.session, 
    required this.semester,
    required this.color
  });

  @override
  State<PdfsScreen> createState() => _PdfsScreenState();
}

class _PdfsScreenState extends State<PdfsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ResourceBloc>().add(const FetchResourcesRequested());
  }

  void _showForm(BuildContext context, {ResourceItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final urlController = TextEditingController(text: existingItem?.fileUrl ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final colors = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: colors.outlineVariant, borderRadius: BorderRadius.circular(2)),
                ),
                Text(existingItem == null ? 'Upload Resource' : 'Update Resource', 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${widget.semester} • Session ${widget.session}', 
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Title (e.g. Midterm Q 2023)', 
                    border: OutlineInputBorder(),
                    errorStyle: TextStyle(fontSize: 10, height: 0.8),
                  ),
                  validator: (v) => ValidationRules.validateRequired(v, 'Resource title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'File URL (Google Drive/Dropbox)', 
                    border: OutlineInputBorder(),
                    errorStyle: TextStyle(fontSize: 10, height: 0.8),
                  ),
                  validator: (v) => ValidationRules.validateUrl(v, 'File URL'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      
                      Navigator.pop(modalContext);
                      final newItem = ResourceItem(
                        id: existingItem?.id ?? '',
                        name: nameController.text.trim(),
                        date: existingItem?.date ?? DateTime.now().toString().split(' ')[0],
                        session: widget.session,
                        semester: widget.semester,
                        fileUrl: urlController.text.trim(),
                        uploadedBy: existingItem?.uploadedBy ?? currentProfile.value.id,
                      );

                      if (existingItem == null) {
                        context.read<ResourceBloc>().add(AddResourceRequested(item: newItem));
                      } else {
                        context.read<ResourceBloc>().add(UpdateResourceRequested(item: newItem));
                      }
                    },
                    child: Text(existingItem == null ? 'Upload Now' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteItem(ResourceItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<ResourceBloc>().add(DeleteResourceRequested(item: item));
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.session)),
      body: BlocListener<ResourceBloc, bloc_state.ResourceState>(
        listener: (context, state) {
          if (state is bloc_state.ResourceError) {
            _showToast(context, state.message, isError: true);
          } else if (state is bloc_state.ResourceOperationSuccess) {
            _showToast(context, 'Operation successful!', isError: false);
          }
        },
        child: BlocBuilder<ResourceBloc, bloc_state.ResourceState>(
          builder: (context, state) {
            List<ResourceItem> items = [];
            if (state is bloc_state.ResourceLoading && items.isEmpty) {
              if (ResourceService.resources.isNotEmpty) {
                items = ResourceService.resources;
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            } else if (state is bloc_state.ResourceLoaded) {
              items = state.items;
            } else if (state is bloc_state.ResourceError) {
              if (ResourceService.resources.isNotEmpty) {
                items = ResourceService.resources;
              } else {
                return Center(child: Text('Error loading resources: ${state.message}'));
              }
            }

            final sessionItems = items.where((i) => i.session == widget.session && i.semester == widget.semester).toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.color.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded, color: widget.color),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${widget.semester} Resources', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Academic Session ${widget.session}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (sessionItems.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(64),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 64, color: colors.onSurfaceVariant.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text('No resources found', style: TextStyle(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ...sessionItems.map((res) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.insert_drive_file_rounded, color: Colors.redAccent),
                    ),
                    title: Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Uploaded on ${res.date}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.open_in_new_rounded, color: widget.color),
                          onPressed: () {
                            // Link open can be handled or launch URL
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening resource link...')));
                          },
                        ),
                        ValueListenableBuilder<CommitteePermission?>(
                          valueListenable: PermissionsService.currentPermissions,
                          builder: (context, currentPerms, _) {
                            final profile = currentProfile.value;
                            final canManage = profile.role == UserRole.superUser ||
                                (profile.role == UserRole.committeeMember && (currentPerms?.canManageResources ?? false)) ||
                                profile.designation == 'President' ||
                                profile.designation == 'Vice President';

                            if (canManage) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                    onPressed: () => _showForm(context, existingItem: res),
                                    tooltip: 'Update Details',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _deleteItem(res),
                                    tooltip: 'Delete File',
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
      floatingActionButton: ValueListenableBuilder<CommitteePermission?>(
        valueListenable: PermissionsService.currentPermissions,
        builder: (context, currentPerms, _) {
          final profile = currentProfile.value;
          final canManage = profile.role == UserRole.superUser ||
              (profile.role == UserRole.committeeMember && (currentPerms?.canManageResources ?? false)) ||
              profile.designation == 'President' ||
              profile.designation == 'Vice President';

          if (canManage) {
            return FloatingActionButton.extended(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add File'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}