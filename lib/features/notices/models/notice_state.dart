import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoticeItem {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> tags;
  final Color tagColor;
  final String date;
  bool isPinned;

  NoticeItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.tagColor,
    required this.date,
    this.isPinned = false,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: json['id'] as String,
      icon: IconData(json['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
      iconColor: Color(json['icon_color'] as int),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      tagColor: Color(json['tag_color'] as int),
      date: json['date'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson(String category) {
    return {
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'tags': tags,
      'tag_color': tagColor.value,
      'date': date,
      'is_pinned': isPinned,
      'icon_code_point': icon.codePoint,
      'icon_color': iconColor.value,
    };
  }
}

// Global Notifiers for Notices
final ValueNotifier<List<NoticeItem>> clubNoticesState = ValueNotifier([]);
final ValueNotifier<List<NoticeItem>> deptNoticesState = ValueNotifier([]);

Future<void> fetchNotices() async {
  try {
    final response = await Supabase.instance.client
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
  } catch (e) {
    debugPrint('Error fetching notices: $e');
  }
}

Future<void> addNoticeToDB(NoticeItem notice, String category) async {
  try {
    final data = notice.toJson(category);
    final response = await Supabase.instance.client
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
  } catch (e) {
    debugPrint('Error adding notice: $e');
  }
}

Future<void> updateNoticeInDB(NoticeItem notice, String category) async {
  try {
    final data = notice.toJson(category);
    await Supabase.instance.client
        .from('notices')
        .update(data)
        .eq('id', notice.id);
  } catch (e) {
    debugPrint('Error updating notice: $e');
  }
}

Future<void> deleteNoticeFromDB(String id, String category) async {
  try {
    await Supabase.instance.client
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
  } catch (e) {
    debugPrint('Error deleting notice: $e');
  }
}
