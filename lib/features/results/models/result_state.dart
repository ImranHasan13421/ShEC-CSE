
import '../../../core/utils/subject_information.dart';

class SubjectResult {
  final String code;
  final String name;
  final String grade;
  final String point;
  final double credits;

  SubjectResult({
    required this.code,
    required this.name,
    required this.grade,
    required this.point,
    this.credits = 3.0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_code': code,
      'subject_name': name,
      'grade': grade,
      'point': point,
      'credits': credits,
    };
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

  ExamResult({
    required this.id,
    required this.regNo,
    required this.examId,
    required this.examName,
    required this.gpa,
    required this.cgpa,
    required this.subjects,
    this.semester,
  });

  factory ExamResult.fromDB(Map<String, dynamic> json, List<SubjectResult> subjects) {
    final examIdData = json['DUCMC_exams_id'];
    int? semVal;
    if (examIdData is Map) {
      semVal = examIdData['semester'] as int?;
    } else if (examIdData is List && examIdData.isNotEmpty) {
      semVal = examIdData.first['semester'] as int?;
    }
    semVal ??= json['semester'] as int?;

    return ExamResult(
      id: json['id'] ?? '',
      regNo: json['reg_no'] ?? '',
      examId: json['exam_id'] ?? '',
      examName: json['exam_name'] ?? 'Exam ${json['exam_id']}',
      gpa: json['gpa']?.toString() ?? '',
      cgpa: json['cgpa']?.toString() ?? '',
      subjects: subjects,
      semester: semVal,
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


