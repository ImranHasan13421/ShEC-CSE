import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/models/profile_state.dart';
import '../models/result_state.dart';
import '../models/batch_member_result.dart';
import '../../../backend/services/result_service.dart';
import '../presentation/bloc/result_bloc.dart';
import '../presentation/bloc/result_event.dart';
import '../presentation/bloc/result_state.dart';

class BatchResultsTab extends StatefulWidget {
  const BatchResultsTab({super.key});

  @override
  State<BatchResultsTab> createState() => _BatchResultsTabState();
}

class _BatchResultsTabState extends State<BatchResultsTab> {
  // Filter States
  String _selectedSession = '';
  String _studentSearchQuery = '';
  String _selectedSemester = 'All';
  String _subjectSearchQuery = '';

  List<String> _availableSessions = [];

  @override
  void initState() {
    super.initState();
    _selectedSession = currentProfile.value.session;
    _loadAvailableSessions();
    _fetchBatchResults();
  }

  Future<void> _loadAvailableSessions() async {
    final sessions = await ResultService.fetchSessions();
    if (mounted) {
      setState(() {
        _availableSessions = sessions;
        // Ensure current session is added if not present
        if (_selectedSession.isNotEmpty && !_availableSessions.contains(_selectedSession)) {
          _availableSessions.add(_selectedSession);
        }
        _availableSessions.sort((a, b) => b.compareTo(a)); // Descending order
      });
    }
  }

  void _fetchBatchResults() {
    if (_selectedSession.isNotEmpty) {
      context.read<ResultBloc>().add(LoadBatchResultsRequested(session: _selectedSession));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profile = currentProfile.value;
    final isCommittee = profile.role == UserRole.committeeMember || profile.role == UserRole.superUser;

    return BlocBuilder<ResultBloc, ResultState>(
      builder: (context, state) {
        if (state.isBatchLoading && state.batchResults.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.batchResults.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchBatchResults,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // If batchResults is loaded, or if loading completed
        if (state.batchResults.isNotEmpty || (!state.isBatchLoading && _selectedSession.isNotEmpty)) {
          // Extract unique exams/semesters dynamically for filter dropdown
          final List<String> availableSemesters = ['All'];
          for (var r in state.batchResults) {
            if (!availableSemesters.contains(r.result.examName)) {
              availableSemesters.add(r.result.examName);
            }
          }

          // Local multi-dimensional filtering
          final filteredResults = state.batchResults.where((item) {
            // 1. Session check
            if (item.profile.session != state.selectedSession) return false;

            // 2. Student Search (Name, Roll, University ID, Reg)
            final studentMatch = _studentSearchQuery.isEmpty ||
                item.profile.name.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
                item.profile.classRoll.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
                item.profile.universityId.toLowerCase().contains(_studentSearchQuery.toLowerCase()) ||
                item.profile.duRegNo.toLowerCase().contains(_studentSearchQuery.toLowerCase());
            if (!studentMatch) return false;

            // 3. Semester Filter
            final semesterMatch = _selectedSemester == 'All' || item.result.examName == _selectedSemester;
            if (!semesterMatch) return false;

            // 4. Subject Search
            final subjectMatch = _subjectSearchQuery.isEmpty ||
                item.result.subjects.any((sub) =>
                    sub.code.toLowerCase().contains(_subjectSearchQuery.toLowerCase()) ||
                    sub.name.toLowerCase().contains(_subjectSearchQuery.toLowerCase()));
            
            return subjectMatch;
          }).toList();

          // Group filtered results by student
          final Map<String, List<BatchMemberResult>> groupedResults = {};
          for (var item in filteredResults) {
            final studentId = item.profile.id;
            groupedResults.putIfAbsent(studentId, () => []).add(item);
          }

          final studentIds = groupedResults.keys.toList();
          // Sort student list by class roll (ascending) or name if rolls are equal/empty
          studentIds.sort((idA, idB) {
            final pA = groupedResults[idA]!.first.profile;
            final pB = groupedResults[idB]!.first.profile;
            
            final cleanRollA = pA.classRoll.replaceAll(RegExp(r'\D'), '');
            final cleanRollB = pB.classRoll.replaceAll(RegExp(r'\D'), '');
            final rollA = int.tryParse(cleanRollA) ?? 999999;
            final rollB = int.tryParse(cleanRollB) ?? 999999;
            if (rollA != rollB) {
              return rollA.compareTo(rollB);
            }
            return pA.name.compareTo(pB.name);
          });

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Filtration Panel
                  _buildFiltrationPanel(colors, isCommittee, availableSemesters),

                  // 2. Dynamic Performance Insights Panel
                  if (_selectedSemester != 'All' && _subjectSearchQuery.isNotEmpty)
                    _buildGradeDistributionAnalysisCard(filteredResults, colors),

                  // 3. Directory List
                  Expanded(
                    child: studentIds.isEmpty
                        ? _buildEmptyState(colors)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: studentIds.length,
                            itemBuilder: (context, index) {
                              final studentId = studentIds[index];
                              final studentItems = groupedResults[studentId]!;
                              return _buildStudentAccordion(studentItems, state.batchResults, colors);
                            },
                          ),
                  ),
                ],
              ),
              if (state.isBatchLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        }

        return const Center(child: Text('Load results to view directory.'));
      },
    );
  }

