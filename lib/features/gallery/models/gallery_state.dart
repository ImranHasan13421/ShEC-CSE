import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? json['subtitle'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subtitle': description,
      'image_path': imagePath,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }
}

// Global Notifier for Gallery Items
final ValueNotifier<List<GalleryItem>> galleryState = ValueNotifier([]);
