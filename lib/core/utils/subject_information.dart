import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_helper.dart';
import '../services/connectivity_service.dart';

class SubjectInformation {
  // Hardcoded fallback data based on the provided JSON
  static final Map<String, double> _fallbackCredits = {
    // Semester 1
    "CSE-1101": 2.0, "CSE-1102": 3.0, "EEE-1103": 3.0, "CHE-1104": 3.0, "MATH-1105": 3.0, "SS-1106": 2.0, "CSE-1111": 1.5, "EEE-1113": 1.5, "CHE-1114": 1.5,
    // Semester 2
    "CSE-1201": 3.0, "CSE-1202": 3.0, "PHY-1203": 3.0, "MATH-1204": 3.0, "ENG-1205": 2.0, "CSE-1211": 3.0, "CSE-1212": 1.5, "PHY-1213": 1.5, "ENG-1215": 1.5,
    // Semester 3
    "CSE-2101": 3.0, "CSE-2102": 3.0, "CSE-2103": 3.0, "EEE-2104": 3.0, "MATH-2105": 3.0, "SS-2106": 2.0, "CSE-2111": 1.5, "CSE-2112": 1.5, "CSE-2113": 1.5, "EEE-2114": 0.75,
    // Semester 4
    "CSE-2201": 3.0, "CSE-2202": 3.0, "CSE-2203": 3.0, "CSE-2204": 3.0, "CSE-2205": 2.0, "CSE-2211": 1.5, "CSE-2212": 1.5, "CSE-2213": 0.75, "CSE-2216": 1.5,
    // Semester 5
    "CSE-3101": 3.0, "CSE-3102": 3.0, "CSE-3103": 3.0, "CSE-3104": 3.0, "MATH-3105": 3.0, "CSE-3111": 1.5, "CSE-3112": 0.75, "CSE-3113": 1.5, "CSE-3116": 0.75,
    // Semester 6
    "CSE-3201": 3.0, "CSE-3202": 3.0, "CSE-3203": 3.0, "CSE-3204": 3.0, "STAT-3205": 3.0, "CSE-3211": 1.5, "CSE-3212": 0.75, "CSE-3216": 1.5, "ENG-3217": 0.75,
    // Semester 7
    "CSE-4101": 3.0, "CSE-4102": 3.0, "SS-4103": 2.0, "CSE-4111": 1.5, "CSE-4113": 1.5, "CSE-4114": 2.0,
    // Semester 8
    "ECO-4201": 2.0, "CSE-4202": 2.0, "SS-4203": 2.0, "CSE-4214": 4.0,

    // Option I
    "CSE-4121": 3.0, "CSE-4123": 3.0, "CSE-4125": 3.0, "CSE-4127": 3.0, "CSE-4131": 3.0, "CSE-4133": 3.0, "CSE-4135": 3.0, "CSE-4137": 3.0, "CSE-4139": 3.0,
    // Option II
    "CSE-4122": 3.0, "CSE-4124": 3.0, "CSE-4126": 3.0, "CSE-4128": 3.0, "CSE-4130": 3.0, "CSE-4132": 3.0, "CSE-4134": 3.0, "CSE-4136": 3.0, "CSE-4140": 3.0,
    // Option III
    "CSE-4221": 3.0, "CSE-4223": 3.0, "CSE-4225": 3.0, "CSE-4227": 3.0, "CSE-4229": 3.0, "CSE-4231": 3.0, "CSE-4233": 3.0, "CSE-4235": 3.0, "CSE-4237": 3.0, "CSE-4239": 3.0,
    // Option IV
    "CSE-4222": 3.0, "CSE-4224": 3.0, "CSE-4226": 3.0, "CSE-4228": 3.0, "CSE-4230": 3.0, "CSE-4232": 3.0, "CSE-4234": 3.0, "CSE-4236": 3.0, "CSE-4238": 3.0, "CSE-4240": 3.0, "CSE-4242": 3.0, "CSE-4244": 3.0, "CSE-4246": 3.0,
    "CSE-4155": 1.5, // Introduction to Machine Learning Lab
  };

