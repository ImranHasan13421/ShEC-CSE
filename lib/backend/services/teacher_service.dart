import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/department/models/teacher_state.dart';
import '../../features/profile/models/profile_state.dart';

class TeacherService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchTeachers() async {
    final isAdmin = currentProfile.value.role != UserRole.student;
    
    var query = _client.from('teachers').select();
    if (!isAdmin) {
      query = query.eq('is_approved', true);
    }
    
    final response = await query.order('created_at', ascending: false);

    final List<TeacherContact> teachers = [];
    for (var row in response) {
      teachers.add(TeacherContact.fromJson(row));
    }
    teachersState.value = teachers;
  }

  static Future<void> addTeacher(TeacherContact teacher) async {
    final isSuperUser = currentProfile.value.role == UserRole.superUser;
    
    final data = teacher.toJson();
    data['is_approved'] = isSuperUser; 
    
    await _client.from('teachers').insert(data);
    fetchTeachers();
  }

  static Future<void> updateTeacher(TeacherContact teacher) async {
    final data = teacher.toJson();
    data.remove('is_approved'); // Don't overwrite existing status on normal edit
    
    await _client.from('teachers').update(data).eq('id', teacher.id);
    fetchTeachers();
  }

  static Future<void> approveTeacher(String id) async {
    await _client.from('teachers').update({'is_approved': true}).eq('id', id);
    fetchTeachers();
  }

  static Future<void> deleteTeacher(String id) async {
    await _client.from('teachers').delete().eq('id', id);
    fetchTeachers();
  }

  static Future<String?> uploadImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      await _client.storage.from('teacher_images').upload(fileName, file);
      return _client.storage.from('teacher_images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading teacher image: $e');
      return null;
    }
  }
}
