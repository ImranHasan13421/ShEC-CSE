import 'package:flutter/material.dart';

class SubjectResult {
  final String code;
  final String name;
  final String grade;
  final String point;

  SubjectResult({
    required this.code,
    required this.name,
    required this.grade,
    required this.point,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      point: json['point'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'grade': grade,
      'point': point,
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

  ExamResult({
    required this.id,
    required this.regNo,
    required this.examId,
    required this.examName,
    required this.gpa,
    required this.cgpa,
    required this.subjects,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json, String examName) {
    final subjectsList = json['subjects'] as List? ?? [];
    return ExamResult(
      id: json['id'] ?? '',
      regNo: json['reg_no'] ?? '',
      examId: json['exam_id'] ?? '',
      examName: examName,
      gpa: json['gpa'] ?? '',
      cgpa: json['cgpa'] ?? '',
      subjects: subjectsList.map((s) => SubjectResult.fromJson(s)).toList(),
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

// Global state for results
final ValueNotifier<List<ExamResult>> studentResultsState = ValueNotifier([]);
final ValueNotifier<bool> isSyncingResults = ValueNotifier(false);
