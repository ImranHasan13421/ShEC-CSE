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
      // Fetch all exam summaries for the user
      final resultsResponse = await _client
          .from('results')
          .select()
          .eq('user_id', profile.id)
          .order('created_at', ascending: false);
      
      debugPrint('Found ${resultsResponse.length} exam results in DB');

      final List<ExamResult> examResults = [];

      for (var resultRow in resultsResponse) {
        final resultId = resultRow['id'];
        
        // Fetch subjects for this specific exam
        final subjectsResponse = await _client
            .from('subject_results')
            .select()
            .eq('result_id', resultId);
        
        final List<SubjectResult> subjects = (subjectsResponse as List)
            .map((s) => SubjectResult.fromJson(s))
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

  // 4. Add new session ID (Admin only)
  static Future<void> addSessionId(String session, String sessId) async {
    await _client.from('DUCMC_sessions_id').upsert({
      'session': session,
      'sess_id': sessId,
    });
  }

  // 5. Add new exam ID (Admin only)
  static Future<void> addExamId(String examName, String examId) async {
    await _client.from('DUCMC_exams_id').upsert({
      'exam_name': examName,
      'exam_id': examId,
    });
  }
}
