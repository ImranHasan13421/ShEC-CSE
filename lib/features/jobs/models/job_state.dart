import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/icon_mapper.dart';

// --- Data Model for Jobs ---
class JobItem {
  final String id;
  final String company;
  final String role;
  final String location;
  final String salary;
  final String deadline;
  final String jobType;
  final Color typeColor;
  final Color iconColor;
  final IconData icon;
  bool isStarred;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;
  final String description;
  final List<String> requirements;
  final List<String> responsibilities;
  final String applyUrl;

  JobItem({
    required this.id,
    required this.company,
    required this.role,
    required this.location,
    required this.salary,
    required this.deadline,
    required this.jobType,
    required this.typeColor,
    required this.iconColor,
    required this.icon,
    this.isStarred = false,
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
    this.description = '',
    this.requirements = const [],
    this.responsibilities = const [],
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
      typeColor: Color(json['type_color'] as int),
      iconColor: Color(json['icon_color'] as int),
      icon: IconMapper.getIcon(json['icon_key'] as String?, defaultIcon: Icons.work),
      isStarred: json['is_starred'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requirements: (json['requirements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      responsibilities: (json['responsibilities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      applyUrl: json['apply_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson(String category) {
    return {
      'category': category,
      'company': company,
      'role': role,
      'location': location,
      'salary': salary,
      'deadline': deadline,
      'job_type': jobType,
      'type_color': typeColor.value,
      'icon_key': IconMapper.getIconKey(icon),
      'icon_color': iconColor.value,
      'is_starred': isStarred,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
      'description': description,
      'requirements': requirements,
      'responsibilities': responsibilities,
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
    Color? typeColor,
    Color? iconColor,
    IconData? icon,
    bool? isStarred,
    bool? isApproved,
    bool? isVisible,
    String? createdByName,
    String? description,
    List<String>? requirements,
    List<String>? responsibilities,
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
      typeColor: typeColor ?? this.typeColor,
      iconColor: iconColor ?? this.iconColor,
      icon: icon ?? this.icon,
      isStarred: isStarred ?? this.isStarred,
      isApproved: isApproved ?? this.isApproved,
      isVisible: isVisible ?? this.isVisible,
      createdByName: createdByName ?? this.createdByName,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      responsibilities: responsibilities ?? this.responsibilities,
      applyUrl: applyUrl ?? this.applyUrl,
    );
  }
}

// Global Notifiers for Jobs
final ValueNotifier<List<JobItem>> recommendedJobsState = ValueNotifier([]);
final ValueNotifier<List<JobItem>> recentJobsState = ValueNotifier([]);
