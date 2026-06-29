import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/results/models/result_state.dart';
import 'package:ShEC_CSE/features/results/screens/cgpa_prediction_chart.dart';
import 'package:ShEC_CSE/features/results/utils/results_pdf_generator.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';

class StudentResultsViewerScreen extends StatefulWidget {
  final ProfileData profile;
  final List<ExamResult> results;

  const StudentResultsViewerScreen({
    super.key,
    required this.profile,
    required this.results,
  });

  @override
  State<StudentResultsViewerScreen> createState() => _StudentResultsViewerScreenState();
}

class _StudentResultsViewerScreenState extends State<StudentResultsViewerScreen> {
  String? _expandedResultId;

  int _parseSemesterNumber(String examName) {
    final name = examName.toLowerCase();
    if (name.contains('1st year 1st') || name.contains('1st sem') || name.contains('1-1') || (name.contains('1st year') && name.contains('1st'))) return 1;
    if (name.contains('1st year 2nd') || name.contains('2nd sem') || name.contains('1-2') || (name.contains('1st year') && name.contains('2nd'))) return 2;
    if (name.contains('2nd year 1st') || name.contains('3rd sem') || name.contains('2-1') || (name.contains('2nd year') && name.contains('1st'))) return 3;
    if (name.contains('2nd year 2nd') || name.contains('4th sem') || name.contains('2-2') || (name.contains('2nd year') && name.contains('2nd'))) return 4;
    if (name.contains('3rd year 1st') || name.contains('5th sem') || name.contains('3-1') || (name.contains('3rd year') && name.contains('1st'))) return 5;
    if (name.contains('3rd year 2nd') || name.contains('6th sem') || name.contains('3-2') || (name.contains('3rd year') && name.contains('2nd'))) return 6;
    if (name.contains('4th year 1st') || name.contains('7th sem') || name.contains('4-1') || (name.contains('4th year') && name.contains('1st'))) return 7;
    if (name.contains('4th year 2nd') || name.contains('8th sem') || name.contains('4-2') || (name.contains('4th year') && name.contains('2nd'))) return 8;

    if (name.contains('1st')) return 1;
    if (name.contains('2nd')) return 2;
    if (name.contains('3rd')) return 3;
    if (name.contains('4th')) return 4;
    if (name.contains('5th')) return 5;
    if (name.contains('6th')) return 6;
    if (name.contains('7th')) return 7;
    if (name.contains('8th')) return 8;

    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final sortedResults = List<ExamResult>.from(widget.results)
      ..sort((a, b) {
        final semA = a.semester ?? _parseSemesterNumber(a.examName);
        final semB = b.semester ?? _parseSemesterNumber(b.examName);
        return semA.compareTo(semB);
      });

    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('${widget.profile.name}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download Consolidated PDF',
              onPressed: () {
                if (widget.results.isNotEmpty) {
                  ResultsPdfGenerator.generateAndShareConsolidatedPdf(
                    context, 
                    widget.profile, 
                    widget.results,
                  );
                } else {
                  SnackBarUtils.showInfo(context, 'No results available to download.');
                }
              },
            ),
          ],
        ),
        body: sortedResults.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_late_outlined, size: 64, color: colors.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No results synced.',
                        style: TextStyle(fontSize: 18, color: colors.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This user has not synced their academic results yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Student Details Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                    ),
                    color: colors.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: colors.primary.withValues(alpha: 0.1),
                                backgroundImage: widget.profile.imagePath != null
                                    ? NetworkImage(widget.profile.imagePath!)
                                    : null,
                                child: widget.profile.imagePath == null
                                    ? Text(
                                        (widget.profile.name.isNotEmpty ? widget.profile.name[0] : '?').toUpperCase(),
                                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.profile.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Roll: ${widget.profile.classRoll.isNotEmpty ? widget.profile.classRoll : "—"}  •  ID: ${widget.profile.universityId.isNotEmpty ? widget.profile.universityId : "—"}',
                                      style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoLabel('Session', widget.profile.session, colors),
                              _buildInfoLabel('Batch', 'Batch ${widget.profile.batch}', colors),
                              _buildInfoLabel('Reg No', widget.profile.duRegNo, colors),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trend Graph Card
                  CgpaPredictionChart(results: widget.results, showPredictions: false),
                  const SizedBox(height: 20),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.format_list_bulleted, size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Semester Results',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List of Completed Semesters
                  ...sortedResults.map((result) => _buildResultCard(context, result, colors, widget.results)),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoLabel(String title, String value, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 9, color: colors.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value.isNotEmpty ? value : '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, ExamResult result, ColorScheme colors, List<ExamResult> allResults) {
    final semNum = result.semester ?? _parseSemesterNumber(result.examName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      color: colors.surfaceContainerLow,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('v_${result.id}_${result.id == _expandedResultId}'),
          initiallyExpanded: result.id == _expandedResultId,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedResultId = result.id;
              } else if (_expandedResultId == result.id) {
                _expandedResultId = null;
              }
            });
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Semester $semNum',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.blueAccent, size: 20),
                tooltip: 'Download Semester PDF',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => ResultsPdfGenerator.generateAndShareSemesterPdf(context, widget.profile, result, allResults: allResults),
              ),
              const SizedBox(width: 8),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                _buildScoreChip(context, 'GPA: ${result.gpa}', Colors.blue, colors),
                const SizedBox(width: 8),
                _buildScoreChip(context, 'CGPA: ${result.cgpa}', Colors.green, colors),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                result.examName,
                style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
              ),
            ),
            const Divider(height: 1),
            ...result.subjects.map((subject) => _buildSubjectRow(context, subject, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(BuildContext context, String text, MaterialColor color, ColorScheme colors) {
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

  Widget _buildSubjectRow(BuildContext context, SubjectResult subject, ColorScheme colors) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
