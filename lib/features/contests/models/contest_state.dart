import 'package:flutter/material.dart';

class ContestItem {
  final String id;
  final String title;
  final String platform;
  final String level;
  final String date;
  final String url;
  final String description;
  final Color iconColor;
  final bool isCourse;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  ContestItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.level,
    required this.date,
    required this.url,
    this.description = '',
    required this.iconColor,
    this.isCourse = false,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  factory ContestItem.fromJson(Map<String, dynamic> json) {
    return ContestItem(
      id: json['id'] as String,
      title: json['title'] as String,
      platform: json['platform'] as String,
      level: json['level'] as String,
      date: json['date'] as String,
      url: json['url'] as String,
      description: json['description'] as String? ?? '',
      iconColor: Color(json['icon_color'] as int),
      isCourse: json['is_course'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'platform': platform,
      'level': level,
      'date': date,
      'url': url,
      'description': description,
      'icon_color': iconColor.value,
      'is_course': isCourse,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }

  ContestItem copyWith({
    String? id,
    String? title,
    String? platform,
    String? level,
    String? date,
    String? url,
    String? description,
    Color? iconColor,
    bool? isCourse,
    bool? isApproved,
    bool? isVisible,
    String? createdByName,
  }) {
    return ContestItem(
      id: id ?? this.id,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      level: level ?? this.level,
      date: date ?? this.date,
      url: url ?? this.url,
      description: description ?? this.description,
      iconColor: iconColor ?? this.iconColor,
      isCourse: isCourse ?? this.isCourse,
      isApproved: isApproved ?? this.isApproved,
      isVisible: isVisible ?? this.isVisible,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}

final ValueNotifier<List<ContestItem>> contestState = ValueNotifier([]);
final ValueNotifier<List<ContestItem>> courseState = ValueNotifier([]);
