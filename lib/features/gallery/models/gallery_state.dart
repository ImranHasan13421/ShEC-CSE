import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;
  final bool isApproved;

  GalleryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
    this.isApproved = false,
  });
  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imagePath: json['image_path'] as String,
      icon: IconData(json['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['icon_color'] as int),
      isApproved: json['is_approved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'image_path': imagePath,
      'icon_code_point': icon.codePoint,
      'icon_color': color.value,
      'is_approved': isApproved,
    };
  }
}

// Global Notifier for Gallery Items
final ValueNotifier<List<GalleryItem>> galleryState = ValueNotifier([]);
