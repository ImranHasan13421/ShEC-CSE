import 'package:flutter/material.dart';
import '../models/gallery_state.dart';

class GalleryDetailScreen extends StatelessWidget {
  final GalleryItem item;
  const GalleryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Animated Collapsible Image AppBar ──
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: colors.surface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Hero(
                tag: 'gallery_img_${item.id}',
                child: Image.network(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: item.color.withOpacity(0.2),
                    child: Center(
                      child: Icon(item.icon, size: 80, color: item.color.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Title ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: item.color.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, color: item.color, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Gallery',
                          style: TextStyle(
                            color: item.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Created by
                  if (item.createdByName.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: colors.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          'Added by ${item.createdByName}',
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Divider ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(),
            ),
          ),

          // ── Description ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: item.description.isNotEmpty
                  ? Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: colors.onSurface.withOpacity(0.8),
                      ),
                    )
                  : Text(
                      'No description available.',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: colors.onSurface.withOpacity(0.4),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
