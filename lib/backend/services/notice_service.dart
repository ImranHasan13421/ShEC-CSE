import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notices/models/notice_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';
import 'package:ShEC_CSE/backend/services/notification_service.dart';

class NoticeService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchNotices({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.notices)) return;

    final profile = currentProfile.value;
    final isAdmin = profile.role != UserRole.student;

    var query = _client.from('notices').select();
    
    if (!isAdmin) {
      query = query.eq('is_approved', true).eq('is_visible', true);
    }
    
    final response = await query.order('created_at', ascending: false);

    final List<NoticeItem> clubNotices = [];
    final List<NoticeItem> deptNotices = [];

    for (var row in response) {
      final item = NoticeItem.fromJson(row);
      if (row['category'] == 'club') {
        clubNotices.add(item);
      } else {
        deptNotices.add(item);
      }
    }

    clubNoticesState.value = clubNotices;
    deptNoticesState.value = deptNotices;
    CacheService.markFresh(CacheKeys.notices);
  }

  static Future<String?> uploadImage(File file) async {
    try {
      final fileName = 'notice_${DateTime.now().millisecondsSinceEpoch}.webp';
      await _client.storage.from('notice_images').upload(fileName, file);
      return _client.storage.from('notice_images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Notice image upload error: $e');
      return null;
    }
  }

  static Future<void> addNoticeToDB(NoticeItem notice, String category) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final Map<String, dynamic> data = {
      'category': category,
      'title': notice.title,
      'description': notice.description,
      'image_path': notice.imagePath ?? '',
      'tags': notice.tags,
      'is_pinned': notice.isPinned,
      'is_approved': isSuperUser, 
      'is_visible': true,
      'created_by_name': profile.name,
    };
    
    final now = DateTime.now();
    data['date'] = '${now.day}/${now.month}/${now.year}';

    try {
      final response = await _client
          .from('notices')
          .insert(data)
          .select()
          .single();

      final newItem = NoticeItem.fromJson(response);
      if (category == 'club') {
        clubNoticesState.value = List.from(clubNoticesState.value)..insert(0, newItem);
      } else {
        deptNoticesState.value = List.from(deptNoticesState.value)..insert(0, newItem);
      }
      CacheService.invalidate(CacheKeys.notices);
    } catch (e) {
      debugPrint('Error inserting notice: $e');
      rethrow;
    }
  }

  static Future<void> updateNoticeInDB(NoticeItem notice, String category) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final data = notice.toJson(category);
    
    if (!isSuperUser) {
      data['is_approved'] = false;
    }
    
    try {
      await _client
          .from('notices')
          .update(data)
          .eq('id', notice.id);
      
      CacheService.invalidate(CacheKeys.notices);
      fetchNotices(forceRefresh: true);
    } catch (e) {
      debugPrint('Error updating notice: $e');
      rethrow;
    }
  }

  static Future<void> toggleNoticePin(String id, bool isPinned) async {
    await _client.from('notices').update({'is_pinned': isPinned}).eq('id', id);
    CacheService.invalidate(CacheKeys.notices);
    fetchNotices(forceRefresh: true);
  }

  static Future<void> deleteNoticeFromDB(NoticeItem notice, String category) async {
    try {
      // 1. Delete Image from Storage if exists
      if (notice.imagePath != null && notice.imagePath!.isNotEmpty) {
        final uri = Uri.parse(notice.imagePath!);
        final fileName = uri.pathSegments.last;
        await _client.storage.from('notice_images').remove([fileName]);
      }
      
      // 2. Delete from DB
      await _client.from('notices').delete().eq('id', notice.id);
      
      if (category == 'club') {
        clubNoticesState.value = List.from(clubNoticesState.value)..removeWhere((n) => n.id == notice.id);
      } else {
        deptNoticesState.value = List.from(deptNoticesState.value)..removeWhere((n) => n.id == notice.id);
      }
      CacheService.invalidate(CacheKeys.notices);
    } catch (e) {
      debugPrint('Error deleting notice and image: $e');
      rethrow;
    }
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

  static void subscribeToNotices() {
    _client
      .channel('public:notices')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notices',
        callback: (payload) {
          if (payload.eventType == PostgresChangeEvent.insert) {
            final data = payload.newRecord;
            // Notify if it's not our own notice
            if (data['created_by_name'] != currentProfile.value.name) {
               NotificationService.incrementUnread('notices');
               NotificationService.showNotification(
                id: 1,
                title: 'New Notice: ${data['title']}',
                body: data['description'] ?? 'A new notice has been posted.',
              );
            }
          }
          fetchNotices(forceRefresh: true);
        },
      )
      .subscribe();
  }
}