  Widget _buildFiltrationPanel(ColorScheme colors, bool isCommittee, List<String> availableSemesters) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.12)),
      ),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row 1: Session Selector (If Admin) & Student Search
            Row(
              children: [
                if (isCommittee) ...[
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedSession,
                      decoration: const InputDecoration(
                        labelText: 'Session',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _availableSessions.map((session) {
                        return DropdownMenuItem(
                          value: session,
                          child: Text(session, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSession = val;
                            _selectedSemester = 'All'; // Reset filters
                          });
                          _fetchBatchResults();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Student',
                      hintText: 'Name or Roll No',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setState(() => _studentSearchQuery = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Semester & Subject Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedSemester,
                    decoration: const InputDecoration(
                      labelText: 'Semester Filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: availableSemesters.map((sem) {
                      return DropdownMenuItem(value: sem, child: Text(sem, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSemester = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter Subject',
                      hintText: 'Code or Name',
                      prefixIcon: Icon(Icons.book, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setState(() => _subjectSearchQuery = val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Premium feature: Grade Breakdown distribution
  Widget _buildGradeDistributionAnalysisCard(List<BatchMemberResult> filteredList, ColorScheme colors) {
    // Count grades for the filtered subject
    final Map<String, int> gradeCounts = {
      'A+': 0, 'A': 0, 'A-': 0, 'B+': 0, 'B': 0, 'B-': 0, 'C+': 0, 'C': 0, 'D': 0, 'F': 0
    };

    int totalStudentsEvaluated = 0;
    double totalPoints = 0.0;

    for (var r in filteredList) {
      final targetSub = r.result.subjects.firstWhere(
        (sub) =>
            sub.code.toLowerCase().contains(_subjectSearchQuery.toLowerCase()) ||
            sub.name.toLowerCase().contains(_subjectSearchQuery.toLowerCase()),
        orElse: () => SubjectResult(code: '', name: '', grade: '', point: ''),
      );

      if (targetSub.grade.isNotEmpty) {
        final cleanGrade = targetSub.grade.trim().toUpperCase();
        if (gradeCounts.containsKey(cleanGrade)) {
          gradeCounts[cleanGrade] = gradeCounts[cleanGrade]! + 1;
        }
        final pointsVal = double.tryParse(targetSub.point) ?? 0.0;
        if (pointsVal > 0.0 || cleanGrade == 'F') {
          totalPoints += pointsVal;
          totalStudentsEvaluated++;
        }
      }
    }

    if (totalStudentsEvaluated == 0) return const SizedBox.shrink();

    final averageSubjectGpa = totalPoints / totalStudentsEvaluated;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 16),
      elevation: 0,
      color: colors.primaryContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Subject Analytics: "$_subjectSearchQuery"',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Avg GPA: ${averageSubjectGpa.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Grade metrics bars
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: gradeCounts.entries.map((entry) {
                  final grade = entry.key;
                  final count = entry.value;
                  if (count == 0) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          grade,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        Text(
                          '$count ${count == 1 ? "student" : "students"}',
                          style: TextStyle(fontSize: 9, color: colors.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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

  String _getOrdinalSuffix(int number) {
    if (number == 1) return 'st';
    if (number == 2) return 'nd';
    if (number == 3) return 'rd';
    return 'th';
  }

  double _getLatestStudentCgpa(String studentId, List<BatchMemberResult> allResults) {
    double latestCgpa = 0.0;
    int maxSemester = 0;
    for (var r in allResults) {
      if (r.profile.id == studentId) {
        final sem = r.result.semester ?? _parseSemesterNumber(r.result.examName);
        if (sem > maxSemester) {
          maxSemester = sem;
          final cgpaVal = double.tryParse(r.result.cgpa) ?? 0.0;
          if (cgpaVal > 0.0) {
            latestCgpa = cgpaVal;
          }
        }
      }
    }
    
    // Fallback: average GPAs if latestCgpa is 0
    if (latestCgpa == 0.0) {
      double sumGpa = 0.0;
      int count = 0;
      for (var r in allResults) {
        if (r.profile.id == studentId) {
          final gpaVal = double.tryParse(r.result.gpa) ?? 0.0;
          if (gpaVal > 0.0) {
            sumGpa += gpaVal;
            count++;
          }
        }
      }
      if (count > 0) {
        latestCgpa = sumGpa / count;
      }
    }
    
    return latestCgpa;
  }

  Widget _buildStudentAccordion(
    List<BatchMemberResult> studentItems,
    List<BatchMemberResult> allResults,
    ColorScheme colors,
  ) {
    final profile = studentItems.first.profile;
    final latestCgpa = _getLatestStudentCgpa(profile.id, allResults);

    // Group semesters by academic year: 1=1st, 2=2nd, 3=3rd, 4=4th Year
    final Map<int, List<BatchMemberResult>> yearsMap = {};
    for (var item in studentItems) {
      final sem = item.result.semester ?? _parseSemesterNumber(item.result.examName);
      int year = 1;
      if (sem == 1 || sem == 2) {
        year = 1;
      } else if (sem == 3 || sem == 4) {
        year = 2;
      } else if (sem == 5 || sem == 6) {
        year = 3;
      } else if (sem == 7 || sem == 8) {
        year = 4;
      }
      yearsMap.putIfAbsent(year, () => []).add(item);
    }
    
    final sortedYears = yearsMap.keys.toList()..sort();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      color: colors.surface,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            backgroundImage: profile.imagePath != null
                ? NetworkImage(profile.imagePath!)
                : null,
            child: profile.imagePath == null
                ? Text(
                    (profile.name.isNotEmpty ? profile.name[0] : '?').toUpperCase(),
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  )
                : null,
          ),
          title: Text(
            profile.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roll: ${profile.classRoll.isNotEmpty ? profile.classRoll : "N/A"} | ID: ${profile.universityId.isNotEmpty ? profile.universityId : "N/A"}',
                  style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'CGPA: ${latestCgpa > 0.0 ? latestCgpa.toStringAsFixed(2) : "N/A"}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            ...sortedYears.map((yearNum) {
              final yearItems = yearsMap[yearNum]!;
              // Sort semesters inside yearItems by semester index
              yearItems.sort((a, b) {
                final semA = a.result.semester ?? _parseSemesterNumber(a.result.examName);
                final semB = b.result.semester ?? _parseSemesterNumber(b.result.examName);
                return semA.compareTo(semB);
              });

              final yearLabel = '$yearNum${_getOrdinalSuffix(yearNum)} Year';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.05)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        yearLabel,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primary),
                      ),
                      leading: Icon(Icons.school_outlined, size: 18, color: colors.primary),
                      children: yearItems.map((item) => _buildSemesterSubTile(item, colors)).toList(),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterSubTile(BatchMemberResult item, ColorScheme colors) {
    // Locate filtered subject if any search query is set
    SubjectResult? searchedSubject;
    if (_subjectSearchQuery.isNotEmpty) {
      for (var s in item.result.subjects) {
        if (s.code.toLowerCase().contains(_subjectSearchQuery.toLowerCase()) ||
            s.name.toLowerCase().contains(_subjectSearchQuery.toLowerCase())) {
          searchedSubject = s;
          break;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6).copyWith(bottom: 10),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.all(12).copyWith(top: 0),
          title: Text(
            item.result.examName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'GPA: ${item.result.gpa}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CGPA: ${item.result.cgpa}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                if (searchedSubject != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${searchedSubject.code}: ${searchedSubject.grade}',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registration No: ${item.profile.duRegNo.isNotEmpty ? item.profile.duRegNo : "N/A"}',
                  style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...item.result.subjects.map((sub) => _buildSubjectMiniRow(sub, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectMiniRow(SubjectResult subject, ColorScheme colors) {
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.code,
                  style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  subject.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                subject.grade,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: gradeColor),
              ),
              Text(
                subject.point,
                style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 48, color: colors.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            const Text(
              'No batch members found.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search query or toggling filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
