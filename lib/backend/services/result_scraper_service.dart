import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResultScraperService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Get Base URL from environment variables
  static String get _apiBaseUrl {
    final baseUrl = dotenv.env['RESULT_API_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception("RESULT_API_URL not found in .env file");
    }
    return baseUrl.endsWith('/') ? '${baseUrl}result' : '$baseUrl/result';
  }

  static Future<void> scrapeAndSaveAllResults(String userId, String regNo, String session) async {
    try {
      debugPrint('Starting result scraping for user: $userId');
      
      // 1. Get the sess_id from the session name
      final sessionData = await _client
          .from('DUCMC_sessions_id')
          .select('sess_id')
          .eq('session', session)
          .maybeSingle();
      
      if (sessionData == null) {
        debugPrint('Could not find sess_id for session: $session');
        return;
      }
      final String sessId = sessionData['sess_id'];

      // 2. Get all exam IDs
      final examsData = await _client.from('DUCMC_exams_id').select('exam_id, exam_name');
      final List<Map<String, dynamic>> exams = List<Map<String, dynamic>>.from(examsData);

      // 3. Iterate through exams and scrape
      for (var exam in exams) {
        final String examId = exam['exam_id'];
        final String examName = exam['exam_name'];
        
        await _scrapeSingleExam(userId, regNo, examId, sessId, examName);
      }
      
      debugPrint('Finished scraping all results for user: $userId');
    } catch (e) {
      debugPrint('Error in scrapeAndSaveAllResults: $e');
    }
  }

  static Future<void> _scrapeSingleExam(String userId, String regNo, String examId, String sessId, String examName) async {
    try {
      final url = Uri.parse('$_apiBaseUrl?reg_no=$regNo&exam_id=$examId&sess_id=$sessId');
      
      final response = await http.get(url).timeout(const Duration(minutes: 2));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Handle API error response
        if (data.containsKey('error')) {
          debugPrint('API Error for Exam $examId: ${data['error']}');
          return;
        }

        // Safely check for results
        final subjects = data['subjects'];
        final bool hasSubjects = subjects is List && subjects.isNotEmpty;
        final bool hasGpa = data['gpa'] != null || data['cgpa'] != null;

        if (hasGpa || hasSubjects) {
          await _saveResultToDB(userId, regNo, examId, sessId, examName, data);
        }
      }
    } catch (e) {
      // It's expected that many exams will return no results
      debugPrint('Scrape error for Exam $examId: $e');
    }
  }

  static Future<void> _saveResultToDB(String userId, String regNo, String examId, String sessId, String examName, Map<String, dynamic> data) async {
    try {
      // 1. Insert/Update the main result record
      final resultResponse = await _client.from('results').upsert({
        'user_id': userId,
        'reg_no': regNo,
        'exam_id': examId,
        'sess_id': sessId,
        'exam_name': examName,
        'gpa': data['gpa'],
        'cgpa': data['cgpa'],
      }).select('id').single();

      final String resultId = resultResponse['id'];

      // 2. Insert subject results
      final dynamic subjectsRaw = data['subjects'];
      final List<dynamic> subjects = (subjectsRaw is List) ? subjectsRaw : [];
      
      if (subjects.isNotEmpty) {
        // Delete old subject results for this specific exam if any (due to upsert logic)
        await _client.from('subject_results').delete().eq('result_id', resultId);
        
        final List<Map<String, dynamic>> subjectData = subjects.map((s) => {
          'result_id': resultId,
          'subject_code': s['code'],
          'subject_name': s['name'],
          'grade': s['grade'],
          'point': s['point'],
        }).toList();

        await _client.from('subject_results').insert(subjectData);
      }
    } catch (e) {
      debugPrint('Error saving result to DB: $e');
    }
  }
}
