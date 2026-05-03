import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/contests/models/contest_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';

class ContestService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchContestsAndCourses({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.contests)) return;

    final isAdmin = currentProfile.value.role != UserRole.student;

    var query = _client.from('contests').select();
    if (!isAdmin) {
      query = query.eq('is_approved', true).eq('is_visible', true);
    }
    // Only fetch non-courses as user wants to remove courses feature
    query = query.eq('is_course', false);
    
    final response = await query.order('created_at', ascending: false);

    final List<ContestItem> fetchedContests = [];
    for (var row in response) {
      final item = ContestItem.fromJson(row);
      fetchedContests.add(item);
    }

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
    data['is_course'] = false; // Always false now
    
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
    
    // Reset approval if edited by non-superuser
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
        callback: (payload) => fetchContestsAndCourses(forceRefresh: true),
      )
      .subscribe();
  }
}

