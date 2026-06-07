import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Required for making the link clickable
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/services/tour_service.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/guided_tour_overlay.dart';
import 'package:ShEC_CSE/features/results/models/result_state.dart';
import 'package:ShEC_CSE/backend/services/result_service.dart';
import 'package:ShEC_CSE/core/utils/subject_information.dart';

// --- Data Models ---
class CourseData {
  String name;
  double credit;
  double grade;

  CourseData({this.name = '', this.credit = 3.0, this.grade = 4.0});
}

class SemesterData {
  String name;
  List<CourseData> courses;

  SemesterData({required this.name, required this.courses});

  double get semesterGPA {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var course in courses) {
      totalPoints += (course.credit * course.grade);
      totalCredits += course.credit;
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  double get semesterCredits {
    return courses.fold(0, (sum, course) => sum + course.credit);
  }
}

class CGPACalculatorScreen extends StatefulWidget {
  final List<ExamResult>? initialResults;
  const CGPACalculatorScreen({super.key, this.initialResults});

  @override
  State<CGPACalculatorScreen> createState() => _CGPACalculatorScreenState();
}

class _CGPACalculatorScreenState extends State<CGPACalculatorScreen> {
  final GlobalKey _cgpaHeaderKey = GlobalKey();
  final GlobalKey _resultButtonKey = GlobalKey();
  final GlobalKey _addSemesterKey = GlobalKey();
  bool _showTour = false;

