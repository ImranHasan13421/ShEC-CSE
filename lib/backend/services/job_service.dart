import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/jobs/models/job_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';

class JobService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchJobs({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.jobsRecommended)) return;
    
    final isAdmin = currentProfile.value.role != UserRole.student;
    
    var query = _client.from('jobs').select();
    if (!isAdmin) {
      query = query.eq('is_approved', true).eq('is_visible', true);
    }
    
    final response = await query.order('created_at', ascending: false);

    final List<JobItem> recommended = [];
    final List<JobItem> recent = [];

    for (var row in response) {
      final job = JobItem.fromJson(row);
      if (job.category == 'recommended') {
        recommended.add(job);
      } else {
        recent.add(job);
      }
    }

    recommendedJobsState.value = recommended;
    recentJobsState.value = recent;
    CacheService.markFresh(CacheKeys.jobsRecommended);
  }

  static Future<void> addJobToDB(JobItem job, String category) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final data = job.copyWith(category: category).toJson();
    data['is_approved'] = isSuperUser;
    data['is_visible'] = true;
    data['created_by_name'] = profile.name;
    
    final response = await _client
        .from('jobs')
        .insert(data)
        .select()
        .single();

    final newJob = JobItem.fromJson(response);
    if (newJob.category == 'recommended') {
      recommendedJobsState.value = List.from(recommendedJobsState.value)..insert(0, newJob);
    } else {
      recentJobsState.value = List.from(recentJobsState.value)..insert(0, newJob);
    }
    CacheService.invalidate(CacheKeys.jobsRecommended);
  }

  static Future<void> updateJobInDB(JobItem job, String category) async {
    final data = job.copyWith(category: category).toJson();
    data.remove('is_approved'); // Don't overwrite existing status on normal edit
    
    await _client
        .from('jobs')
        .update(data)
        .eq('id', job.id);
        
    CacheService.invalidate(CacheKeys.jobsRecommended);
    fetchJobs(forceRefresh: true);
  }

  static Future<void> approveJob(String id) async {
    await _client.from('jobs').update({'is_approved': true}).eq('id', id);
    CacheService.invalidate(CacheKeys.jobsRecommended);
    fetchJobs(forceRefresh: true);
  }

  static Future<void> toggleJobVisibility(String id, bool isVisible) async {
    await _client.from('jobs').update({'is_visible': isVisible}).eq('id', id);
    CacheService.invalidate(CacheKeys.jobsRecommended);
    fetchJobs(forceRefresh: true);
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
    CacheService.invalidate(CacheKeys.jobsRecommended);
  }

  // Real-time subscription
  static void subscribeToJobs() {
    _client
      .channel('public:jobs')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'jobs',
        callback: (payload) => fetchJobs(forceRefresh: true),
      )
      .subscribe();
  }
}
