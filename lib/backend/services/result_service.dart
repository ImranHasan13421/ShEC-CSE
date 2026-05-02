import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile_state.dart';
import '../../features/results/models/result_state.dart';
import 'result_scraper_service.dart';

class ResultService {
  static final SupabaseClient _client = Supabase.instance.client;

  // 1. Load results from the new normalized tables
  static Future<void> loadResultsFromDB() async {
    final profile = currentProfile.value;
    if (profile.id.isEmpty) return;

    try {
      // Fetch all exam summaries for the user
      final resultsResponse = await _client
          .from('results')
          .select()
          .eq('user_id', profile.id)
          .order('created_at', ascending: false);

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

      studentResultsState.value = examResults;
    } catch (e) {
      debugPrint('Error loading results: $e');
    }
  }

  // 2. Sync results using the ResultScraperService
  static Future<void> syncResults() async {
    final profile = currentProfile.value;
    if (profile.duRegNo.isEmpty || profile.session.isEmpty) {
      debugPrint('Cannot sync: missing duReg or session');
      return;
    }

    isSyncingResults.value = true;

    try {
      // Delegate the scraping and saving to the dedicated Scraper service
      await ResultScraperService.scrapeAndSaveAllResults(
        profile.id, 
        profile.duRegNo, 
        profile.session
      );

      // Reload the state from the DB after scraping finishes
      await loadResultsFromDB();
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      isSyncingResults.value = false;
    }
  }

  // 3. (Optional) Fetch available exam IDs for metadata
  static Future<List<DucmcExam>> fetchExams() async {
    try {
      final response = await _client.from('DUCMC_exams_id').select();
      return (response as List).map((e) => DucmcExam.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching exams: $e');
      return [];
    }
  }
}
