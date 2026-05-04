import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/teacher_state.dart';

class TeacherDetailScreen extends StatelessWidget {
  final TeacherContact teacher;
  const TeacherDetailScreen({super.key, required this.teacher});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: colors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Full Image Background
                  teacher.imagePath.isNotEmpty
                      ? Image.network(
                          teacher.imagePath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [colors.primary, colors.secondary],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                teacher.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [colors.primary, colors.secondary],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              teacher.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),

                  // 2. Gradient Overlay for Text Readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // 3. Name and Designation at the Bottom
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teacher.designation.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Back Button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: Colors.black26),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(colors, 'Contact Details'),
                    const SizedBox(height: 16),
                    _contactCard(
                      context,
                      colors,
                      Icons.email_outlined,
                      'Email Address',
                      teacher.email,
                      () => _launch('mailto:${teacher.email}'),
                    ),
                    const SizedBox(height: 12),
                    _contactCard(
                      context,
                      colors,
                      Icons.phone_outlined,
                      'Phone Number',
                      teacher.phone,
                      () => _launch('tel:${teacher.phone}'),
                    ),
                    
                    const SizedBox(height: 32),
                    _sectionTitle(colors, 'Academic Info'),
                    const SizedBox(height: 16),
                    _infoTile(colors, Icons.school_outlined, 'Department', 'Computer Science & Engineering'),
                    _infoTile(colors, Icons.work_outline, 'Designation', teacher.designation),
                    if (teacher.officeRoom.isNotEmpty)
                      _infoTile(colors, Icons.location_on_outlined, 'Office', teacher.officeRoom),
                    if (teacher.joinYear.isNotEmpty)
                      _infoTile(colors, Icons.calendar_today_outlined, 'Joined', teacher.joinYear),
                    
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ColorScheme colors, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _contactCard(BuildContext context, ColorScheme colors, IconData icon, String label, String value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 20, color: colors.primary.withOpacity(0.7)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 1)),
                  );
                },
                tooltip: 'Copy',
              ),
              Icon(Icons.open_in_new, size: 18, color: colors.onSurfaceVariant.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(ColorScheme colors, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: colors.onSurfaceVariant)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
