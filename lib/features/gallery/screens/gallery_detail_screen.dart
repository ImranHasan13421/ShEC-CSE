import 'package:flutter/material.dart';
import '../models/gallery_state.dart';

class GalleryDetailScreen extends StatelessWidget {
  final GalleryItem item;
  const GalleryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Hero(
            tag: 'gallery_img_${item.id}',
            child: Image.network(
              item.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.6, 1.0],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(item.subtitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
