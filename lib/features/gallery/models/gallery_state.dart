import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;

  GalleryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
  });
}

// Global Notifier for Gallery Items
final ValueNotifier<List<GalleryItem>> galleryState = ValueNotifier([
  GalleryItem(id: 'g1', title: 'Microprocessor Lab', subtitle: 'Top Level Equipments', imagePath: 'assets/gallery/1.jpg', icon: Icons.memory, color: Colors.blue),
  GalleryItem(id: 'g2', title: 'Programming Lab', subtitle: 'Coding sessions', imagePath: 'assets/gallery/2.jpg', icon: Icons.code, color: Colors.teal),
  GalleryItem(id: 'g3', title: 'Application Lab', subtitle: 'App development workshop', imagePath: 'assets/gallery/3.jpg', icon: Icons.app_shortcut, color: Colors.indigo),
  GalleryItem(id: 'g4', title: 'Network Lab', subtitle: 'Configuring devices', imagePath: 'assets/gallery/4.jpg', icon: Icons.router, color: Colors.orange),
  GalleryItem(id: 'g5', title: 'Project Exhibition', subtitle: 'Final year showcase', imagePath: 'assets/gallery/5.jpg', icon: Icons.lightbulb, color: Colors.amber),
  GalleryItem(id: 'g6', title: 'Algorithm Workshop', subtitle: 'Advanced data structures', imagePath: 'assets/gallery/6.jpg', icon: Icons.schema, color: Colors.purple),
  GalleryItem(id: 'g7', title: 'Annual Hackathon', subtitle: 'National coding competition', imagePath: 'assets/gallery/7.jpg', icon: Icons.emoji_events, color: Colors.redAccent),
  GalleryItem(id: 'g8', title: 'Basic Programming Workshop', subtitle: 'Curious learners', imagePath: 'assets/gallery/8.jpg', icon: Icons.smart_toy, color: Colors.cyan),
]);
