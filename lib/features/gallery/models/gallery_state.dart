import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final Color color;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.color = Colors.blue,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    // icon_color column stores int (ARGB)
    Color itemColor = Colors.blue;
    final rawColor = json['icon_color'];
    if (rawColor != null) {
      itemColor = Color(rawColor as int);
    }

    return GalleryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      // DB has 'description' column; 'subtitle' was the old column name
      description: json['description'] as String? ?? json['subtitle'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      color: itemColor,
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      // Also write subtitle for backward-compat with any old rows
      'subtitle': description,
      'image_path': imagePath,
      // icon_code_point and icon_color are kept for DB schema
      'icon_code_point': Icons.photo.codePoint,
      'icon_color': color.toARGB32(),
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }
}

// Expose a simple icon for UI fallback
extension GalleryItemIcon on GalleryItem {
  IconData get icon => Icons.photo_library;
}

// Global Notifier for Gallery Items
final ValueNotifier<List<GalleryItem>> galleryState = ValueNotifier([]);
