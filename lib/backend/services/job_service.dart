import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/jobs/models/job_state.dart';

class JobService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchJobs() async {
    final response = await _client
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
  }

  static Future<void> addJobToDB(JobItem job, String category) async {
    final data = job.toJson(category);
    final response = await _client
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
  }

  static Future<void> updateJobInDB(JobItem job, String category) async {
    final data = job.toJson(category);
    await _client
        .from('jobs')
        .update(data)
        .eq('id', job.id);
  }

  static Future<void> deleteJobFromDB(String id, String category) async {
    await _client
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
  }
}
