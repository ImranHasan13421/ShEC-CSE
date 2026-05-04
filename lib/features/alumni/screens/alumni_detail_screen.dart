import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alumni_state.dart';

class AlumniDetailScreen extends StatelessWidget {
  final AlumniItem alumni;
  const AlumniDetailScreen({super.key, required this.alumni});

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
            expandedHeight: 300,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: colors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Full Image Background
                  alumni.imagePath.isNotEmpty
                      ? Image.network(
                          alumni.imagePath,
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
                                alumni.name[0].toUpperCase(),
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
                              alumni.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),

                  // 2. Gradient Overlay
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

                  // 3. Name and Designation
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alumni.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${alumni.currentPosition} at ${alumni.company}'.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
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
                    _sectionTitle(colors, 'Professional Info'),
                    const SizedBox(height: 16),
                    _infoTile(colors, Icons.badge_outlined, 'Current Position', alumni.currentPosition),
                    _infoTile(colors, Icons.business_outlined, 'Company', alumni.company),
                    _infoTile(colors, Icons.psychology_outlined, 'Expertise', alumni.areasOfExpertise.join(', ')),

                    const SizedBox(height: 32),
                    _sectionTitle(colors, 'Academic Background'),
                    const SizedBox(height: 16),
                    _infoTile(colors, Icons.school_outlined, 'Batch', 'Batch ${alumni.batch}'),
                    _infoTile(colors, Icons.date_range_outlined, 'Session', alumni.session),
                    _infoTile(colors, Icons.history_edu_outlined, 'Graduation Year', alumni.passingYear),

                    const SizedBox(height: 32),
                    _sectionTitle(colors, 'Contact Channels'),
                    const SizedBox(height: 16),
                    if (alumni.email.isNotEmpty)
                      _contactCard(
                        context,
                        colors,
                        Icons.email_outlined,
                        'Email Address',
                        alumni.email,
                        () => _launch('mailto:${alumni.email}'),
                      ),
                    if (alumni.phone.isNotEmpty)
                      _contactCard(
                        context,
                        colors,
                        Icons.phone_outlined,
                        'Phone Number',
                        alumni.phone,
                        () => _launch('tel:${alumni.phone}'),
                      ),
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
    if (value.isEmpty) return const SizedBox.shrink();
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
