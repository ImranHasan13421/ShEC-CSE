import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color color;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.color,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });
  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? json['subtitle'] as String? ?? '',
      imagePath: json['image_path'] as String,
      icon: IconData(json['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['icon_color'] as int),
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subtitle': description, // For backward compatibility if column exists
      'image_path': imagePath,
      'icon_code_point': icon.codePoint,
      'icon_color': color.value,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }
}

// Global Notifier for Gallery Items
final ValueNotifier<List<GalleryItem>> galleryState = ValueNotifier([]);
