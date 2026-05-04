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
  final String universityId;
  final String classRoll;
  final String duRegNo;
  final String session;
  final String batch;
  final String phone;
  final String? imagePath;
  final UserRole role;
  final String designation;
  final bool isApproved;
  final bool isAlumni;

  ProfileData({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    required this.name,
    required this.email,
    this.universityId = '',
    this.classRoll = '',
    required this.duRegNo,
    required this.session,
    this.batch = '',
    this.phone = '',
    this.imagePath,
    this.role = UserRole.student,
    this.designation = 'Student',
    this.isApproved = false,
    this.isAlumni = false,
  });

  // Combined Identifier replacing the old class_id
  String get studentFullId => universityId.isNotEmpty && classRoll.isNotEmpty 
    ? '$universityId | $classRoll' 
    : (universityId.isNotEmpty ? universityId : classRoll);

  ProfileData copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? name,
    String? email,
    String? universityId,
    String? classRoll,
    String? duRegNo,
    String? session,
    String? batch,
    String? phone,
    String? imagePath,
    UserRole? role,
    String? designation,
    bool? isApproved,
    bool? isAlumni,
  }) {
    return ProfileData(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      email: email ?? this.email,
      universityId: universityId ?? this.universityId,
      classRoll: classRoll ?? this.classRoll,
      duRegNo: duRegNo ?? this.duRegNo,
      session: session ?? this.session,
      batch: batch ?? this.batch,
      phone: phone ?? this.phone,
      imagePath: imagePath ?? this.imagePath,
      role: role ?? this.role,
      designation: designation ?? this.designation,
      isApproved: isApproved ?? this.isApproved,
      isAlumni: isAlumni ?? this.isAlumni,
    );
  }
}

final ValueNotifier<ProfileData> currentProfile = ValueNotifier(
  ProfileData(
    id: '',
    name: 'Guest',
    email: '',
    universityId: '',
    classRoll: '',
    duRegNo: '',
    session: '',
    batch: '',
    phone: '',
    role: UserRole.student,
    designation: 'Student',
    isApproved: false,
    isAlumni: false,
  ),
);