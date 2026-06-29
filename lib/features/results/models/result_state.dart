
import '../../../core/utils/subject_information.dart';

class SubjectResult {
  final String code;
  final String name;
  final String grade;
  final String point;
  final double credits;
  // Whether this subject was part of an improvement exam result
  final bool isImproved;

  SubjectResult({
    required this.code,
    required this.name,
    required this.grade,
    required this.point,
    this.credits = 3.0,
    this.isImproved = false,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    final subInfo = json['subject_information'] as Map<String, dynamic>?;
    final codeVal = subInfo?['code'] ?? json['subject_code'] ?? json['code'] ?? '';
    final nameVal = subInfo?['subject_name'] ?? json['subject_name'] ?? json['name'] ?? '';
    
    double creditsVal = 3.0;
    if (subInfo?['credits'] != null) {
      creditsVal = (subInfo!['credits'] as num).toDouble();
    } else if (json['credits'] != null) {
      creditsVal = (json['credits'] as num).toDouble();
    } else {
      creditsVal = SubjectInformation.getCredits(codeVal);
    }
    
    return SubjectResult(
      code: codeVal,
      name: nameVal,
      grade: json['grade'] ?? '',
      point: json['point']?.toString() ?? '',
      credits: creditsVal,
      isImproved: json['is_improved'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_code': code,
      'subject_name': name,
      'grade': grade,
      'point': point,
      'credits': credits,
      'is_improved': isImproved,
    };
  }

  SubjectResult copyWith({
    String? code,
    String? name,
    String? grade,
    String? point,
    double? credits,
    bool? isImproved,
  }) {
    return SubjectResult(
      code: code ?? this.code,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      point: point ?? this.point,
      credits: credits ?? this.credits,
      isImproved: isImproved ?? this.isImproved,
    );
  }
}

class ExamResult {
  final String id;
  final String regNo;
  final String examId;
  final String examName;
  final String gpa;
  final String cgpa;
  final List<SubjectResult> subjects;
  final int? semester;
  /// True if this is an improvement/backlog exam result
  final bool isImprovement;
  /// GPA calculated from subject grades (used when official gpa is null for improvement results)
  final double? calculatedGpa;
  /// Running effective CGPA for this semester after applying improvements to all prior semesters.
  /// Computed by ResultService.recalculateEffectiveCgpa and stored in Supabase.
  final double? effectiveCgpa;
  /// Effective semester GPA after replacing main subjects with improvement subjects.
  /// Computed by ResultService.recalculateEffectiveCgpa and stored in Supabase.
  final double? storedEffectiveGpa;

  ExamResult({
    required this.id,
    required this.regNo,
    required this.examId,
    required this.examName,
    required this.gpa,
    required this.cgpa,
    required this.subjects,
    this.semester,
    this.isImprovement = false,
    this.calculatedGpa,
    this.effectiveCgpa,
    this.storedEffectiveGpa,
  });

  /// The effective GPA to use for chart plotting:
  /// - For main results: stored effective_gpa (if computed), else official gpa
  /// - For improvement results: calculatedGpa (since official gpa is null)
  double? get effectiveGpa {
    if (storedEffectiveGpa != null && storedEffectiveGpa! > 0) return storedEffectiveGpa;
    final official = double.tryParse(gpa);
    if (official != null && official > 0) return official;
    return calculatedGpa;
  }

  factory ExamResult.fromDB(Map<String, dynamic> json, List<SubjectResult> subjects) {
    final examIdData = json['DUCMC_exams_id'];
    int? semVal;
    if (examIdData is Map) {
      semVal = examIdData['semester'] as int?;
    } else if (examIdData is List && examIdData.isNotEmpty) {
      semVal = examIdData.first['semester'] as int?;
    }
    semVal ??= json['semester'] as int?;

    final resultType = json['result_type']?.toString() ?? 'main';
    final calculatedGpaRaw = json['calculated_gpa'];
    double? calculatedGpaVal;
    if (calculatedGpaRaw != null) {
      calculatedGpaVal = (calculatedGpaRaw as num?)?.toDouble();
    }
    final effectiveCgpaRaw = json['effective_cgpa'];
    double? effectiveCgpaVal;
    if (effectiveCgpaRaw != null) {
      effectiveCgpaVal = (effectiveCgpaRaw as num?)?.toDouble();
    }
    final effectiveGpaRaw = json['effective_gpa'];
    double? effectiveGpaVal;
    if (effectiveGpaRaw != null) {
      effectiveGpaVal = (effectiveGpaRaw as num?)?.toDouble();
    }

    return ExamResult(
      id: json['id'] ?? '',
      regNo: json['reg_no'] ?? '',
      examId: json['exam_id'] ?? '',
      examName: json['exam_name'] ?? 'Exam ${json['exam_id']}',
      gpa: json['gpa']?.toString() ?? '',
      cgpa: json['cgpa']?.toString() ?? '',
      subjects: subjects,
      semester: semVal,
      isImprovement: resultType == 'improvement',
      calculatedGpa: calculatedGpaVal,
      effectiveCgpa: effectiveCgpaVal,
      storedEffectiveGpa: effectiveGpaVal,
    );
  }

  // Legacy support for JSON-based results (if any remain)
  factory ExamResult.fromJson(Map<String, dynamic> json, String examName) {
    final subjectsList = json['subjects'] as List? ?? [];
    return ExamResult(
      id: json['id'] ?? '',
      regNo: json['reg_no'] ?? '',
      examId: json['exam_id'] ?? '',
      examName: examName,
      gpa: json['gpa']?.toString() ?? '',
      cgpa: json['cgpa']?.toString() ?? '',
      subjects: subjectsList.map((s) => SubjectResult.fromJson(s)).toList(),
      semester: json['semester'] as int?,
      isImprovement: json['result_type'] == 'improvement',
      calculatedGpa: (json['calculated_gpa'] as num?)?.toDouble(),
      effectiveCgpa: (json['effective_cgpa'] as num?)?.toDouble(),
      storedEffectiveGpa: (json['effective_gpa'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reg_no': regNo,
      'exam_id': examId,
      'exam_name': examName,
      'gpa': gpa,
      'cgpa': cgpa,
      'semester': semester,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'result_type': isImprovement ? 'improvement' : 'main',
      'calculated_gpa': calculatedGpa,
      'effective_cgpa': effectiveCgpa,
      'effective_gpa': storedEffectiveGpa,
    };
  }

  factory ExamResult.fromLocalJson(Map<String, dynamic> json) {
    final subjectsList = json['subjects'] as List? ?? [];
    return ExamResult(
      id: json['id'] ?? '',
      regNo: json['reg_no'] ?? '',
      examId: json['exam_id'] ?? '',
      examName: json['exam_name'] ?? '',
      gpa: json['gpa']?.toString() ?? '',
      cgpa: json['cgpa']?.toString() ?? '',
      subjects: subjectsList.map((s) => SubjectResult.fromJson(s as Map<String, dynamic>)).toList(),
      semester: json['semester'] as int?,
      isImprovement: json['result_type'] == 'improvement',
      calculatedGpa: (json['calculated_gpa'] as num?)?.toDouble(),
      effectiveCgpa: (json['effective_cgpa'] as num?)?.toDouble(),
    );
  }
}

class DucmcExam {
  final String examId;
  final String examName;

  DucmcExam({required this.examId, required this.examName});

  factory DucmcExam.fromJson(Map<String, dynamic> json) {
    return DucmcExam(
      examId: json['exam_id'].toString(),
      examName: json['exam_name'] ?? 'Unknown Exam',
    );
  }
}
