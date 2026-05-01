import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notices/models/notice_state.dart';

class NoticeService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchNotices() async {
    final response = await _client
        .from('notices')
        .select()
        .order('created_at', ascending: false);

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
  }

  static Future<void> addNoticeToDB(NoticeItem notice, String category) async {
    final data = notice.toJson(category);
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
  }

  static Future<void> updateNoticeInDB(NoticeItem notice, String category) async {
    final data = notice.toJson(category);
    await _client
        .from('notices')
        .update(data)
        .eq('id', notice.id);
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
  }

  static Future<String?> uploadImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      await _client.storage.from('notice_images').upload(fileName, file);
      return _client.storage.from('notice_images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
