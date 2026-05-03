import 'package:flutter/material.dart';
import '../models/gallery_state.dart';

class GalleryDetailScreen extends StatelessWidget {
  final GalleryItem item;
  const GalleryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const defaultColor = Colors.blue;

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
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Hero(
                tag: 'gallery_img_${item.id}',
                child: item.imagePath.isNotEmpty
                    ? Image.network(
                        item.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: defaultColor.withValues(alpha: 0.15),
                          child: const Center(child: Icon(Icons.photo_library, size: 80, color: Colors.grey)),
                        ),
                      )
                    : Container(
                        color: defaultColor.withValues(alpha: 0.15),
                        child: const Center(child: Icon(Icons.photo_library, size: 80, color: Colors.grey)),
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
                      color: defaultColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: defaultColor.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library, color: defaultColor, size: 14),
                        SizedBox(width: 6),
                        Text('Gallery', style: TextStyle(color: defaultColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(item.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 8),
                  if (item.createdByName.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text('Added by ${item.createdByName}',
                            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Divider ──
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
          ),

          // ── Description ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: item.description.isNotEmpty
                  ? Text(item.description,
                      style: TextStyle(fontSize: 16, height: 1.7, color: colors.onSurface.withValues(alpha: 0.8)))
                  : Text('No description available.',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: colors.onSurface.withValues(alpha: 0.4))),
            ),
          ),
        ],
      ),
    );
  }
}
