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

      // 2. Get all exam IDs for the specific session
      final examsData = await _client
          .from('DUCMC_exams_id')
          .select('exam_id, exam_name')
          .eq('session', session);
      final List<Map<String, dynamic>> exams = List<Map<String, dynamic>>.from(examsData);

      // 3. Perform concurrent scraping tasks
      final List<Future<void>> scrapingTasks = exams.map((exam) {
        final String examId = exam['exam_id'];
        final String examName = exam['exam_name'];
        return _scrapeSingleExam(userId, regNo, examId, sessId, examName);
      }).toList();

      await Future.wait(scrapingTasks);
      
      debugPrint('Finished scraping all results for user: $userId');
    } catch (e) {
      debugPrint('Error in scrapeAndSaveAllResults: $e');
    }
  }

  static Future<bool> scrapeAndSaveSingleResult({
    required String userId,
    required String regNo,
    required String examId,
    required String sessId,
    required String examName,
  }) async {
    return await _scrapeSingleExam(userId, regNo, examId, sessId, examName);
  }

  static Future<bool> _scrapeSingleExam(String userId, String regNo, String examId, String sessId, String examName) async {
    try {
      final url = Uri.parse('$_apiBaseUrl?reg_no=$regNo&exam_id=$examId&sess_id=$sessId');
      
      final response = await http.get(url).timeout(const Duration(minutes: 2));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('error')) {
          debugPrint('API returned error for exam $examId: ${data['error']}');
          return false;
        }

        final subjects = data['subjects'];
        final bool hasSubjects = subjects is List && subjects.isNotEmpty;
        final bool hasGpa = data['gpa'] != null || data['cgpa'] != null;

        if (hasGpa || hasSubjects) {
          await _saveResultToDB(userId, regNo, examId, sessId, examName, data);
          return true;
        } else {
          debugPrint('No GPA or subjects returned for exam $examId');
          return false;
        }
      } else {
        debugPrint('Failed to scrape exam $examId: HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Scrape error for Exam $examId: $e');
      return false;
    }
  }

  static double? _parseDbNumeric(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final str = value.toString().trim();
    if (str.isEmpty || str == 'null') return null;
    return double.tryParse(str);
  }

  static Future<void> _saveResultToDB(String userId, String regNo, String examId, String sessId, String examName, Map<String, dynamic> data) async {
    try {
      final parsedGpa = _parseDbNumeric(data['gpa']);
      final parsedCgpa = _parseDbNumeric(data['cgpa']);

      // 1. Insert/Update the main result record with user_id, exam_id onConflict target
      final resultResponse = await _client.from('results').upsert({
        'user_id': userId,
        'reg_no': regNo,
        'exam_id': examId,
        'sess_id': sessId,
        'exam_name': examName,
        'gpa': parsedGpa,
        'cgpa': parsedCgpa,
      }, onConflict: 'user_id,exam_id').select('id').single();

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
          'point': _parseDbNumeric(s['point']),
        }).toList();

        await _client.from('subject_results').insert(subjectData);
      }
    } catch (e) {
      debugPrint('Error saving result to DB: $e');
      rethrow;
    }
  }
}
