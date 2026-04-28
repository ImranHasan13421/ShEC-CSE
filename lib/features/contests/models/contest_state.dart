import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContestItem {
  final String id;
  final String title;
  final String platform;
  final String level;
  final String date;
  final String url;
  final Color iconColor;
  final bool isCourse; // To distinguish between contests and courses

  ContestItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.level,
    required this.date,
    required this.url,
    required this.iconColor,
    this.isCourse = false,
  });

  factory ContestItem.fromJson(Map<String, dynamic> json) {
    return ContestItem(
      id: json['id'] as String,
      title: json['title'] as String,
      platform: json['platform'] as String,
      level: json['level'] as String,
      date: json['date'] as String,
      url: json['url'] as String,
      iconColor: Color(json['icon_color'] as int),
      isCourse: json['is_course'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'platform': platform,
      'level': level,
      'date': date,
      'url': url,
      'icon_color': iconColor.value,
      'is_course': isCourse,
    };
  }
}

final ValueNotifier<List<ContestItem>> contestState = ValueNotifier([]);
final ValueNotifier<List<ContestItem>> courseState = ValueNotifier([]);

Future<void> fetchContestsAndCourses() async {
  try {
    final response = await Supabase.instance.client
        .from('contests')
        .select()
        .order('created_at', ascending: false);

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
  } catch (e) {
    debugPrint('Error fetching contests/courses: $e');
  }
}

Future<void> addContestToDB(ContestItem item) async {
  try {
    final data = item.toJson();
    final response = await Supabase.instance.client
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
  } catch (e) {
    debugPrint('Error adding contest/course: $e');
  }
}

Future<void> updateContestInDB(ContestItem item) async {
  try {
    final data = item.toJson();
    await Supabase.instance.client
        .from('contests')
        .update(data)
        .eq('id', item.id);
  } catch (e) {
    debugPrint('Error updating contest/course: $e');
  }
}

Future<void> deleteContestFromDB(ContestItem item) async {
  try {
    await Supabase.instance.client
        .from('contests')
        .delete()
        .eq('id', item.id);

    if (item.isCourse) {
      courseState.value = List.from(courseState.value)..removeWhere((i) => i.id == item.id);
    } else {
      contestState.value = List.from(contestState.value)..removeWhere((i) => i.id == item.id);
    }
  } catch (e) {
    debugPrint('Error deleting contest/course: $e');
  }
}
