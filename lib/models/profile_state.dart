// lib/models/profile_state.dart
import 'package:flutter/material.dart';

class ProfileData {
  final String name;
  final String email;
  final String roll;
  final String studentId;
  final String duRegNo;
  final String session;
  final String? imagePath;

  ProfileData({
    required this.name,
    required this.email,
    required this.roll,
    required this.studentId,
    required this.duRegNo,
    required this.session,
    this.imagePath,
  });

  ProfileData copyWith({
    String? name,
    String? email,
    String? roll,
    String? studentId,
    String? duRegNo,
    String? session,
    String? imagePath,
  }) {
    return ProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      roll: roll ?? this.roll,
      studentId: studentId ?? this.studentId,
      duRegNo: duRegNo ?? this.duRegNo,
      session: session ?? this.session,
      imagePath: imagePath ?? this.imagePath,
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
  ),
);