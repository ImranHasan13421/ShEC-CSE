import 'package:flutter/material.dart';

enum UserRole {
  student,
  committeeMember,
  admin,
}

class ProfileData {
  final String name;
  final String email;
  final String roll;
  final String studentId;
  final String duRegNo;
  final String session;
  final String? imagePath;
  final UserRole role;

  ProfileData({
    required this.name,
    required this.email,
    required this.roll,
    required this.studentId,
    required this.duRegNo,
    required this.session,
    this.imagePath,
    this.role = UserRole.student,
  });

  ProfileData copyWith({
    String? name,
    String? email,
    String? roll,
    String? studentId,
    String? duRegNo,
    String? session,
    String? imagePath,
    UserRole? role,
  }) {
    return ProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      roll: roll ?? this.roll,
      studentId: studentId ?? this.studentId,
      duRegNo: duRegNo ?? this.duRegNo,
      session: session ?? this.session,
      imagePath: imagePath ?? this.imagePath,
      role: role ?? this.role,
    );
  }
}

// Global Notifier initialized with placeholder data
final ValueNotifier<ProfileData> currentProfile = ValueNotifier(
  ProfileData(
    name: 'Imran',
    email: 'imran@student.shec.ac.bd',
    roll: '45',
    studentId: 'CSE-018-045',
    duRegNo: '2018314567',
    session: '2021-2022',
    role: UserRole.committeeMember, // Default to committee member for testing
  ),
);