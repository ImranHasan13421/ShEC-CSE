import 'package:flutter/material.dart';
import '../models/result_state.dart';
import '../../../backend/services/result_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    ResultService.loadResultsFromDB();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isSyncingResults,
            builder: (context, isSyncing, _) {
              if (isSyncing) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync Results',
                onPressed: () {
                  ResultService.syncResults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing results... this may take a moment.')),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<ExamResult>>(
        valueListenable: studentResultsState,
        builder: (context, results, _) {
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
        },
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
    if (subject.grade.startsWith('A')) gradeColor = Colors.green;
    else if (subject.grade.startsWith('B')) gradeColor = Colors.blue;
    else if (subject.grade.startsWith('C')) gradeColor = Colors.orange;
    else if (subject.grade == 'F') gradeColor = Colors.red;

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
