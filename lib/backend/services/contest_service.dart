import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/contests/models/contest_state.dart';
import '../../features/profile/models/profile_state.dart';

class ContestService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchContestsAndCourses() async {
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
  }

  static Future<void> toggleContestVisibility(String id, bool isVisible) async {
    await _client.from('contests').update({'is_visible': isVisible}).eq('id', id);
    fetchContestsAndCourses();
  }

  static Future<void> updateContestInDB(ContestItem item) async {
    final data = item.toJson();
    data.remove('is_approved'); // Don't overwrite existing status on normal edit
    
    await _client
        .from('contests')
        .update(data)
        .eq('id', item.id);
  }

  static Future<void> approveContest(String id) async {
    await _client.from('contests').update({'is_approved': true}).eq('id', id);
    fetchContestsAndCourses();
  }

  static Future<void> deleteContestFromDB(ContestItem item) async {
    await _client
        .from('contests')
        .delete()
        .eq('id', item.id);

    contestState.value = List.from(contestState.value)..removeWhere((i) => i.id == item.id);
  }
}
