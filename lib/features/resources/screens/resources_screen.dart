import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import '../models/resource_state.dart';

// ==========================================
// 1. YEARS SCREEN
// ==========================================
class YearsScreen extends StatelessWidget {
  const YearsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previous Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 4.0),
            child: Text(
              'Select Academic Year',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildYearCard(context, 1, '1st Year', Colors.blue),
          _buildYearCard(context, 2, '2nd Year', Colors.teal),
          _buildYearCard(context, 3, '3rd Year', Colors.indigo),
          _buildYearCard(context, 4, '4th Year', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildYearCard(BuildContext context, int yearIndex, String title, Color color) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.school, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: const Text('Question papers & resources'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SemestersScreen(yearIndex: yearIndex, yearName: title, color: color)),
          );
        },
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
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 4.0),
            child: Text('Select Semester', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildSemesterCard(context, 1, colors),
          _buildSemesterCard(context, 2, colors),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(BuildContext context, int semIndex, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.layers, color: color),
        ),
        title: Text('Semester $semIndex', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionsScreen(yearIndex: yearIndex, yearName: yearName, semIndex: semIndex, color: color),
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
  final Color color;

  const SessionsScreen({
    super.key,
    required this.yearIndex,
    required this.yearName,
    required this.semIndex,
    required this.color,
  });

  List<String> _getValidSessions() {
    if (yearIndex == 4) {
      if (semIndex == 1) return ['19-20', '20-21'];
      if (semIndex == 2) return ['19-20'];
    } else if (yearIndex == 3) {
      if (semIndex == 1) return ['19-20', '20-21', '21-22'];
      if (semIndex == 2) return ['19-20', '20-21'];
    } else if (yearIndex == 2) {
      if (semIndex == 1) return ['19-20', '20-21', '21-22', '22-23'];
      if (semIndex == 2) return ['19-20', '20-21', '21-22'];
    } else if (yearIndex == 1) {
      if (semIndex == 1) return ['19-20', '20-21', '21-22', '22-23', '23-24', '24-25'];
      if (semIndex == 2) return ['19-20', '20-21', '21-22', '22-23', '23-24'];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sessions = _getValidSessions();

    return Scaffold(
      appBar: AppBar(title: Text('$yearName - Sem $semIndex')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 4.0),
            child: Text(
              'Available Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (sessions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No sessions available.'),
              ),
            ),
          ...sessions.map((session) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outline.withOpacity(0.1)),
            ),
            child: ListTile(
              leading: Icon(Icons.calendar_month, color: color),
              title: Text(
                'Session $session',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfsScreen(
                      title: 'Session $session Resources',
                      session: session,
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
class PdfsScreen extends StatelessWidget {
  final String title;
  final String session;
  final Color color;

  const PdfsScreen({super.key, required this.title, required this.session, required this.color});

  void _showForm(BuildContext context, {ResourceItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final sizeController = TextEditingController(text: existingItem?.size ?? '1.5 MB');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existingItem == null ? 'Add Resource' : 'Edit Resource', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'File Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(labelText: 'File Size', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final newItem = ResourceItem(
                        id: existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        size: sizeController.text,
                        date: 'Just now',
                        session: session,
                      );

                      if (existingItem == null) {
                        resourceState.value = List.from(resourceState.value)..insert(0, newItem);
                      } else {
                        final index = resourceState.value.indexOf(existingItem);
                        if (index != -1) {
                          final updatedList = List<ResourceItem>.from(resourceState.value);
                          updatedList[index] = newItem;
                          resourceState.value = updatedList;
                        }
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(existingItem == null ? 'Upload' : 'Update'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _deleteItem(ResourceItem item) {
    resourceState.value = List.from(resourceState.value)..remove(item);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ValueListenableBuilder<List<ResourceItem>>(
        valueListenable: resourceState,
        builder: (context, items, _) {
          // Filter resources for this specific session
          final sessionItems = items.where((i) => i.session == session).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These are placeholder files. You can add or edit resources if you are a Committee Member.',
                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (sessionItems.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No resources uploaded yet.'))),
              ...sessionItems.map((pdf) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.outline.withOpacity(0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  ),
                  title: Text(pdf.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Text(pdf.size, style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('• ${pdf.date}', style: TextStyle(color: colors.onSurface.withOpacity(0.4), fontSize: 12)),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.download, color: color),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloading file...')),
                          );
                        },
                      ),
                      ValueListenableBuilder<ProfileData>(
                        valueListenable: currentProfile,
                        builder: (context, profile, _) {
                          if (profile.role == UserRole.committeeMember) {
                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showForm(context, existingItem: pdf);
                                } else if (value == 'delete') {
                                  _deleteItem(pdf);
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
                ),
              )),
            ],
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<ProfileData>(
        valueListenable: currentProfile,
        builder: (context, profile, _) {
          if (profile.role == UserRole.committeeMember) {
            return FloatingActionButton(
              onPressed: () => _showForm(context),
              child: const Icon(Icons.upload_file),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}