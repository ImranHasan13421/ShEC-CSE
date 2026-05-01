import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/profile/models/profile_state.dart';
import '../../features/results/models/result_state.dart';

class ResultService {
  static final SupabaseClient _client = Supabase.instance.client;

  // 1. Fetch available exams
  static Future<List<DucmcExam>> fetchExams() async {
    try {
      final response = await _client.from('DUCMC_exams_id').select();
      return (response as List).map((e) => DucmcExam.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching exams: $e');
      return [];
    }
  }

  // 2. Fetch session ID mapping
  static Future<String?> getSessionId(String sessionText) async {
    try {
      final response = await _client
          .from('DUCMC_sessions_id')
          .select('sess_id')
          .eq('session', sessionText)
          .maybeSingle();
      return response?['sess_id']?.toString();
    } catch (e) {
      debugPrint('Error fetching session ID: $e');
      return null;
    }
  }

  // 3. Load results from Supabase for current user
  static Future<void> loadResultsFromDB() async {
    if (currentProfile.value.id.isEmpty) return;

    try {
      final exams = await fetchExams();
      final examMap = {for (var e in exams) e.examId: e.examName};

      final response = await _client
          .from('student_results')
          .select()
          .eq('reg_no', currentProfile.value.duRegNo)
          .order('created_at', ascending: false);

      final List<ExamResult> results = [];
      for (var row in response) {
        final examName = examMap[row['exam_id']] ?? 'Exam ${row['exam_id']}';
        results.add(ExamResult.fromJson(row, examName));
      }

      studentResultsState.value = results;
    } catch (e) {
      debugPrint('Error loading results: $e');
    }
  }

  // 4. Sync missing results from API
  static Future<void> syncResults() async {
    final profile = currentProfile.value;
    if (profile.duRegNo.isEmpty || profile.session.isEmpty) {
      debugPrint('Cannot sync: missing duReg or session');
      return;
    }

    isSyncingResults.value = true;

    try {
      // Get internal session ID mapped from string (e.g., "19-20" -> "21")
      final sessId = await getSessionId(profile.session);
      if (sessId == null) {
        debugPrint('Session ID mapping not found for ${profile.session}');
        isSyncingResults.value = false;
        return;
      }

      // Get all exams
      final allExams = await fetchExams();
      
      // Get existing results for current user
      final existingResponse = await _client.from('student_results').select('exam_id');
      final Set<String> existingExamIds = (existingResponse as List)
          .map((row) => row['exam_id'].toString())
          .toSet();

      // Find exams that need fetching
      final examsToFetch = allExams.where((exam) => !existingExamIds.contains(exam.examId)).toList();

      for (var exam in examsToFetch) {
        final success = await _fetchAndSaveResult(profile.duRegNo, exam.examId, sessId, exam.examName);
        if (success) {
          // Sleep briefly to avoid hammering the API
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Reload state after syncing
      await loadResultsFromDB();

    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      isSyncingResults.value = false;
    }
  }

  // Helper to fetch from API and save to DB
  static Future<bool> _fetchAndSaveResult(String regNo, String examId, String sessId, String examName) async {
    final baseUrl = dotenv.env['RESULT_API_URL'] ?? 'https://saifur2025-ducmc-info-scrapper.hf.space';
    final url = Uri.parse('$baseUrl/result?reg_no=$regNo&exam_id=$examId&sess_id=$sessId');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // If the API returns subjects, it's a valid result
        if (data['subjects'] != null && (data['subjects'] as List).isNotEmpty) {
          // Prepare DB insert
          final insertData = {
            'reg_no': regNo,
            'exam_id': examId,
            'gpa': data['gpa'] ?? '',
            'cgpa': data['cgpa'] ?? '',
            'subjects': data['subjects'],
          };
          
          await _client.from('student_results').insert(insertData);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error fetching specific result ($examId): $e');
      return false;
    }
  }
}
