import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoticeItem {
  final String id;
  final String title;
  final String description;
  final String? imagePath;
  final List<String> tags;
  final String date;
  final bool isPinned;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  NoticeItem({
    required this.id,
    required this.title,
    this.description = '',
    this.imagePath,
    required this.tags,
    required this.date,
    this.isPinned = false,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  NoticeItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imagePath,
    List<String>? tags,
    String? date,
    bool? isPinned,
    bool? isApproved,
    bool? isVisible,
    String? createdByName,
  }) {
    return NoticeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      isPinned: isPinned ?? this.isPinned,
      isApproved: isApproved ?? this.isApproved,
      isVisible: isVisible ?? this.isVisible,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      date: json['date'] as String? ?? 'Just now',
      isPinned: json['is_pinned'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson(String category) {
    return {
      'category': category,
      'title': title,
      'description': description,
      'image_path': imagePath ?? '',
      'tags': tags,
      'date': date,
      'is_pinned': isPinned,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }
}

// Global Notifiers for Notices
final ValueNotifier<List<NoticeItem>> clubNoticesState = ValueNotifier([]);
final ValueNotifier<List<NoticeItem>> deptNoticesState = ValueNotifier([]);
