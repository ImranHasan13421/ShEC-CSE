import 'package:flutter/material.dart';

// --- Data Model for Jobs ---
class JobItem {
  final String id;
  final String company;
  final String role;
  final String location;
  final String salary;
  final String deadline;
  final String jobType;
  bool isStarred;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;
  final String description;
  final String applyUrl;

  JobItem({
    required this.id,
    required this.company,
    required this.role,
    required this.location,
    required this.salary,
    required this.deadline,
    required this.jobType,
    this.isStarred = false,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
    this.description = '',
    this.applyUrl = '',
  });

  factory JobItem.fromJson(Map<String, dynamic> json) {
    return JobItem(
      id: json['id'] as String,
      company: json['company'] as String,
      role: json['role'] as String,
      location: json['location'] as String,
      salary: json['salary'] as String,
      deadline: json['deadline'] as String,
      jobType: json['job_type'] as String,
      isStarred: json['is_starred'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      applyUrl: json['apply_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'role': role,
      'location': location,
      'salary': salary,
      'deadline': deadline,
      'job_type': jobType,
      'is_starred': isStarred,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
      'description': description,
      'apply_url': applyUrl,
    };
  }

  JobItem copyWith({
    String? id,
    String? company,
    String? role,
    String? location,
    String? salary,
    String? deadline,
    String? jobType,
    bool? isStarred,
    bool? isApproved,
    bool? isVisible,
    String? createdByName,
    String? description,
    String? applyUrl,
  }) {
    return JobItem(
      id: id ?? this.id,
      company: company ?? this.company,
      role: role ?? this.role,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      deadline: deadline ?? this.deadline,
      jobType: jobType ?? this.jobType,
      isStarred: isStarred ?? this.isStarred,
      isApproved: isApproved ?? this.isApproved,
      isVisible: isVisible ?? this.isVisible,
      createdByName: createdByName ?? this.createdByName,
      description: description ?? this.description,
      applyUrl: applyUrl ?? this.applyUrl,
    );
  }
}

// Global Notifier for Jobs
final ValueNotifier<List<JobItem>> jobsState = ValueNotifier([]);
