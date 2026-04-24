import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Required for making the link clickable

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
  const CGPACalculatorScreen({super.key});

  @override
  State<CGPACalculatorScreen> createState() => _CGPACalculatorScreenState();
}

class _CGPACalculatorScreenState extends State<CGPACalculatorScreen> {
  // Initialize with one semester and one course
  List<SemesterData> semesters = [
    SemesterData(name: 'Semester 1', courses: [CourseData(name: 'Course 1')])
  ];

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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
      ),
      body: Column(
        children: [
          // Sticky Header for Overall Result
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Total Credits', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(overallCredits.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                Column(
                  children: [
                    Text('Cumulative GPA', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(overallCGPA.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),

          // --- NEW: Check Result Button Banner ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildResultButton(context),
          ),

          // List of Semesters
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: semesters.length,
              itemBuilder: (context, semIndex) {
                return _buildSemesterCard(context, semIndex, colors);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSemester,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Semester'),
      ),
    );
  }

  // --- The Custom Result Button Widget ---
  Widget _buildResultButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withOpacity(0.3), width: 1.5),
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
                    BoxShadow(color: colors.primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
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
                      style: TextStyle(color: colors.onSurface.withOpacity(0.7), fontSize: 13),
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
        side: BorderSide(color: colors.outline.withOpacity(0.2), width: 1),
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
                  decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
                        onChanged: (val) => course.name = val,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Typable Credits Field
                    Expanded(
                      flex: 2,
                      child: TextFormField(
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
                        icon: Icon(Icons.close, size: 20, color: colors.onSurface.withOpacity(0.4)),
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