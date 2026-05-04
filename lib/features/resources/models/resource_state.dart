import 'package:flutter/material.dart';

class ResourceItem {
  final String id;
  final String name;
  final String date;
  final String session;
  final String semester;
  final String fileUrl;
  final String? uploadedBy;

  ResourceItem({
    required this.id,
    required this.name,
    required this.date,
    required this.session,
    required this.semester,
    required this.fileUrl,
    this.uploadedBy,
  });

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    return ResourceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      session: json['session'] as String,
      semester: json['semester'] ?? '1st Semester',
      fileUrl: json['file_url'] ?? '',
      uploadedBy: json['uploaded_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'session': session,
      'semester': semester,
      'file_url': fileUrl,
      'uploaded_by': uploadedBy,
    };
  }
}

// Global Notifier for Resources
final ValueNotifier<List<ResourceItem>> resourceState = ValueNotifier([]);
