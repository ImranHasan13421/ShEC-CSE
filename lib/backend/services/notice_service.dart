import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notices/models/notice_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';

class NoticeService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchNotices({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.notices)) return;

    final isAdmin = currentProfile.value.role != UserRole.student;
    
    var query = _client.from('notices').select();
    if (!isAdmin) {
      query = query.eq('is_approved', true).eq('is_visible', true);
    }
    
    final response = await query.order('created_at', ascending: false);

    final List<NoticeItem> clubNotices = [];
    final List<NoticeItem> deptNotices = [];

    for (var row in response) {
      final notice = NoticeItem.fromJson(row);
      if (row['category'] == 'club') {
        clubNotices.add(notice);
      } else if (row['category'] == 'department') {
        deptNotices.add(notice);
      }
    }

    clubNoticesState.value = clubNotices;
    deptNoticesState.value = deptNotices;
    CacheService.markFresh(CacheKeys.notices);
  }

  static Future<void> addNoticeToDB(NoticeItem notice, String category) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final data = notice.toJson(category);
    data['is_approved'] = isSuperUser; // Superusers auto-approve, committee needs approval
    data['is_visible'] = true;
    data['created_by_name'] = profile.name;
    
    final response = await _client
        .from('notices')
        .insert(data)
        .select()
        .single();

    final newNotice = NoticeItem.fromJson(response);
    if (category == 'club') {
      clubNoticesState.value = List.from(clubNoticesState.value)..insert(0, newNotice);
    } else {
      deptNoticesState.value = List.from(deptNoticesState.value)..insert(0, newNotice);
    }
    CacheService.invalidate(CacheKeys.notices);
  }

  static Future<void> updateNoticeInDB(NoticeItem notice, String category) async {
    final data = notice.toJson(category);
    data.remove('is_approved'); // Don't overwrite existing status on normal edit
    
    await _client
        .from('notices')
        .update(data)
        .eq('id', notice.id);
    
    CacheService.invalidate(CacheKeys.notices);
    fetchNotices(forceRefresh: true);
  }

  static Future<void> approveNotice(String id) async {
    await _client.from('notices').update({'is_approved': true}).eq('id', id);
    CacheService.invalidate(CacheKeys.notices);
    fetchNotices(forceRefresh: true);
  }

  static Future<void> toggleNoticeVisibility(String id, bool isVisible) async {
    await _client.from('notices').update({'is_visible': isVisible}).eq('id', id);
    CacheService.invalidate(CacheKeys.notices);
    fetchNotices(forceRefresh: true);
  }

  static Future<void> deleteNoticeFromDB(String id, String category) async {
    await _client
        .from('notices')
        .delete()
        .eq('id', id);

    if (category == 'club') {
      clubNoticesState.value = List.from(clubNoticesState.value)
        ..removeWhere((notice) => notice.id == id);
    } else {
      deptNoticesState.value = List.from(deptNoticesState.value)
        ..removeWhere((notice) => notice.id == id);
    }
    CacheService.invalidate(CacheKeys.notices);
  }

  static Future<String?> uploadImage(File file) async {
    try {
      final fileName = 'notice_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      await _client.storage.from('notice_images').upload(fileName, file);
      return _client.storage.from('notice_images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading notice image: $e');
      return null;
    }
  }
}
