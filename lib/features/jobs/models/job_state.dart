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
    };
  }
}

// Global Notifiers for Jobs
final ValueNotifier<List<JobItem>> recommendedJobsState = ValueNotifier([]);
final ValueNotifier<List<JobItem>> recentJobsState = ValueNotifier([]);

// Supabase DB functions for Jobs
Future<void> fetchJobs() async {
  try {
    final response = await Supabase.instance.client
        .from('jobs')
        .select()
        .order('created_at', ascending: false);

    final List<JobItem> recommended = [];
    final List<JobItem> recent = [];

    for (var row in response) {
      final job = JobItem.fromJson(row);
      if (row['category'] == 'recommended') {
        recommended.add(job);
      } else if (row['category'] == 'recent') {
        recent.add(job);
      }
    }

    recommendedJobsState.value = recommended;
    recentJobsState.value = recent;
  } catch (e) {
    debugPrint('Error fetching jobs: $e');
  }
}

Future<void> addJobToDB(JobItem job, String category) async {
  try {
    final data = job.toJson(category);
    // Remove id to let Supabase generate it, or you can insert it if using uuid package
    final response = await Supabase.instance.client
        .from('jobs')
        .insert(data)
        .select()
        .single();
    
    final newJob = JobItem.fromJson(response);
    if (category == 'recommended') {
      recommendedJobsState.value = List.from(recommendedJobsState.value)..insert(0, newJob);
    } else {
      recentJobsState.value = List.from(recentJobsState.value)..insert(0, newJob);
    }
  } catch (e) {
    debugPrint('Error adding job: $e');
  }
}

Future<void> updateJobInDB(JobItem job, String category) async {
  try {
    final data = job.toJson(category);
    await Supabase.instance.client
        .from('jobs')
        .update(data)
        .eq('id', job.id);
        
    // Local state is usually updated in the screen before calling this, 
    // or we can refresh here.
  } catch (e) {
    debugPrint('Error updating job: $e');
  }
}

Future<void> deleteJobFromDB(String id, String category) async {
  try {
    await Supabase.instance.client
        .from('jobs')
        .delete()
        .eq('id', id);
        
    if (category == 'recommended') {
      recommendedJobsState.value = List.from(recommendedJobsState.value)
        ..removeWhere((job) => job.id == id);
    } else {
      recentJobsState.value = List.from(recentJobsState.value)
        ..removeWhere((job) => job.id == id);
    }
  } catch (e) {
    debugPrint('Error deleting job: $e');
  }
}
