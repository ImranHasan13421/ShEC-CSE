import 'package:flutter/material.dart';

class TeacherContact {
  final String id;
  final String name;
  final String designation; // e.g., Professor, Assistant Professor
  final String phone;
  final String email;
  final String imagePath;
  final String officeRoom;
  final String department;
  final String joinYear;
  final List<String> areasOfExpertise;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  TeacherContact({
    required this.id,
    required this.name,
    required this.designation,
    this.phone = '',
    this.email = '',
    this.imagePath = '',
    this.officeRoom = '',
    this.department = 'CSE',
    this.joinYear = '',
    this.areasOfExpertise = const [],
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  factory TeacherContact.fromJson(Map<String, dynamic> json) {
    final expertiseRaw = json['areas_of_expertise'];
    final List<String> expertise;
    if (expertiseRaw is List) {
      expertise = expertiseRaw.map((e) => e.toString()).toList();
    } else {
      expertise = [];
    }

    return TeacherContact(
      id: json['id'] as String,
      name: json['name'] as String,
      designation: json['designation'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      officeRoom: json['office_room'] as String? ?? '',
      department: json['department'] as String? ?? 'CSE',
      joinYear: json['join_year'] as String? ?? '',
      areasOfExpertise: expertise,
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'designation': designation,
      'phone': phone,
      'email': email,
      'image_path': imagePath,
      'office_room': officeRoom,
      'department': department,
      'join_year': joinYear,
      'areas_of_expertise': areasOfExpertise,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }
}

// Global Notifier
final ValueNotifier<List<TeacherContact>> teachersState = ValueNotifier([]);
