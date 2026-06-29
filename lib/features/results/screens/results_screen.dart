import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/results/utils/results_pdf_generator.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/guided_tour_overlay.dart';
import 'package:ShEC_CSE/features/cgpa_calculator/screens/cgpa_calculator_screen.dart';
import '../../profile/models/profile_state.dart';
import '../models/result_state.dart';
import '../../../backend/services/result_service.dart';
import '../presentation/bloc/result_bloc.dart';
import '../presentation/bloc/result_event.dart';
import '../presentation/bloc/result_state.dart';
import 'cgpa_prediction_chart.dart';
import 'batch_results_tab.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSyncing = false;
  String? _expandedResultId;

  // Guided Tour keys and control state
  final GlobalKey _syncButtonKey = GlobalKey();
  final GlobalKey _tabBarKey = GlobalKey();
  final GlobalKey _chartKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  bool _showTour = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initial load for own results
    context.read<ResultBloc>().add(LoadResultsRequested());

    // Trigger onboarding guided tour
    TourService.instance.hasCompletedScreenTour('results_tour').then((completed) {
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

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;

    if (_tabController.index == 0) {
      context.read<ResultBloc>().add(LoadResultsRequested());
    } else {
      context.read<ResultBloc>().add(LoadBatchResultsRequested(session: currentProfile.value.session));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<ResultBloc, ResultState>(
      listener: (context, state) {
        if (state.isSyncing) {
          _isSyncing = true;
        } else if (!state.isSyncing && _isSyncing && state.errorMessage == null) {
          _isSyncing = false;
          SnackBarUtils.showSuccess(context, 'Sync complete!');
        } else if (state.errorMessage != null) {
          _isSyncing = false;
          SnackBarUtils.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final isSyncing = state.isSyncing;

        return Stack(
          children: [
            AmbientTimeBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  elevation: 0,
                  title: const Text('Academic Results'),
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
                        key: _syncButtonKey,
                        icon: const Icon(Icons.sync),
                        tooltip: 'Sync Results',
                        onPressed: () {
                          if (_tabController.index == 0) {
                            context.read<ResultBloc>().add(SyncResultsRequested());
                          } else {
                            context.read<ResultBloc>().add(LoadBatchResultsRequested(session: currentProfile.value.session));
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_rounded),
                        tooltip: 'Download Consolidated Report',
                        onPressed: () {
                          final resultsState = context.read<ResultBloc>().state;
                          if (resultsState.ownResults.isNotEmpty) {
                            _generateAndShareFullReport(context, resultsState.ownResults);
                          } else {
                            SnackBarUtils.showInfo(context, 'No results available to download.');
                          }
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
                  bottom: TabBar(
                    key: _tabBarKey,
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'My Results', icon: Icon(Icons.dashboard_outlined)),
                      Tab(text: 'Batch Results', icon: Icon(Icons.group_outlined)),
                    ],
                  ),
                ),
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: My Dashboard
                    Column(
                      children: [
                        // Progress Bar at the Top
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
                        
                        Expanded(
                          child: _buildOwnDashboard(context, state, colors),
                        ),
                      ],
                    ),
                    // Tab 2: Batch Directory
                    const BatchResultsTab(),
                  ],
                ),
                floatingActionButton: isSyncing || _tabController.index == 1
                    ? null
                    : FloatingActionButton.extended(
                        key: _fabKey,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const _FetchSpecificResultDialog(),
                          );
                        },
                        label: const Text('Fetch Specific Exam'),
                        icon: const Icon(Icons.sync_alt),
                      ),
              ),
            ),
            if (_showTour)
              GuidedTourOverlay(
                steps: [
                  TourStep(
                    targetKey: _syncButtonKey,
                    title: 'Sync Academic Results',
                    description: 'Tap this icon to securely fetch and synchronize your official exam results from the DUCMC portal.',
                  ),
                  TourStep(
                    targetKey: _tabBarKey,
                    title: 'Personal vs Batch Directories',
                    description: 'Toggle between "My Dashboard" for your results and "Batch Directory" to view/search session results.',
                  ),
                  TourStep(
                    targetKey: _chartKey,
                    title: 'CGPA Prediction & Metrics',
                    description: 'Visualize your academic path with an interactive forecasting chart. Slide predictions to see how future GPA targets affect your final graduation grade!',
                  ),
                  TourStep(
                    targetKey: _fabKey,
                    title: 'Manual Exam Fetcher',
                    description: 'Use the floating manual query builder to search, select, and pull specific academic sessions/exams. Note: If you are a year-drop student, use this manual fetcher to pull your specific exam with your present session ID.',
                  ),
                ],
                onComplete: () {
                  setState(() => _showTour = false);
                  TourService.instance.completeScreenTour('results_tour');
                },
                onSkip: () {
                  setState(() => _showTour = false);
                  TourService.instance.completeScreenTour('results_tour');
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildOwnDashboard(BuildContext context, ResultState state, ColorScheme colors) {
    if (state.isOwnLoading && state.ownResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final results = state.ownResults;

    if (results.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ResultBloc>().add(SyncResultsRequested());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              key: _chartKey,
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
                  'Click the Sync icon in the top right or pull down to fetch your latest results.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Separate main vs improvement results
    final mainResults = results.where((r) => !r.isImprovement).toList()
      ..sort((a, b) {
        final semA = a.semester ?? _parseSemesterNumber(a.examName);
        final semB = b.semester ?? _parseSemesterNumber(b.examName);
        return semA.compareTo(semB);
      });
    final improvementResults = results.where((r) => r.isImprovement).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ResultBloc>().add(SyncResultsRequested());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. CGPA Prediction Chart Card (receives ALL results)
          CgpaPredictionChart(key: _chartKey, results: results),
          const SizedBox(height: 20),

        // CGPA Calculator Redirection Banner
        _buildCgpaCalculatorBanner(context, results),
        const SizedBox(height: 20),

        // 2. Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.format_list_bulleted, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              const Text(
                'Semester Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3. Main result cards — with linked improvement cards below
        ...mainResults.map((result) {
          final sem = result.semester ?? _parseSemesterNumber(result.examName);
          // Find any improvement results for this semester
          final linked = improvementResults.where((imp) {
            final impSem = imp.semester ?? _parseSemesterNumber(imp.examName);
            return impSem == sem;
          }).toList();
          return _buildResultCard(context, result, improvementResults: linked);
        }),

        // 4. Standalone improvement results (no paired main result for this semester)
        ...improvementResults.where((imp) {
          final impSem = imp.semester ?? _parseSemesterNumber(imp.examName);
          final hasPaired = mainResults.any((m) =>
            (m.semester ?? _parseSemesterNumber(m.examName)) == impSem
          );
          return !hasPaired;
        }).map((result) => _buildResultCard(context, result)),
      ],
    ),
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
                SnackBarUtils.showSuccess(context, '$type ID saved successfully');
              } catch (e) {
                SnackBarUtils.showError(context, e.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ExamResult result, {List<ExamResult> improvementResults = const []}) {
    final colors = Theme.of(context).colorScheme;
    final semNum = result.semester ?? _parseSemesterNumber(result.examName);
    final isImp = result.isImprovement;

    // Build a set of subject codes that have improvements (for marking in main card)
    final improvedCodes = <String>{};
    for (final imp in improvementResults) {
      for (final s in imp.subjects) {
        improvedCodes.add(s.code.toUpperCase());
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isImp
          ? Colors.orange.withValues(alpha: 0.04)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isImp
              ? Colors.orange.withValues(alpha: 0.35)
              : colors.outline.withValues(alpha: 0.1),
          width: isImp ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('${result.id}_${result.id == _expandedResultId}'),
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
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isImp ? '📈 Improvement — Sem $semNum' : 'Semester $semNum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isImp ? Colors.orange.shade700 : null,
                          ),
                        ),
                        if (improvementResults.isNotEmpty) ...[  
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              '↑ Improved',
                              style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.examName,
                      style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.download_rounded, color: colors.primary, size: 20),
                tooltip: 'Download PDF Report',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _generateAndSharePdf(context, result, improvementResults),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                tooltip: 'Remove Semester Result',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Remove Result'),
                      content: Text('Are you sure you want to remove the result of "${result.examName}" from your personal dashboard?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            context.read<ResultBloc>().add(DeleteResultRequested(resultId: result.id));
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (!isImp) ...[  
                  _buildScoreChip(context, 'GPA: ${result.gpa}', Colors.blue),
                  if (result.storedEffectiveGpa != null && result.storedEffectiveGpa! > (double.tryParse(result.gpa) ?? 0.0))
                    _buildScoreChip(context, 'Eff. GPA: ${result.storedEffectiveGpa!.toStringAsFixed(2)}', Colors.orange),
                  _buildScoreChip(context, 'CGPA: ${result.cgpa}', Colors.green),
                ] else ...[  
                  _buildScoreChip(
                    context,
                    'Calc. Subjects GPA: ${result.calculatedGpa?.toStringAsFixed(2) ?? "N/A"}',
                    Colors.orange,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'CGPA: Official pending',
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            // Main subjects
            ...result.subjects.map((subject) {
              // Check if this subject was improved
              final isImprovedSubject = improvedCodes.contains(subject.code.toUpperCase());
              // Find the improvement grade for this subject
              SubjectResult? impSubject;
              for (final imp in improvementResults) {
                try {
                  impSubject = imp.subjects.firstWhere(
                    (s) => s.code.toUpperCase() == subject.code.toUpperCase(),
                  );
                  break;
                } catch (_) {}
              }
              return _buildSubjectRow(context, subject,
                  isImproved: isImprovedSubject, improvedSubject: impSubject);
            }),

            // If this is an improvement result, show standalone improved subjects
            if (isImp && result.subjects.isNotEmpty) ...[  
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Calc. Subjects GPA: ${result.calculatedGpa?.toStringAsFixed(2) ?? "N/A"}',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            // Improvement subjects section below main subjects (only for main result cards)
            if (!isImp && improvementResults.isNotEmpty) ...[  
              const SizedBox(height: 12),
              ...improvementResults.map((imp) => _buildImprovementSection(context, imp)),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows the improvement exam subjects as a collapsible sub-section
  Widget _buildImprovementSection(BuildContext context, ExamResult imp) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.all(12).copyWith(top: 0),
          leading: const Icon(Icons.trending_up, color: Colors.orange, size: 18),
          title: Text(
            '📈 ${imp.examName}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          subtitle: Text(
            'Calc. GPA: ${imp.calculatedGpa?.toStringAsFixed(2) ?? "N/A"}  •  ${imp.subjects.length} subject(s) improved',
            style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.6)),
          ),
          children: [
            const Divider(height: 16),
            ...imp.subjects.map((s) => _buildSubjectRow(context, s, isImproved: true)),
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

  Widget _buildSubjectRow(
    BuildContext context,
    SubjectResult subject, {
    bool isImproved = false,
    SubjectResult? improvedSubject,
  }) {
    final colors = Theme.of(context).colorScheme;
    
    Color _gradeColor(String grade) {
      if (grade.startsWith('A')) return Colors.green;
      if (grade.startsWith('B')) return Colors.blue;
      if (grade.startsWith('C')) return Colors.orange;
      if (grade == 'F') return Colors.red;
      return Colors.grey;
    }

    final gradeColor = _gradeColor(subject.grade);
    final impGradeColor = improvedSubject != null ? _gradeColor(improvedSubject.grade) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subject.code,
                      style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (isImproved) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '↑ improved',
                          style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
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
              // If improved, show old → new grade
              if (improvedSubject != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject.grade,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: gradeColor.withValues(alpha: 0.5),
                        decoration: TextDecoration.lineThrough),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 10, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      improvedSubject.grade,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: impGradeColor),
                    ),
                  ],
                ),
                Text(
                  improvedSubject.point,
                  style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6)),
                ),
              ] else ...[
                Text(
                  subject.grade,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: gradeColor),
                ),
                Text(
                  subject.point,
                  style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  Future<void> _generateAndSharePdf(BuildContext context, ExamResult result, List<ExamResult> allResults) async {
    await ResultsPdfGenerator.generateAndShareSemesterPdf(context, currentProfile.value, result, allResults: allResults);
  }

  Future<void> _generateAndShareFullReport(BuildContext context, List<ExamResult> results) async {
    await ResultsPdfGenerator.generateAndShareConsolidatedPdf(context, currentProfile.value, results);
  }

  Widget _buildCgpaCalculatorBanner(BuildContext context, List<ExamResult> results) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CGPACalculatorScreen(initialResults: results),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calculate_rounded, color: colors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyze in CGPA Calculator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Simulate future grades using your official results',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                      final semester = exam['semester'] ?? '';
                      final isImprovement = exam['is_improvement'] == 'true';
                      final improvesSemester = exam['improves_semester'] ?? '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                examName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isImprovement)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  '↑ Improvement',
                                  style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
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
                              if (semester.isNotEmpty)
                                Text(
                                  'Semester: $semester',
                                  style: TextStyle(
                                    color: colors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (isImprovement && improvesSemester.isNotEmpty)
                                Text(
                                  'Improves Semester: $improvesSemester',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
                  SnackBarUtils.showSuccess(context, 'Exam ID deleted successfully');
                } catch (e) {
                  navigator.pop();
                  SnackBarUtils.showError(context, e.toString());
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
  int? _selectedSemester;
  bool _isImprovement = false;
  int? _improvesSemester;
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
      final semStr = widget.examToEdit!['semester'];
      _selectedSemester = semStr != null ? int.tryParse(semStr) : null;
      _isImprovement = widget.examToEdit!['is_improvement'] == 'true';
      final impSemStr = widget.examToEdit!['improves_semester'];
      _improvesSemester = impSemStr != null && impSemStr.isNotEmpty ? int.tryParse(impSemStr) : null;
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedSemester,
                    decoration: const InputDecoration(
                      labelText: 'Semester *',
                      border: OutlineInputBorder(),
                      helperText: 'Select Dhaka University Semester (1-8)',
                    ),
                    items: List.generate(8, (index) {
                      final sem = index + 1;
                      return DropdownMenuItem<int>(
                        value: sem,
                        child: Text('Semester $sem'),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        _selectedSemester = val;
                      });
                    },
                    validator: (val) => val == null ? 'Semester is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Improvement Exam Toggle ────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(8),
                      color: _isImprovement
                          ? Colors.orange.withValues(alpha: 0.06)
                          : Colors.transparent,
                    ),
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: const Text(
                        'Improvement / Backlog Exam',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Check if this exam is for improving previous semester grades',
                        style: TextStyle(fontSize: 11),
                      ),
                      secondary: Icon(
                        Icons.trending_up,
                        color: _isImprovement ? Colors.orange : Colors.grey,
                      ),
                      value: _isImprovement,
                      activeColor: Colors.orange,
                      onChanged: (val) => setState(() {
                        _isImprovement = val;
                        if (!val) _improvesSemester = null;
                      }),
                    ),
                  ),

                  // ── Which semester does this improve? ────────────────────
                  if (_isImprovement) ...[  
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _improvesSemester,
                      decoration: const InputDecoration(
                        labelText: 'Improves Semester *',
                        border: OutlineInputBorder(),
                        helperText: 'Which original semester does this improve?',
                        prefixIcon: Icon(Icons.arrow_upward, color: Colors.orange),
                      ),
                      items: List.generate(8, (index) {
                        final sem = index + 1;
                        return DropdownMenuItem<int>(
                          value: sem,
                          child: Text('Semester $sem'),
                        );
                      }),
                      onChanged: (val) => setState(() => _improvesSemester = val),
                    ),
                  ],
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
    final semester = _selectedSemester;

    if (name.isEmpty || id.isEmpty || session == null || session.isEmpty || semester == null) {
      SnackBarUtils.showError(context, 'Please fill all fields');
      return;
    }
    if (_isImprovement && _improvesSemester == null) {
      SnackBarUtils.showError(context, 'Please select which semester this improvement exam is for');
      return;
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);

    try {
      await ResultService.addExamId(
        name, id, session, semester,
        isImprovement: _isImprovement,
        improvesSemester: _improvesSemester,
      );
      navigator.pop(true); // Return true to indicate successful save
    } catch (e) {
      setState(() => _isSaving = false);
      SnackBarUtils.showError(context, e.toString());
    }
  }
}

class _FetchSpecificResultDialog extends StatefulWidget {
  const _FetchSpecificResultDialog();

  @override
  State<_FetchSpecificResultDialog> createState() => _FetchSpecificResultDialogState();
}

class _FetchSpecificResultDialogState extends State<_FetchSpecificResultDialog> {
  List<Map<String, String>> _sessions = [];
  Map<String, String>? _selectedSession;
  List<Map<String, String>> _exams = [];
  final Set<String> _selectedExamIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionsAndExams();
  }

  Future<void> _loadSessionsAndExams() async {
    final sessionsFuture = ResultService.fetchSessionsWithId();
    final examsFuture = ResultService.fetchAllExams();
    final results = await Future.wait([sessionsFuture, examsFuture]);
    
    if (mounted) {
      setState(() {
        _sessions = List<Map<String, String>>.from(results[0]);
        final allExams = List<Map<String, String>>.from(results[1]);
        
        final userSession = currentProfile.value.session;
        final userSessionMap = _sessions.firstWhere(
          (s) => s['session'] == userSession,
          orElse: () => {'session': userSession, 'sess_id': ''},
        );
        _selectedSession = userSessionMap;
        
        // Filter exams to user session OR improvement exams
        _exams = allExams.where((e) {
          final isImp = e['is_improvement'] == 'true';
          final matchSession = e['session'] == userSession;
          return matchSession || isImp;
        }).toList();
        
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userSession = currentProfile.value.session;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync_alt, color: colors.primary, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sync Specific Exam Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fetch results from the DUCMC portal by manually selecting exams. Improvement exams are marked with an orange badge.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Divider(height: 24),
                  
                  // Display current session
                  Row(
                    children: [
                      Text(
                        'Academic Session: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        userSession.isEmpty ? 'Not Configured' : userSession,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Exams (${_exams.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                      ),
                      if (_exams.isNotEmpty)
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedExamIds.addAll(_exams.map((e) => e['exam_id'] ?? ''));
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Select All', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedExamIds.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _exams.isEmpty
                        ? Center(
                            child: Text(
                              'No exams configured for this session.',
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _exams.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: colors.outline.withValues(alpha: 0.1),
                                ),
                                itemBuilder: (context, index) {
                                  final exam = _exams[index];
                                  final examId = exam['exam_id'] ?? '';
                                  final examName = exam['exam_name'] ?? '';
                                  final isChecked = _selectedExamIds.contains(examId);
                                  final isImp = exam['is_improvement'] == 'true';

                                  return CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            examName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colors.onSurface,
                                              fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isImp)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                                            ),
                                            child: const Text(
                                              'Improvement',
                                              style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'ID: $examId${isImp && exam['session'] != null ? "  •  Session: ${exam['session']}" : ""}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    value: isChecked,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedExamIds.add(examId);
                                        } else {
                                          _selectedExamIds.remove(examId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _selectedSession == null || _selectedExamIds.isEmpty
                            ? null
                            : () {
                                final selectedExams = _exams
                                    .where((e) => _selectedExamIds.contains(e['exam_id']))
                                    .toList();
                                
                                context.read<ResultBloc>().add(
                                  FetchSpecificResultsRequested(
                                    session: _selectedSession!['session'] ?? '',
                                    sessId: _selectedSession!['sess_id'] ?? '',
                                    exams: selectedExams,
                                  ),
                                );
                                Navigator.pop(context);
                              },
                        child: const Text('Sync Results'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
