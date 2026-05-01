import 'package:flutter/material.dart';

enum UserRole {
  student,
  committeeMember,
  superUser,
}

class ProfileData {
  final String id;
  final String firstName;
  final String lastName;
  final String name;
  final String email;
  final String roll; // Class ID
  final String studentId; // Class ID
  final String duRegNo;
  final String session;
  final String batch;
  final String phone;
  final String? imagePath;
  final UserRole role;
  final String designation;
  final bool isApproved;

  ProfileData({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    required this.name,
    required this.email,
    required this.roll,
    required this.studentId,
    required this.duRegNo,
    required this.session,
    this.batch = '',
    this.phone = '',
    this.imagePath,
    this.role = UserRole.student,
    this.designation = 'Student',
    this.isApproved = false,
  });

  ProfileData copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? name,
    String? email,
    String? roll,
    String? studentId,
    String? duRegNo,
    String? session,
    String? batch,
    String? phone,
    String? imagePath,
    UserRole? role,
    String? designation,
    bool? isApproved,
  }) {
    return ProfileData(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      email: email ?? this.email,
      roll: roll ?? this.roll,
      studentId: studentId ?? this.studentId,
      duRegNo: duRegNo ?? this.duRegNo,
      session: session ?? this.session,
      batch: batch ?? this.batch,
      phone: phone ?? this.phone,
      imagePath: imagePath ?? this.imagePath,
      role: role ?? this.role,
      designation: designation ?? this.designation,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

// Global Notifier initialized with empty data. Will be populated on login.
final ValueNotifier<ProfileData> currentProfile = ValueNotifier(
  ProfileData(
    id: '',
    name: 'Guest',
    email: '',
    roll: '',
    studentId: '',
    duRegNo: '',
    session: '',
    batch: '',
    phone: '',
    role: UserRole.student,
    designation: 'Student',
    isApproved: false,
  ),
);