import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/contests/models/contest_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';
import 'notification_service.dart';

class ContestService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchContestsAndCourses({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.contests)) return;

    final isAdmin = currentProfile.value.role != UserRole.student;

    var query = _client.from('contests').select();
    if (!isAdmin) {
      query = query.eq('is_approved', true).eq('is_visible', true);
    }
    
    final response = await query.order('created_at', ascending: false);
    final List<ContestItem> fetchedContests = response.map((row) => ContestItem.fromJson(row)).toList();

    contestState.value = fetchedContests;
    courseState.value = [];
    CacheService.markFresh(CacheKeys.contests);
  }

  static Future<void> addContestToDB(ContestItem item) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final data = item.toJson();
    data['is_approved'] = isSuperUser;
    data['is_visible'] = true;
    data['created_by_name'] = profile.name;
    
    final response = await _client
        .from('contests')
        .insert(data)
        .select()
        .single();

    final newItem = ContestItem.fromJson(response);
    contestState.value = List.from(contestState.value)..insert(0, newItem);
    CacheService.invalidate(CacheKeys.contests);
  }

  static Future<void> toggleContestVisibility(String id, bool isVisible) async {
    await _client.from('contests').update({'is_visible': isVisible}).eq('id', id);
    CacheService.invalidate(CacheKeys.contests);
    fetchContestsAndCourses(forceRefresh: true);
  }

  static Future<void> updateContestInDB(ContestItem item) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final data = item.toJson();
    
    if (!isSuperUser) {
      data['is_approved'] = false;
    }
    
    await _client
        .from('contests')
        .update(data)
        .eq('id', item.id);
        
    CacheService.invalidate(CacheKeys.contests);
    fetchContestsAndCourses(forceRefresh: true);
  }

  static Future<void> approveContest(String id) async {
    await _client.from('contests').update({'is_approved': true}).eq('id', id);
    CacheService.invalidate(CacheKeys.contests);
    fetchContestsAndCourses(forceRefresh: true);
  }

  static Future<void> deleteContestFromDB(ContestItem item) async {
    await _client
        .from('contests')
        .delete()
        .eq('id', item.id);

    contestState.value = List.from(contestState.value)..removeWhere((i) => i.id == item.id);
    CacheService.invalidate(CacheKeys.contests);
  }

  // Real-time subscription
  static void subscribeToContests() {
    _client
      .channel('public:contests')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'contests',
        callback: (payload) {
          if (payload.eventType == PostgresChangeEvent.insert) {
            final data = payload.newRecord;
            if (data['created_by_name'] != currentProfile.value.name) {
              NotificationService.incrementUnread('contests');
              NotificationService.showNotification(
                id: 3,
                title: 'New Contest: ${data['title']}',
                body: 'Level: ${data['level']}. Register now!',
              );
            }
          }
          fetchContestsAndCourses(forceRefresh: true);
        },
      )
      .subscribe();
  }
}
