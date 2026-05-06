import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/department/models/teacher_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/storage_service.dart';


class TeacherService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchTeachers({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.teachers)) return;

    try {
      final isAdmin = currentProfile.value.role != UserRole.student;
      var query = _client.from('teachers').select();
      if (!isAdmin) {
        query = query.eq('is_approved', true).eq('is_visible', true);
      }
      final response = await query.order('created_at', ascending: false);
      teachersState.value = (response as List).map((e) => TeacherContact.fromJson(e)).toList();
      CacheService.markFresh(CacheKeys.teachers);
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
    }
  }

  static Future<void> addTeacher(TeacherContact teacher) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';

    final data = teacher.toJson();
    data['is_approved'] = isSuperUser;
    data['is_visible'] = teacher.isVisible;
    data['created_by_name'] = profile.name;

    await _client.from('teachers').insert(data);
    CacheService.invalidate(CacheKeys.teachers);
    await fetchTeachers(forceRefresh: true);
  }

  static Future<void> toggleTeacherVisibility(String id, bool isVisible) async {
    await _client.from('teachers').update({'is_visible': isVisible}).eq('id', id);
    CacheService.invalidate(CacheKeys.teachers);
    await fetchTeachers(forceRefresh: true);
  }

  static Future<void> updateTeacher(TeacherContact teacher) async {
    final data = teacher.toJson();
    data.remove('is_approved');
    await _client.from('teachers').update(data).eq('id', teacher.id);
    CacheService.invalidate(CacheKeys.teachers);
    await fetchTeachers(forceRefresh: true);
  }

  static Future<void> approveTeacher(String id) async {
    await _client.from('teachers').update({'is_approved': true}).eq('id', id);
    CacheService.invalidate(CacheKeys.teachers);
    await fetchTeachers(forceRefresh: true);
  }

  static Future<void> deleteTeacher(TeacherContact teacher) async {
    try {
      // 1. Delete image from storage
      if (teacher.imagePath.isNotEmpty) {
        await StorageService.deleteFile(teacher.imagePath);
      }

      // 2. Delete from DB
      await _client.from('teachers').delete().eq('id', teacher.id);
      
      teachersState.value = teachersState.value.where((t) => t.id != teacher.id).toList();
      CacheService.invalidate(CacheKeys.teachers);
    } catch (e) {
      debugPrint('Error deleting teacher: $e');
      rethrow;
    }
  }

  static Future<String?> uploadImage(File file) async {
    return StorageService.uploadFile(file, 'teacher_images');
  }
}
