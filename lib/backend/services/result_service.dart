import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile_state.dart';
import '../../features/results/models/result_state.dart';
import 'result_scraper_service.dart';

class ResultService {
  static final SupabaseClient _client = Supabase.instance.client;

  // 1. Load results from the new normalized tables
  static Future<List<ExamResult>> loadResultsFromDB() async {
    final profile = currentProfile.value;
    if (profile.id.isEmpty) {
      debugPrint('Skipping results load: Profile ID is empty');
      return [];
    }

    try {
      debugPrint('Loading results for user ID: ${profile.id}');
      // Fetch results and matching subject_results in a single query
      final resultsResponse = await _client
          .from('results')
          .select('*, subject_results(*)')
          .eq('user_id', profile.id)
          .order('created_at', ascending: false);
      
      debugPrint('Found ${resultsResponse.length} exam results in DB');

      final List<ExamResult> examResults = [];

      for (var resultRow in resultsResponse) {
        final List<dynamic> subjectsRaw = resultRow['subject_results'] ?? [];
        final List<SubjectResult> subjects = subjectsRaw
            .map((s) => SubjectResult.fromJson(s as Map<String, dynamic>))
            .toList();

        examResults.add(ExamResult.fromDB(resultRow, subjects));
      }

      return examResults;
    } catch (e) {
      debugPrint('Error loading results: $e');
      rethrow;
    }
  }

  // 2. Sync results using the ResultScraperService
  static Future<List<ExamResult>> syncResults() async {
    final profile = currentProfile.value;
    if (profile.duRegNo.isEmpty || profile.session.isEmpty) {
      debugPrint('Cannot sync: missing duReg or session');
      return [];
    }

    try {
      // Delegate the scraping and saving to the dedicated Scraper service
      await ResultScraperService.scrapeAndSaveAllResults(
        profile.id, 
        profile.duRegNo, 
        profile.session
      );

      // Reload the state from the DB after scraping finishes
      return await loadResultsFromDB();
    } catch (e) {
      debugPrint('Sync Error: $e');
      rethrow;
    }
  }

  // 3. Fetch all sessions (Admin / general)
  static Future<List<String>> fetchSessions() async {
    try {
      final List<dynamic> data = await _client
          .from('DUCMC_sessions_id')
          .select('session')
          .order('session', ascending: true);
      return data.map((row) => (row['session'] ?? '').toString()).toList();
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }

  // Fetch all sessions with their respective sess_id
  static Future<List<Map<String, String>>> fetchSessionsWithId() async {
    try {
      final List<dynamic> data = await _client
          .from('DUCMC_sessions_id')
          .select('session, sess_id')
          .order('session', ascending: true);
      return data.map((row) => {
        'session': (row['session'] ?? '').toString(),
        'sess_id': (row['sess_id'] ?? '').toString(),
      }).toList();
    } catch (e) {
      debugPrint('Error fetching sessions with ID: $e');
      return [];
    }
  }

  // Fetch all configured exams for a specific session
  static Future<List<Map<String, String>>> fetchExamsForSession(String session) async {
    try {
      final List<dynamic> data = await _client
          .from('DUCMC_exams_id')
          .select('exam_id, exam_name, session')
          .eq('session', session)
          .order('exam_name', ascending: true);
      return data.map((row) => {
        'exam_id': (row['exam_id'] ?? '').toString(),
        'exam_name': (row['exam_name'] ?? '').toString(),
        'session': (row['session'] ?? '').toString(),
      }).toList();
    } catch (e) {
      debugPrint('Error fetching exams for session $session: $e');
      return [];
    }
  }

  // 4. Fetch all configured exams (Admin only)
  static Future<List<Map<String, String>>> fetchAllExams() async {
    try {
      final List<dynamic> data = await _client
          .from('DUCMC_exams_id')
          .select('exam_id, exam_name, session')
          .order('exam_name', ascending: true);
      return data.map((row) => {
        'exam_id': (row['exam_id'] ?? '').toString(),
        'exam_name': (row['exam_name'] ?? '').toString(),
        'session': (row['session'] ?? '').toString(),
      }).toList();
    } catch (e) {
      debugPrint('Error fetching exams: $e');
      return [];
    }
  }

  // 5. Delete an exam configuration (Admin only)
  static Future<void> deleteExamId(String examId) async {
    await _client.from('DUCMC_exams_id').delete().eq('exam_id', examId);
  }

  // 6. Add new session ID (Admin only)
  static Future<void> addSessionId(String session, String sessId) async {
    await _client.from('DUCMC_sessions_id').upsert({
      'session': session,
      'sess_id': sessId,
    });
  }

  // 7. Add new exam ID (Admin only)
  static Future<void> addExamId(String examName, String examId, String session) async {
    await _client.from('DUCMC_exams_id').upsert({
      'exam_name': examName,
      'exam_id': examId,
      'session': session,
    });
  }
}
