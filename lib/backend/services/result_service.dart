import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile_state.dart';
import '../../features/results/models/result_state.dart';
import '../../features/results/models/batch_member_result.dart';
import '../../core/services/database_helper.dart';
import '../../core/services/connectivity_service.dart';
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

    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      final cachedResultsStr = await DatabaseHelper.instance.getCache('personal_results');
      if (cachedResultsStr != null) {
        try {
          final List decoded = json.decode(cachedResultsStr);
          final list = decoded.map((r) => ExamResult.fromLocalJson(r)).toList();
          debugPrint('Successfully loaded personal results from local SQLite cache.');
          return list;
        } catch (e) {
          debugPrint('Error deserializing cached results: $e');
        }
      }
      return [];
    }

    try {
      debugPrint('Loading results for user ID: ${profile.id}');
      // Fetch results and matching subject_results with subject_information in a single query
      final resultsResponse = await _client
          .from('results')
          .select('*, DUCMC_exams_id(semester), subject_results(*, subject_information(*))')
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

      // Save to SQLite
      await DatabaseHelper.instance.saveCache(
        'personal_results', 
        json.encode(examResults.map((r) => r.toJson()).toList()),
      );

      return examResults;
    } catch (e) {
      debugPrint('Error loading results: $e');
      final cachedResultsStr = await DatabaseHelper.instance.getCache('personal_results');
      if (cachedResultsStr != null) {
        try {
          final List decoded = json.decode(cachedResultsStr);
          return decoded.map((r) => ExamResult.fromLocalJson(r)).toList();
        } catch (_) {}
      }
      rethrow;
    }
  }

  // 1b. Load results for all members of a batch (session)
  static Future<List<BatchMemberResult>> loadBatchResults(String session) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      final cachedBatchStr = await DatabaseHelper.instance.getCache('batch_results_$session');
      if (cachedBatchStr != null) {
        try {
          final List decoded = json.decode(cachedBatchStr);
          final list = decoded.map((e) => BatchMemberResult.fromJson(e)).toList();
          debugPrint('Successfully loaded batch results from SQLite cache.');
          return list;
        } catch (e) {
          debugPrint('Error deserializing cached batch results: $e');
        }
      }
      return [];
    }

    try {
      debugPrint('Loading batch results for session: $session');
      // Fetch profiles in the same session
      final profilesResponse = await _client
          .from('profiles')
          .select()
          .eq('session', session);

      final List<ProfileData> profiles = [];
      for (var p in profilesResponse) {
        UserRole parsedRole;
        switch (p['role']) {
          case 'superuser': parsedRole = UserRole.superUser; break;
          case 'committee': parsedRole = UserRole.committeeMember; break;
          default: parsedRole = UserRole.student; break;
        }

        profiles.add(ProfileData(
          id: p['id'] ?? '',
          firstName: p['first_name'] ?? '',
          lastName: p['last_name'] ?? '',
          name: '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim().isEmpty 
              ? (p['email'] ?? 'Student') 
              : '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim(),
          email: p['email'] ?? '',
          universityId: p['university_id'] ?? '',
          classRoll: p['class_roll'] ?? '',
          duRegNo: p['du_reg'] ?? '',
          session: p['session'] ?? '',
          batch: p['batch'] ?? '',
          phone: p['phone'] ?? '',
          imagePath: p['profile_pic'],
          role: parsedRole,
          designation: p['designation'] ?? 'Student',
          isApproved: p['is_approved'] ?? false,
          isAlumni: p['is_alumni'] ?? false,
        ));
      }

      if (profiles.isEmpty) {
        debugPrint('No profiles found for session: $session');
        return [];
      }

      final List<String> userIds = profiles.map((p) => p.id).toList();

      // Fetch all results for these users with subject_information
      final resultsResponse = await _client
          .from('results')
          .select('*, DUCMC_exams_id(semester), subject_results(*, subject_information(*))')
          .inFilter('user_id', userIds)
          .order('created_at', ascending: false);

      debugPrint('Found ${resultsResponse.length} batch exam results in DB');

      final List<BatchMemberResult> batchResults = [];
      for (var resultRow in resultsResponse) {
        final userId = resultRow['user_id'];
        final profile = profiles.firstWhere((p) => p.id == userId, orElse: () => currentProfile.value);
        if (profile.id.isEmpty || profile.id == currentProfile.value.id) {
          // If profile is not found or it's the current user
        }

        final List<dynamic> subjectsRaw = resultRow['subject_results'] ?? [];
        final List<SubjectResult> subjects = subjectsRaw
            .map((s) => SubjectResult.fromJson(s as Map<String, dynamic>))
            .toList();

        final examResult = ExamResult.fromDB(resultRow, subjects);
        batchResults.add(BatchMemberResult(profile: profile, result: examResult));
      }

      // Save to SQLite
      await DatabaseHelper.instance.saveCache(
        'batch_results_$session', 
        json.encode(batchResults.map((e) => e.toJson()).toList()),
      );

      return batchResults;
    } catch (e) {
      debugPrint('Error loading batch results: $e');
      final cachedBatchStr = await DatabaseHelper.instance.getCache('batch_results_$session');
      if (cachedBatchStr != null) {
        try {
          final List decoded = json.decode(cachedBatchStr);
          return decoded.map((e) => BatchMemberResult.fromJson(e)).toList();
        } catch (_) {}
      }
      return [];
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
          .select('exam_id, exam_name, session, semester')
          .eq('session', session)
          .order('exam_name', ascending: true);
      return data.map((row) => {
        'exam_id': (row['exam_id'] ?? '').toString(),
        'exam_name': (row['exam_name'] ?? '').toString(),
        'session': (row['session'] ?? '').toString(),
        'semester': (row['semester'] ?? '').toString(),
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
          .select('exam_id, exam_name, session, semester')
          .order('exam_name', ascending: true);
      return data.map((row) => {
        'exam_id': (row['exam_id'] ?? '').toString(),
        'exam_name': (row['exam_name'] ?? '').toString(),
        'session': (row['session'] ?? '').toString(),
        'semester': (row['semester'] ?? '').toString(),
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
  static Future<void> addExamId(String examName, String examId, String session, int semester) async {
    await _client.from('DUCMC_exams_id').upsert({
      'exam_name': examName,
      'exam_id': examId,
      'session': session,
      'semester': semester,
    });
  }

  // 8. Delete a specific personal result (and let CASCADE delete associated subject results)
  static Future<void> deleteResult(String resultId) async {
    await _client.from('results').delete().eq('id', resultId);
  }
}
