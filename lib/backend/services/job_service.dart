import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/jobs/models/job_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';
import 'notification_service.dart';

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
    final List<JobItem> jobs = response.map((row) => JobItem.fromJson(row)).toList();

    jobsState.value = jobs;
    CacheService.markFresh(CacheKeys.jobsRecommended);
  }

  static Future<void> addJobToDB(JobItem job) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final data = job.toJson();
    data['is_approved'] = isSuperUser;
    data['is_visible'] = true;
    data['created_by_name'] = profile.name;
    
    final response = await _client
        .from('jobs')
        .insert(data)
        .select()
        .single();

    final newJob = JobItem.fromJson(response);
    jobsState.value = List.from(jobsState.value)..insert(0, newJob);
    CacheService.invalidate(CacheKeys.jobsRecommended);
  }

  static Future<void> updateJobInDB(JobItem job) async {
    final data = job.toJson();
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

  static Future<void> deleteJobFromDB(String id) async {
    await _client
        .from('jobs')
        .delete()
        .eq('id', id);

    jobsState.value = List.from(jobsState.value)
        ..removeWhere((job) => job.id == id);
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
        callback: (payload) {
          if (payload.eventType == PostgresChangeEvent.insert) {
            final data = payload.newRecord;
            if (data['created_by_name'] != currentProfile.value.name) {
              NotificationService.incrementUnread('jobs');
              NotificationService.showNotification(
                id: 2,
                title: 'New Job Opening: ${data['title']}',
                body: '${data['company']} is hiring! Check it out in the Job Board.',
              );
            }
          }
          fetchJobs(forceRefresh: true);
        },
      )
      .subscribe();
  }
}
