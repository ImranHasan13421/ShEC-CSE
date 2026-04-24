import 'package:flutter/material.dart';

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
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
            child: Text('Select Semester', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  // Hardcoded manual mapping for session blocks
  // Will be replaced by Admin API/Database fetch in the future
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
    return []; // Fallback empty list
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
  final Color color;

  const PdfsScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Placeholder data to show how it will look once the admin uploads files
    final List<Map<String, String>> dummyPdfs = [
      {'name': 'Semester Final Question.pdf', 'size': '1.2 MB', 'date': 'Added 2 months ago'},
      {'name': 'Semester Final All Course Notes .pdf', 'size': '36.6 MB', 'date': 'Added 3 months ago'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
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
                    'These are placeholder files. The real question papers will be dynamically fetched here once the Admin Panel is live.',
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...dummyPdfs.map((pdf) => Card(
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
              title: Text(pdf['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Text(pdf['size']!, style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('• ${pdf['date']}', style: TextStyle(color: colors.onSurface.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.download, color: color),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading file...')),
                  );
                },
              ),
            ),
          )),
        ],
      ),
    );
  }
}