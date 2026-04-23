import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Mock data for the gallery items
    final List<Map<String, dynamic>> galleryItems = [
      {'title': 'Microprocessor Lab', 'subtitle': 'Students working on projects', 'icon': Icons.memory, 'color': Colors.blue},
      {'title': 'Programming Lab', 'subtitle': 'Coding sessions', 'icon': Icons.code, 'color': Colors.teal},
      {'title': 'Application Lab', 'subtitle': 'App development workshop', 'icon': Icons.app_shortcut, 'color': Colors.indigo},
      {'title': 'Network Lab', 'subtitle': 'Configuring devices', 'icon': Icons.router, 'color': Colors.orange},
      {'title': 'Annual Hackathon', 'subtitle': '24-hour coding challenge', 'icon': Icons.emoji_events, 'color': Colors.redAccent},
      {'title': 'Algorithm Workshop', 'subtitle': 'Advanced data structures', 'icon': Icons.schema, 'color': Colors.purple},
      {'title': 'Project Exhibition', 'subtitle': 'Final year showcase', 'icon': Icons.lightbulb, 'color': Colors.amber},
      {'title': 'Robotics Competition', 'subtitle': 'Challenge winners', 'icon': Icons.smart_toy, 'color': Colors.cyan},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two items per row
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85, // Makes the cards slightly taller than they are wide
        ),
        itemCount: galleryItems.length,
        itemBuilder: (context, index) {
          final item = galleryItems[index];
          return _buildGalleryCard(
            context: context,
            title: item['title'],
            subtitle: item['subtitle'],
            icon: item['icon'],
            iconColor: item['color'],
          );
        },
      ),
    );
  }

  Widget _buildGalleryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias, // Ensures the top container respects the card's border radius
      child: InkWell(
        onTap: () {
          // Future: Open full-screen image viewer
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Half: Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                color: iconColor.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    icon,
                    size: 48,
                    color: iconColor.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            // Bottom Half: Text Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}