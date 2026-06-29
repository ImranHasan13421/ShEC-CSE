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
          .select('*, effective_cgpa, DUCMC_exams_id(semester), subject_results(*, subject_information(*))')
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
      // Note: is_improvement hints are now loaded inside scrapeAndSaveAllResults
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

  // Fetch all exams configured for a specific session
  static Future<List<Map<String, String>>> fetchExamsForSession(String session) async {
    try {
      final List<dynamic> data = await _client
          .from('DUCMC_exams_id')
          .select('exam_id, exam_name, session, semester, is_improvement, improves_semester')
          .eq('session', session)
          .order('exam_name', ascending: true);
      return data.map((row) => {
        'exam_id': (row['exam_id'] ?? '').toString(),
        'exam_name': (row['exam_name'] ?? '').toString(),
        'session': (row['session'] ?? '').toString(),
        'semester': (row['semester'] ?? '').toString(),
        'is_improvement': (row['is_improvement'] ?? false).toString(),
        'improves_semester': (row['improves_semester'] ?? '').toString(),
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
          .select('exam_id, exam_name, session, semester, is_improvement, improves_semester')
          .order('exam_name', ascending: true);
      return data.map((row) => {
        'exam_id': (row['exam_id'] ?? '').toString(),
        'exam_name': (row['exam_name'] ?? '').toString(),
        'session': (row['session'] ?? '').toString(),
        'semester': (row['semester'] ?? '').toString(),
        'is_improvement': (row['is_improvement'] ?? false).toString(),
        'improves_semester': (row['improves_semester'] ?? '').toString(),
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
  static Future<void> addExamId(
    String examName,
    String examId,
    String session,
    int semester, {
    bool isImprovement = false,
    int? improvesSemester,
  }) async {
    await _client.from('DUCMC_exams_id').upsert({
      'exam_name': examName,
      'exam_id': examId,
      'session': session,
      'semester': semester,
      'is_improvement': isImprovement,
      'improves_semester': improvesSemester,
    });
  }

  // 8. Recalculate and persist effective CGPA for all main results of a user.
  //
  // Algorithm:
  //   1. Load all results (main + improvement) sorted by semester ascending.
  //   2. Build a map: semester -> best improvement GPA (calculatedGpa).
  //   3. Walk main results in semester order:
  //        effectiveGpa[sem] = max(mainGpa, improvementGpa[sem]) if improvement exists, else mainGpa
  //        effectiveCgpa[sem] = Σ effectiveGpa[1..sem] credits-weighted
  //   4. UPDATE each main result row in Supabase with the computed effective_cgpa.
  static Future<void> recalculateEffectiveCgpa(String userId) async {
    debugPrint('Recalculating effective CGPA for user: $userId');
    try {
      final resultsResponse = await _client
          .from('results')
          .select('*, DUCMC_exams_id(semester), subject_results(*, subject_information(*))')
          .eq('user_id', userId);

      final List<Map<String, dynamic>> mainRows = [];
      final List<Map<String, dynamic>> improvementRows = [];

      for (final row in resultsResponse) {
        final resultType = row['result_type']?.toString() ?? 'main';
        final examIdData = row['DUCMC_exams_id'];
        int? sem;
        if (examIdData is Map) sem = examIdData['semester'] as int?;
        else if (examIdData is List && examIdData.isNotEmpty) sem = examIdData.first['semester'] as int?;
        
        if (sem == null) continue;
        
        final rowWithSem = {...(row as Map<String, dynamic>), '_semester': sem};
        if (resultType == 'improvement') {
          improvementRows.add(rowWithSem);
        } else {
          mainRows.add(rowWithSem);
        }
      }

      // Sort main rows by semester ascending
      mainRows.sort((a, b) => (a['_semester'] as int).compareTo(b['_semester'] as int));

      double effectiveTotalPoints = 0.0;
      double effectiveTotalCredits = 0.0;
      final List<Map<String, dynamic>> updates = [];

      for (final mainRow in mainRows) {
        final sem = mainRow['_semester'] as int;
        
        // 1. Build map of main subjects: code -> SubjectResult
        final mainSubjectsRaw = mainRow['subject_results'] as List<dynamic>? ?? [];
        final Map<String, SubjectResult> mergedSubjects = {};
        for (final s in mainSubjectsRaw) {
          final sub = SubjectResult.fromJson(s as Map<String, dynamic>);
          mergedSubjects[sub.code] = sub;
        }

        // 2. Override with improvement subjects for this semester
        final impForSem = improvementRows.where((r) => r['_semester'] == sem).toList();
        for (final impRow in impForSem) {
          final impSubjectsRaw = impRow['subject_results'] as List<dynamic>? ?? [];
          for (final s in impSubjectsRaw) {
            final impSub = SubjectResult.fromJson(s as Map<String, dynamic>);
            final impPoint = double.tryParse(impSub.point) ?? 0.0;
            
            if (mergedSubjects.containsKey(impSub.code)) {
              final mainPoint = double.tryParse(mergedSubjects[impSub.code]!.point) ?? 0.0;
              // Only override if improvement is better
              if (impPoint > mainPoint) {
                mergedSubjects[impSub.code] = impSub;
              }
            } else {
              // Add anyway if it doesn't exist (rare)
              mergedSubjects[impSub.code] = impSub;
            }
          }
        }

        // 3. Calculate new effective semester GPA from merged subjects
        double semTotalPoints = 0.0;
        double semTotalCredits = 0.0;
        for (final sub in mergedSubjects.values) {
          final p = double.tryParse(sub.point) ?? 0.0;
          semTotalPoints += (p * sub.credits);
          semTotalCredits += sub.credits;
        }
        
        double effectiveSemGpa = 0.0;
        if (semTotalCredits > 0) {
          effectiveSemGpa = semTotalPoints / semTotalCredits;
        } else {
          // Fallback to official GPA if subjects are missing
          effectiveSemGpa = (mainRow['gpa'] as num?)?.toDouble() ?? 0.0;
        }
        
        // Accumulate for CGPA using true credits
        // We accumulate (effectiveSemGpa * true sem credits) to match DU formula
        // Wait, DU Formula for CGPA is sum(GPA_i * Credits_i) / sum(Credits_i)
        // Or is it sum(Points_overall) / sum(Credits_overall)? They are equivalent.
        if (semTotalCredits == 0) {
           // Fallback credits if no subject data
           semTotalCredits = 21.0; 
        }
        
        effectiveTotalPoints += (effectiveSemGpa * semTotalCredits);
        effectiveTotalCredits += semTotalCredits;
        
        double effectiveCgpa = 0.0;
        if (effectiveTotalCredits > 0) {
          effectiveCgpa = effectiveTotalPoints / effectiveTotalCredits;
        }

        updates.add({
          'id': mainRow['id'],
          'effective_gpa': double.parse(effectiveSemGpa.toStringAsFixed(2)),
          'effective_cgpa': double.parse(effectiveCgpa.toStringAsFixed(4)),
        });
      }

      // Batch-update Supabase
      for (final u in updates) {
        await _client
            .from('results')
            .update({
              'effective_gpa': u['effective_gpa'],
              'effective_cgpa': u['effective_cgpa']
            })
            .eq('id', u['id'] as String);
      }
      debugPrint('Effective CGPA recalculated for ${updates.length} semesters');
    } catch (e) {
      debugPrint('Error recalculating effective CGPA: $e');
    }
  }

  // 9. Delete a specific personal result (and let CASCADE delete associated subject results)
  static Future<void> deleteResult(String resultId) async {
    await _client.from('results').delete().eq('id', resultId);
  }
}
