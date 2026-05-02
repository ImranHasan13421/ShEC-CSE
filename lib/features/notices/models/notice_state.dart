import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/icon_mapper.dart';

class NoticeItem {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? imagePath;
  final List<String> tags;
  final Color tagColor;
  final String date;
  final bool isPinned;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  NoticeItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.description = '',
    this.imagePath,
    required this.tags,
    required this.tagColor,
    required this.date,
    this.isPinned = false,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  NoticeItem copyWith({
    String? id,
    IconData? icon,
    Color? iconColor,
    String? title,
    String? description,
    String? imagePath,
    List<String>? tags,
    Color? tagColor,
    String? date,
    bool? isPinned,
    bool? isApproved,
    bool? isVisible,
    String? createdByName,
  }) {
    return NoticeItem(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      tagColor: tagColor ?? this.tagColor,
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
      icon: IconMapper.getIcon(json['icon_key'] as String?, defaultIcon: Icons.notifications),
      iconColor: Color(json['icon_color'] as int),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      tagColor: Color(json['tag_color'] as int),
      date: json['date'] as String,
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
      'tag_color': tagColor.value,
      'date': date,
      'is_pinned': isPinned,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
      'icon_key': IconMapper.getIconKey(icon),
      'icon_color': iconColor.value,
    };
  }
}

// Global Notifiers for Notices
final ValueNotifier<List<NoticeItem>> clubNoticesState = ValueNotifier([]);
final ValueNotifier<List<NoticeItem>> deptNoticesState = ValueNotifier([]);
