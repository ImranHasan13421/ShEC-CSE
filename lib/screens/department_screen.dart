import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Make sure to add this import

class DepartmentScreen extends StatelessWidget {
  const DepartmentScreen({super.key});

  // Helper method to open URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSE Department'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(context, 'About CSE Department',
              'The CSE department offers a four-year undergraduate program in Computer Science & Engineering. Our courses are designed to provide students with a perfect balance of theoretical knowledge and practical skills, preparing them for the highly competitive workplace.\n\nBesides the undergraduate program, the department successfully runs Post-Graduate Diploma in Information Technology, Certificate in Computer Application, and CISCO Certified Network Program.'
          ),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Course Information', [
            _InfoRow(Icons.timer, 'Duration:', '4 Years (8 Semesters)'),
            _InfoRow(Icons.account_balance, 'Certification:', 'University of Dhaka'),
            _InfoRow(Icons.event_seat, 'Seats:', '50 per year'),
            _InfoRow(Icons.library_books, 'Total Credits:', '160.50'),
            _InfoRow(Icons.menu_book_rounded, 'Syllabus:', 'Official Syllabus', url: 'https://drive.google.com/file/d/1qto0ELdWgFXq05M-lHLNnnICP0rlPYQa/view'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Contact Information', [
            _InfoRow(Icons.mail, 'Email:', 'shec.ac.bd@gmail.com'),
            _InfoRow(Icons.phone, 'Phone:', '+8801907485801'),
            _InfoRow(Icons.location_on, 'Address:', 'House # 10, Road # 01, Chand Uddan, Mohammadpur, Dhaka'),
            _InfoRow(Icons.link, 'Website:', 'ShEC CSE Department', url: 'https://shec.ac.bd/cse-department.html'),
          ]),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String body) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(body, style: TextStyle(color: colors.onSurface.withOpacity(0.8), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<_InfoRow> rows) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              // Wrap the row in a GestureDetector to make it clickable
              child: GestureDetector(
                onTap: row.url != null ? () => _launchURL(row.url!) : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(row.icon, size: 20, color: colors.primary),
                    const SizedBox(width: 12),
                    Text(row.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.value,
                        style: TextStyle(
                          // If it has a URL, make it look like a hyperlink!
                          color: row.url != null ? colors.primary : colors.onSurface.withOpacity(0.7),
                          decoration: row.url != null ? TextDecoration.underline : TextDecoration.none,
                          fontWeight: row.url != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final String? url;

  _InfoRow(this.icon, this.label, this.value, {this.url});
}