import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      icon: IconData(json['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
      isStarred: json['is_starred'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
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
      'icon_code_point': icon.codePoint,
      'icon_color': iconColor.value,
      'is_starred': isStarred,
      'is_approved': isApproved,
    };
  }
}

// Global Notifiers for Jobs
final ValueNotifier<List<JobItem>> recommendedJobsState = ValueNotifier([]);
final ValueNotifier<List<JobItem>> recentJobsState = ValueNotifier([]);

