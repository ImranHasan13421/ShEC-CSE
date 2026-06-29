import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ShEC_CSE/core/utils/subject_information.dart';
import 'result_service.dart';

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
      
      // 1. Get all sessions to build a map of session -> sess_id
      final sessionsData = await _client
          .from('DUCMC_sessions_id')
          .select('session, sess_id');
      
      final Map<String, String> sessionToSessId = {
        for (var row in sessionsData)
          (row['session'] ?? '').toString(): (row['sess_id'] ?? '').toString()
      };

      final String studentSessId = sessionToSessId[session] ?? '';
      if (studentSessId.isEmpty) {
        debugPrint('Could not find sess_id for student session: $session');
        return;
      }

      // 2. Get all exam IDs for the specific session + all improvement exams
      final examsData = await _client
          .from('DUCMC_exams_id')
          .select('exam_id, exam_name, session, is_improvement, improves_semester')
          .or('session.eq.$session,is_improvement.eq.true');
      final List<Map<String, dynamic>> exams = List<Map<String, dynamic>>.from(examsData);

      // 3. Perform concurrent scraping tasks
      final List<Future<void>> scrapingTasks = exams.map((exam) {
        final String examId = exam['exam_id'];
        final String examName = exam['exam_name'];
        final String examSession = exam['session'] ?? session;
        final String examSessId = sessionToSessId[examSession] ?? studentSessId;
        final bool isImprovementExam = exam['is_improvement'] == true;
        final int? improvesSemester = exam['improves_semester'] as int?;
        return _scrapeSingleExam(
          userId, regNo, examId, examSessId, examName,
          isImprovementHint: isImprovementExam,
          improvesSemester: improvesSemester,
        );
      }).toList();

      await Future.wait(scrapingTasks);
      
      // ── After all exams scraped, recalculate effective CGPA for all semesters ──
      await ResultService.recalculateEffectiveCgpa(userId);
      
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
    bool isImprovementHint = false,
    int? improvesSemester,
  }) async {
    try {
      final examData = await _client
          .from('DUCMC_exams_id')
          .select('session, is_improvement, improves_semester')
          .eq('exam_id', examId)
          .maybeSingle();

      String resolvedSessId = sessId;
      bool resolvedIsImp = isImprovementHint;
      int? resolvedImpSem = improvesSemester;

      if (examData != null) {
        final String examSession = examData['session'] ?? '';
        resolvedIsImp = examData['is_improvement'] == true;
        resolvedImpSem = examData['improves_semester'] as int?;

        if (examSession.isNotEmpty) {
          final sessionData = await _client
              .from('DUCMC_sessions_id')
              .select('sess_id')
              .eq('session', examSession)
              .maybeSingle();
          if (sessionData != null) {
            resolvedSessId = sessionData['sess_id'] ?? sessId;
          }
        }
      }

      final success = await _scrapeSingleExam(
        userId, regNo, examId, resolvedSessId, examName,
        isImprovementHint: resolvedIsImp,
        improvesSemester: resolvedImpSem,
      );
      // ── After saving, recalculate effective CGPA across all semesters ──
      if (success) await ResultService.recalculateEffectiveCgpa(userId);
      return success;
    } catch (e) {
      debugPrint('Error in scrapeAndSaveSingleResult: $e');
      final fallback = await _scrapeSingleExam(
        userId, regNo, examId, sessId, examName,
        isImprovementHint: isImprovementHint,
        improvesSemester: improvesSemester,
      );
      if (fallback) await ResultService.recalculateEffectiveCgpa(userId);
      return fallback;
    }
  }

  /// Auto-detect if a result is an improvement/backlog result.
  /// Detection logic:
  ///   1. Admin has flagged it as an improvement exam (isImprovementHint = true)
  ///   2. OR the API returns status containing "imp" (case-insensitive)
  ///   3. OR gpa and cgpa are both null but subjects exist
  static bool _isImprovementResult(Map<String, dynamic> data, {bool isImprovementHint = false}) {
    if (isImprovementHint) return true;
    final status = (data['status'] ?? '').toString().toLowerCase();
    if (status.contains('imp')) return true;
    final gpaNull = data['gpa'] == null;
    final cgpaNull = data['cgpa'] == null;
    final hasSubjects = (data['subjects'] as List?)?.isNotEmpty == true;
    return gpaNull && cgpaNull && hasSubjects;
  }

  /// Calculate semester GPA from subject grade points and credits.
  /// Formula: Σ(grade_point × credits) / Σ(credits)
  static double? _calculateGpaFromSubjects(List<dynamic> subjects) {
    double totalPoints = 0.0;
    double totalCredits = 0.0;

    for (final s in subjects) {
      final pointStr = s['point']?.toString() ?? '';
      final point = double.tryParse(pointStr);
      if (point == null) continue;

      final code = (s['code'] ?? '').toString().toUpperCase().replaceAll(' ', '-').trim();
      final credits = SubjectInformation.getCredits(code);

      totalPoints += point * credits;
      totalCredits += credits;
    }

    if (totalCredits == 0) return null;
    // Round to 2 decimal places
    return double.parse((totalPoints / totalCredits).toStringAsFixed(2));
  }

  static Future<bool> _scrapeSingleExam(
    String userId,
    String regNo,
    String examId,
    String sessId,
    String examName, {
    bool isImprovementHint = false,
    int? improvesSemester,
  }) async {
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
          // Detect if this is an improvement result
          final bool isImprovement = _isImprovementResult(data, isImprovementHint: isImprovementHint);

          // Calculate GPA for improvement results (official gpa is null)
          double? calculatedGpa;
          if (isImprovement && hasSubjects) {
            calculatedGpa = _calculateGpaFromSubjects(subjects as List);
            debugPrint('Improvement result detected for exam $examId. Calculated GPA: $calculatedGpa');
          }

          await _saveResultToDB(
            userId, regNo, examId, sessId, examName, data,
            isImprovement: isImprovement,
            calculatedGpa: calculatedGpa,
          );
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

  static Future<void> _saveResultToDB(
    String userId,
    String regNo,
    String examId,
    String sessId,
    String examName,
    Map<String, dynamic> data, {
    bool isImprovement = false,
    double? calculatedGpa,
  }) async {
    try {
      final parsedGpa = _parseDbNumeric(data['gpa']);
      final parsedCgpa = _parseDbNumeric(data['cgpa']);

      // 1. Insert/Update the main result record
      final resultResponse = await _client.from('results').upsert({
        'user_id': userId,
        'reg_no': regNo,
        'exam_id': examId,
        'sess_id': sessId,
        'exam_name': examName,
        'gpa': parsedGpa,
        'cgpa': parsedCgpa,
        'result_type': isImprovement ? 'improvement' : 'main',
        'calculated_gpa': calculatedGpa,
      }, onConflict: 'user_id,exam_id').select('id').single();

      final String resultId = resultResponse['id'];

      // 2. Insert subject results
      final dynamic subjectsRaw = data['subjects'];
      final List<dynamic> subjects = (subjectsRaw is List) ? subjectsRaw : [];
      
      if (subjects.isNotEmpty) {
        // Delete old subject results for this specific exam if any (due to upsert logic)
        await _client.from('subject_results').delete().eq('result_id', resultId);
        
        final List<Map<String, dynamic>> subjectData = [];
        
        for (var s in subjects) {
          final String originalCode = (s['code'] ?? '').toString();
          final String normalizedCode = originalCode.toUpperCase().replaceAll(' ', '-').trim();
          final String subjectName = (s['name'] ?? '').toString();
          
          // Dynamic upsert subject details to subject_information to obtain its UUID id
          final subjectInfo = await _client.from('subject_information').upsert({
            'code': normalizedCode,
            'subject_name': subjectName,
            'credits': SubjectInformation.getCredits(normalizedCode),
          }, onConflict: 'code').select('id').single();
          
          final String subjectId = subjectInfo['id'];
          
          subjectData.add({
            'result_id': resultId,
            'subject_id': subjectId,
            'grade': s['grade'],
            'point': _parseDbNumeric(s['point']),
          });
        }

        await _client.from('subject_results').insert(subjectData);
      }
    } catch (e) {
      debugPrint('Error saving result to DB: $e');
      rethrow;
    }
  }
}
