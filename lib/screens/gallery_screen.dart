import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Added 'image' paths to the mock data
    final List<Map<String, dynamic>> galleryItems = [
      {'title': 'Microprocessor Lab', 'subtitle': 'Top Level Equipments', 'image': 'assets/gallery/1.jpg', 'icon': Icons.memory, 'color': Colors.blue},
      {'title': 'Programming Lab', 'subtitle': 'Coding sessions', 'image': 'assets/gallery/2.jpg', 'icon': Icons.code, 'color': Colors.teal},
      {'title': 'Application Lab', 'subtitle': 'App development workshop', 'image': 'assets/gallery/3.jpg', 'icon': Icons.app_shortcut, 'color': Colors.indigo},
      {'title': 'Network Lab', 'subtitle': 'Configuring devices', 'image': 'assets/gallery/4.jpg', 'icon': Icons.router, 'color': Colors.orange},
      {'title': 'Annual Hackathon', 'subtitle': 'National coding competition', 'image': 'assets/gallery/7.jpg', 'icon': Icons.emoji_events, 'color': Colors.redAccent},
      {'title': 'Algorithm Workshop', 'subtitle': 'Advanced data structures', 'image': 'assets/gallery/6.jpg', 'icon': Icons.schema, 'color': Colors.purple},
      {'title': 'Project Exhibition', 'subtitle': 'Final year showcase', 'image': 'assets/gallery/5.jpg', 'icon': Icons.lightbulb, 'color': Colors.amber},
      {'title': 'Basic Programming Workshop', 'subtitle': 'Curious learners', 'image': 'assets/gallery/8.jpg', 'icon': Icons.smart_toy, 'color': Colors.cyan},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: galleryItems.length,
        itemBuilder: (context, index) {
          final item = galleryItems[index];
          return _buildGalleryCard(
            context: context,
            title: item['title'],
            subtitle: item['subtitle'],
            imagePath: item['image'], // Passing the new image path
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
    required String imagePath,
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Future: Open full-screen image viewer
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Half: Image with Icon Fallback
            Expanded(
              flex: 3,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover, // Ensures the image fills the space beautifully
                errorBuilder: (context, error, stackTrace) {
                  // If the image file isn't found in assets, it smoothly falls back to your original icon design!
                  return Container(
                    color: iconColor.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 48,
                        color: iconColor.withOpacity(0.8),
                      ),
                    ),
                  );
                },
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