import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/resource_state.dart';
import '../../../backend/services/resource_service.dart';

// ==========================================
// 1. YEARS SCREEN
// ==========================================
class YearsScreen extends StatelessWidget {
  const YearsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20.0, left: 4.0),
            child: Column(
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
          _buildYearCard(context, 1, '1st Year', Colors.blue, 'Semesters 1 & 2'),
          _buildYearCard(context, 2, '2nd Year', Colors.teal, 'Semesters 3 & 4'),
          _buildYearCard(context, 3, '3rd Year', Colors.indigo, 'Semesters 5 & 6'),
          _buildYearCard(context, 4, '4th Year', Colors.orange, 'Semesters 7 & 8'),
        ],
      ),
    );
  }

  Widget _buildYearCard(BuildContext context, int yearIndex, String title, Color color, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
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
                  color: color.withOpacity(0.1),
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
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.onSurfaceVariant.withOpacity(0.5)),
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
    // Determine actual semester number (1-8)
    final int actualSem = ((yearIndex - 1) * 2) + semIndex;
    final String semTitle = '$semIndex${semIndex == 1 ? "st" : "nd"} Semester';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
    // Dynamic session list based on recent years
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
              side: BorderSide(color: colors.outline.withOpacity(0.1)),
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
    ResourceService.fetchResources();
  }

  void _showForm(BuildContext context, {ResourceItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final urlController = TextEditingController(text: existingItem?.fileUrl ?? '');

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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Resource Title (e.g. Midterm Q 2023)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'File URL (Google Drive/Dropbox)', border: OutlineInputBorder()),
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
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(modalContext);
                      try {
                        final newItem = ResourceItem(
                          id: existingItem?.id ?? '',
                          name: nameController.text.trim(),
                          date: DateTime.now().toString().split(' ')[0],
                          session: widget.session,
                          semester: widget.semester,
                          fileUrl: urlController.text.trim(),
                          uploadedBy: currentProfile.value.id,
                        );

                        if (existingItem == null) {
                          await ResourceService.addResourceToDB(newItem);
                          if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Resource uploaded!')));
                        } else {
                          await ResourceService.updateResourceInDB(newItem);
                          ResourceService.fetchResources(); // Refresh
                          if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Resource updated!')));
                        }
                      } catch (e) {
                        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: Text(existingItem == null ? 'Upload Now' : 'Save Changes'),
                ),
              ),
            ],
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

    if (confirm == true) {
      try {
        await ResourceService.deleteResourceFromDB(item);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.session)),
      body: ValueListenableBuilder<List<ResourceItem>>(
        valueListenable: resourceState,
        builder: (context, items, _) {
          // Filter resources for this specific session AND semester
          final sessionItems = items.where((i) => i.session == widget.session && i.semester == widget.semester).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withOpacity(0.1)),
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
                        Icon(Icons.cloud_off_rounded, size: 64, color: colors.onSurfaceVariant.withOpacity(0.2)),
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
                  side: BorderSide(color: colors.outline.withOpacity(0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
                          // Launch URL (requires url_launcher)
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening resource link...')));
                        },
                      ),
                      ValueListenableBuilder<ProfileData>(
                        valueListenable: currentProfile,
                        builder: (context, profile, _) {
                          if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded),
                              onSelected: (value) {
                                if (value == 'edit') _showForm(context, existingItem: res);
                                if (value == 'delete') _deleteItem(res);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Update Details')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete File', style: TextStyle(color: Colors.red))),
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
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role == UserRole.committeeMember || profile.role == UserRole.superUser) {
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