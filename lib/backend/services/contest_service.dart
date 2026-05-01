import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/contests/models/contest_state.dart';
import '../../features/profile/models/profile_state.dart';

class ContestService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchContestsAndCourses() async {
    final isAdmin = currentProfile.value.role != UserRole.student;

    var query = _client.from('contests').select();
    if (!isAdmin) {
      query = query.eq('is_approved', true);
    }
    
    final response = await query.order('created_at', ascending: false);

    final List<ContestItem> contests = [];
    final List<ContestItem> courses = [];

    for (var row in response) {
      final item = ContestItem.fromJson(row);
      if (item.isCourse) {
        courses.add(item);
      } else {
        contests.add(item);
      }
    }

    contestState.value = contests;
    courseState.value = courses;
  }

  static Future<void> addContestToDB(ContestItem item) async {
    final isSuperUser = currentProfile.value.role == UserRole.superUser;
    
    final data = item.toJson();
    data['is_approved'] = isSuperUser;
    
    final response = await _client
        .from('contests')
        .insert(data)
        .select()
        .single();

    final newItem = ContestItem.fromJson(response);
    if (newItem.isCourse) {
      courseState.value = List.from(courseState.value)..insert(0, newItem);
    } else {
      contestState.value = List.from(contestState.value)..insert(0, newItem);
    }
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

    if (item.isCourse) {
      courseState.value = List.from(courseState.value)..removeWhere((i) => i.id == item.id);
    } else {
      contestState.value = List.from(contestState.value)..removeWhere((i) => i.id == item.id);
    }
  }
}