  // Initialize with one semester and one course
  List<SemesterData> semesters = [
    SemesterData(name: 'Semester 1', courses: [CourseData(name: 'Course 1')])
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialResults != null) {
      _populateFromResults(widget.initialResults!);
    }
    TourService.instance.hasCompletedScreenTour('cgpa_calculator').then((completed) {
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

  void _populateFromResults(List<ExamResult> results) {
    if (results.isEmpty) return;

    // Sort results by semester ascending
    final sortedResults = List<ExamResult>.from(results);
    sortedResults.sort((a, b) {
      if (a.semester != null && b.semester != null) {
        return a.semester!.compareTo(b.semester!);
      }
      return a.examName.compareTo(b.examName);
    });

    final List<SemesterData> loadedSemesters = [];
    for (var result in sortedResults) {
      final List<CourseData> courses = [];
      for (var subject in result.subjects) {
        final courseName = subject.name.isEmpty 
            ? subject.code 
            : '${subject.code}: ${subject.name}';
        
        courses.add(CourseData(
          name: courseName,
          credit: subject.credits,
          grade: SubjectInformation.parseGradeToPoint(subject.grade),
        ));
      }
      
      if (courses.isEmpty) {
        courses.add(CourseData(name: 'Course 1'));
      }
      
      loadedSemesters.add(SemesterData(
        name: result.examName,
        courses: courses,
      ));
    }

    setState(() {
      semesters = loadedSemesters;
    });
  }

  Future<void> _importStoredResults() async {
    try {
      final results = await ResultService.loadResultsFromDB();
      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved results found. Please sync your results first on the Academic Results page.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Import Results'),
          content: Text(
            'This will overwrite all current entries in the calculator with your official ${results.length} semester results. Do you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        _populateFromResults(results);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully imported results!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error importing results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import results: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Standard UGC Grading Scale for Dropdowns
  final Map<String, double> gradeScale = {
    'A+ (80-100%)': 4.00,
    'A  (75-79%)': 3.75,
    'A- (70-74%)': 3.50,
    'B+ (65-69%)': 3.25,
    'B  (60-64%)': 3.00,
    'B- (55-59%)': 2.75,
    'C+ (50-54%)': 2.50,
    'C  (45-49%)': 2.25,
    'D  (40-44%)': 2.00,
    'F  (0-39%)': 0.00,
  };

  // --- Calculation Logic ---
  double get overallCGPA {
    double totalPoints = 0;
    double totalCredits = 0;
    for (var sem in semesters) {
      for (var course in sem.courses) {
        totalPoints += (course.credit * course.grade);
        totalCredits += course.credit;
      }
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  double get overallCredits {
    double total = 0;
    for (var sem in semesters) {
      total += sem.semesterCredits;
    }
    return total;
  }

  void _addSemester() {
    setState(() {
      semesters.add(SemesterData(
          name: 'Semester ${semesters.length + 1}',
          courses: [CourseData(name: 'Course 1')]));
    });
  }

  void _addCourse(int semesterIndex) {
    setState(() {
      semesters[semesterIndex].courses.add(CourseData(
          name: 'Course ${semesters[semesterIndex].courses.length + 1}'));
    });
  }

  void _removeCourse(int semIndex, int courseIndex) {
    setState(() {
      semesters[semIndex].courses.removeAt(courseIndex);
    });
  }

  void _removeSemester(int semIndex) {
    setState(() {
      semesters.removeAt(semIndex);
    });
  }

  // Helper method to open the Result portal in the external browser
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Widget _buildOverallDashboardCard(BuildContext context, ColorScheme colors) {
    return Card(
      key: _cgpaHeaderKey,
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'Total Credits',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  overallCredits.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(width: 1, height: 40, color: Colors.white30),
            Column(
              children: [
                Text(
                  'Cumulative GPA',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  overallCGPA.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportResultsCard(BuildContext context, ColorScheme colors) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: _importStoredResults,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.download_rounded, color: colors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Saved Results',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Load your official synced grades from DB',
                      style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 13),
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
                child: const Icon(Icons.sync_alt, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AmbientTimeBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              title: const Text('CGPA Calculator'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Overall Result Dashboard Card
                _buildOverallDashboardCard(context, colors),
                const SizedBox(height: 16),

                // 2. Check Your Result Card
                _buildResultButton(context),
                const SizedBox(height: 16),

                // 3. Import Stored Results Card
                _buildImportResultsCard(context, colors),
                const SizedBox(height: 24),

                // 4. Semesters List Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Semesters Breakdown',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. List of Semesters
                ...List.generate(semesters.length, (semIndex) {
                  return _buildSemesterCard(context, semIndex, colors);
                }),
                
                // Add padding at the bottom to avoid floating action button overlap
                const SizedBox(height: 80),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              key: _addSemesterKey,
              onPressed: _addSemester,
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Semester'),
            ),
          ),
        ),
        if (_showTour)
          GuidedTourOverlay(
            steps: [
              TourStep(
                targetKey: _cgpaHeaderKey,
                title: 'Cumulative GPA Dashboard',
                description: 'Your real-time total credits and cumulative grade point average (CGPA) will automatically compute and update here.',
              ),
              TourStep(
                targetKey: _resultButtonKey,
                title: 'Official Result Portal',
                description: 'Tap here to instantly open the DU affiliated colleges student portal in your external browser to view your official semester grades.',
              ),
              TourStep(
                targetKey: _addSemesterKey,
                title: 'Add Semester',
                description: 'Tapping this button appends a new semester block below to input more grades and customize course configurations.',
              ),
            ],
            onComplete: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('cgpa_calculator');
            },
            onSkip: () {
              setState(() => _showTour = false);
              TourService.instance.completeScreenTour('cgpa_calculator');
            },
          ),
      ],
    );
  }

  // --- The Custom Result Button Widget ---
  Widget _buildResultButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: _resultButtonKey,
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _launchURL('https://ducmc.du.ac.bd/result.php'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              // Image/Icon Container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: colors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/branding/ducmc.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check Your Result',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DU Affiliated Colleges Portal',
                      style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 13),
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
                child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterCard(BuildContext context, int semIndex, ColorScheme colors) {
    final semester = semesters[semIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semester Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: semester.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    onChanged: (val) => semester.name = val,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('GPA: ${semester.semesterGPA.toStringAsFixed(2)}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                ),
                if (semesters.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.error),
                    onPressed: () => _removeSemester(semIndex),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                  )
              ],
            ),
            const Divider(height: 24),

            // Header Row for Courses
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Course (Opt)', style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.6)))),
                  Expanded(flex: 2, child: Text('Credits', style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.6)))),
                  Expanded(flex: 3, child: Text('Grade', style: TextStyle(fontSize: 12, color: colors.onSurface.withOpacity(0.6)))),
                  const SizedBox(width: 32), // Space for delete icon
                ],
              ),
            ),

            // Courses List
            ...List.generate(semester.courses.length, (courseIndex) {
              final course = semester.courses[courseIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    // Course Name
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: course.name,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          course.name = val;
                          final cleanCode = val.toUpperCase().replaceAll(' ', '-').trim();
                          // Match subject code patterns like CSE-1101 or CSE 1101 or ECO-4201
                          final regExp = RegExp(r'^[A-Z]{2,4}[- ]?\d{4}$', caseSensitive: false);
                          if (regExp.hasMatch(cleanCode)) {
                            final matchedCredits = SubjectInformation.getCredits(cleanCode);
                            setState(() {
                              course.credit = matchedCredits;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Typable Credits Field
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey('${semIndex}_${courseIndex}_${course.credit}'),
                        initialValue: course.credit.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          setState(() {
                            // Safely convert text to double. If blank or invalid, default to 0.0
                            course.credit = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),
                    // Grade Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<double>(
                        value: course.grade,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: gradeScale.entries.map((entry) {
                          return DropdownMenuItem(value: entry.value, child: Text(entry.key.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => course.grade = val);
                        },
                      ),
                    ),
                    // Delete Course Button
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        icon: Icon(Icons.close, size: 20, color: colors.onSurface.withValues(alpha: 0.4)),
                        onPressed: semester.courses.length > 1 ? () => _removeCourse(semIndex, courseIndex) : null,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Add Course Button
            TextButton.icon(
              onPressed: () => _addCourse(semIndex),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Course'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ],
        ),
      ),
    );
  }
}