  static Map<String, double> _loadedCredits = {};
  static Map<String, String> _loadedIds = {};

  /// Preloads subject details from local cache, and optionally syncs from Supabase if online
  static Future<void> init() async {
    try {
      // 1. Try to load from SQLite cache first
      final cachedStr = await DatabaseHelper.instance.getCache('subject_information');
      if (cachedStr != null) {
        final Map<String, dynamic> decoded = json.decode(cachedStr);
        _loadedCredits = decoded.map((key, value) => MapEntry(key, (value['credits'] as num).toDouble()));
        _loadedIds = decoded.map((key, value) => MapEntry(key, value['id'].toString()));
        debugPrint('Loaded ${_loadedCredits.length} subject details from SQLite cache.');
      }
      
      // 2. Fetch from Supabase in the background if online
      final isOnline = await ConnectivityService.hasInternet();
      if (isOnline) {
        final SupabaseClient client = Supabase.instance.client;
        final response = await client
            .from('subject_information')
            .select('id, code, credits');
        
        final Map<String, Map<String, dynamic>> cacheData = {};
        final Map<String, double> fetchedCredits = {};
        final Map<String, String> fetchedIds = {};

        for (var row in response) {
          final String id = row['id'] ?? '';
          final String code = row['code'] ?? '';
          final double credits = (row['credits'] as num?)?.toDouble() ?? 3.0;
          if (code.isNotEmpty) {
            final cleanCode = code.toUpperCase().trim();
            fetchedCredits[cleanCode] = credits;
            fetchedIds[cleanCode] = id;
            cacheData[cleanCode] = {
              'id': id,
              'credits': credits,
            };
          }
        }

        if (cacheData.isNotEmpty) {
          _loadedCredits = fetchedCredits;
          _loadedIds = fetchedIds;
          // Save to SQLite cache
          await DatabaseHelper.instance.saveCache('subject_information', json.encode(cacheData));
          debugPrint('Synced ${cacheData.length} subject details from Supabase.');
        }
      }
    } catch (e) {
      debugPrint('Error initializing SubjectInformation: $e');
    }
  }

  /// Get credits for a subject code
  static double getCredits(String code) {
    final cleanCode = code.toUpperCase().replaceAll(' ', '-').trim();
    
    // First try database-loaded credits
    if (_loadedCredits.containsKey(cleanCode)) {
      return _loadedCredits[cleanCode]!;
    }
    
    // Fall back to hardcoded fallback credits
    if (_fallbackCredits.containsKey(cleanCode)) {
      return _fallbackCredits[cleanCode]!;
    }

    // Heuristics for unknown courses
    if (cleanCode.contains('LAB') || 
        cleanCode.contains('PRACTICAL') || 
        cleanCode.endsWith('LAB') ||
        cleanCode.contains('PROJECT') || 
        cleanCode.contains('SEMINAR')) {
      if (cleanCode.contains('LAB')) {
        return 1.5;
      }
      if (cleanCode.contains('PROJECT')) {
        return 2.0;
      }
    }
    
    return 3.0;
  }

  /// Get database ID for a subject code
  static String? getSubjectId(String code) {
    final cleanCode = code.toUpperCase().replaceAll(' ', '-').trim();
    return _loadedIds[cleanCode];
  }

  /// Safe parsing of letter grades to grade points
  static double parseGradeToPoint(String grade) {
    final cleanGrade = grade.toUpperCase().trim();
    if (cleanGrade == 'A+') return 4.00;
    if (cleanGrade == 'A') return 3.75;
    if (cleanGrade == 'A-') return 3.50;
    if (cleanGrade == 'B+') return 3.25;
    if (cleanGrade == 'B') return 3.00;
    if (cleanGrade == 'B-') return 2.75;
    if (cleanGrade == 'C+') return 2.50;
    if (cleanGrade == 'C') return 2.25;
    if (cleanGrade == 'D') return 2.00;
    return 0.00;
  }
}
