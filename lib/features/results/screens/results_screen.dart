import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/models/profile_state.dart';
import '../models/result_state.dart';
import '../../../backend/services/result_service.dart';
import '../presentation/bloc/result_bloc.dart';
import '../presentation/bloc/result_event.dart';
import '../presentation/bloc/result_state.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    context.read<ResultBloc>().add(LoadResultsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<ResultBloc, ResultState>(
      listener: (context, state) {
        if (state is ResultSyncInProgress) {
          _isSyncing = true;
        } else if (state is ResultsLoaded && _isSyncing) {
          _isSyncing = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sync complete!')),
          );
        } else if (state is ResultError) {
          _isSyncing = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isSyncing = state is ResultSyncInProgress;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Results'),
            actions: [
              if (isSyncing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync Results',
                  onPressed: () {
                    context.read<ResultBloc>().add(SyncResultsRequested());
                  },
                ),
                if (currentProfile.value.role == UserRole.superUser || 
                    currentProfile.value.designation == 'President' || 
                    currentProfile.value.designation == 'Vice President')
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.admin_panel_settings),
                    onSelected: (val) {
                      if (val == 'session') {
                        _showAdminIdDialog('Session');
                      }
                      if (val == 'exam') {
                        showDialog(
                          context: context,
                          builder: (context) => const _ManageExamsDialog(),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'session', child: Text('Manage Session IDs')),
                      const PopupMenuItem(value: 'exam', child: Text('Manage Exam IDs')),
                    ],
                  ),
              ],
            ],
          ),
          body: Column(
            children: [
              // 1. Progress Bar at the Top
              if (isSyncing)
                Column(
                  children: [
                    const LinearProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Syncing academic results... please wait',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 4), // Spacer when not syncing
              
              // 2. Main Content
              Expanded(
                child: _buildMainContent(context, state, colors),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, ResultState state, ColorScheme colors) {
    if (state is ResultLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    List<ExamResult> results = [];
    if (state is ResultsLoaded) {
      results = state.results;
    } else if (state is ResultSyncInProgress) {
      results = state.results;
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_late, size: 64, color: colors.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'No results found.',
                style: TextStyle(fontSize: 18, color: colors.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the Sync icon in the top right to fetch your latest results.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(context, result);
      },
    );
  }

  void _showAdminIdDialog(String type) {
    final nameController = TextEditingController();
    final idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: type == 'Session' ? 'Session Name (e.g., 2020-2021)' : 'Exam Name (e.g., 1st Year)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: '$type ID (from DUCMC)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final id = idController.text.trim();
              if (name.isEmpty || id.isEmpty) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                if (type == 'Session') {
                  await ResultService.addSessionId(name, id);
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('$type ID saved successfully')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ExamResult result) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
          title: Text(
            result.examName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                _buildScoreChip(context, 'GPA: ${result.gpa}', Colors.blue),
                const SizedBox(width: 8),
                _buildScoreChip(context, 'CGPA: ${result.cgpa}', Colors.green),
              ],
            ),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            ...result.subjects.map((subject) => _buildSubjectRow(context, subject)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(BuildContext context, String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.shade900, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSubjectRow(BuildContext context, SubjectResult subject) {
    final colors = Theme.of(context).colorScheme;
    
    // Determine grade color
    Color gradeColor = Colors.grey;
    if (subject.grade.startsWith('A')) {
      gradeColor = Colors.green;
    } else if (subject.grade.startsWith('B')) {
      gradeColor = Colors.blue;
    } else if (subject.grade.startsWith('C')) {
      gradeColor = Colors.orange;
    } else if (subject.grade == 'F') {
      gradeColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.code,
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subject.name,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                subject.grade,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: gradeColor),
              ),
              Text(
                subject.point,
                style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageExamsDialog extends StatefulWidget {
  const _ManageExamsDialog();

  @override
  State<_ManageExamsDialog> createState() => _ManageExamsDialogState();
}

class _ManageExamsDialogState extends State<_ManageExamsDialog> {
  List<Map<String, String>> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final exams = await ResultService.fetchAllExams();
    if (mounted) {
      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Manage Exam IDs'),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blue),
            tooltip: 'Add New Exam ID',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const _AddEditExamDialog(),
              );
              if (result == true) {
                _loadExams();
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _exams.isEmpty
                ? const Center(
                    child: Text('No exam IDs configured yet.'),
                  )
                : ListView.separated(
                    itemCount: _exams.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final exam = _exams[index];
                      final examId = exam['exam_id'] ?? '';
                      final examName = exam['exam_name'] ?? '';
                      final session = exam['session'] ?? '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          examName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: $examId'),
                              Text(
                                'Session: ${session.isEmpty ? 'None (Needs Update!)' : session}',
                                style: TextStyle(
                                  color: session.isEmpty ? Colors.red : colors.primary,
                                  fontWeight: session.isEmpty ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => _AddEditExamDialog(examToEdit: exam),
                                );
                                if (result == true) {
                                  _loadExams();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(examId, examName),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _confirmDelete(String examId, String examName) {
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete the exam configuration for "$examName" (ID: $examId)?'),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await ResultService.deleteExamId(examId);
                  navigator.pop(); // Close confirm dialog
                  _loadExams(); // Refresh list
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Exam ID deleted successfully')),
                  );
                } catch (e) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _AddEditExamDialog extends StatefulWidget {
  final Map<String, String>? examToEdit;

  const _AddEditExamDialog({this.examToEdit});

  @override
  State<_AddEditExamDialog> createState() => _AddEditExamDialogState();
}

class _AddEditExamDialogState extends State<_AddEditExamDialog> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  String? _selectedSession;
  List<String> _sessions = [];
  bool _isLoadingSessions = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.examToEdit != null) {
      _nameController.text = widget.examToEdit!['exam_name'] ?? '';
      _idController.text = widget.examToEdit!['exam_id'] ?? '';
      _selectedSession = widget.examToEdit!['session'];
      if (_selectedSession != null && _selectedSession!.isEmpty) {
        _selectedSession = null;
      }
    }
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await ResultService.fetchSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        // Verify that if we have a pre-selected session, it exists in the list
        if (_selectedSession != null && !_sessions.contains(_selectedSession)) {
          // If it doesn't exist, we temporarily add it so it can display properly
          _sessions.add(_selectedSession!);
        }
        _isLoadingSessions = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.examToEdit != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Exam ID' : 'Add Exam ID'),
      content: _isLoadingSessions
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Exam Name (e.g., 1st Year)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _idController,
                    enabled: !isEdit, // Cannot edit the ID since it is the unique identifier
                    decoration: InputDecoration(
                      labelText: 'Exam ID (from DUCMC)',
                      border: const OutlineInputBorder(),
                      helperText: isEdit ? 'Exam ID cannot be changed' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSession,
                    decoration: const InputDecoration(
                      labelText: 'Session Name *',
                      border: OutlineInputBorder(),
                      helperText: 'Must match student session exactly',
                    ),
                    items: _sessions.map((session) {
                      return DropdownMenuItem<String>(
                        value: session,
                        child: Text(session),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSession = val;
                      });
                    },
                    validator: (val) => val == null ? 'Session is required' : null,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _isLoadingSessions ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final session = _selectedSession;

    if (name.isEmpty || id.isEmpty || session == null || session.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ResultService.addExamId(name, id, session);
      navigator.pop(true); // Return true to indicate successful save
    } catch (e) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
