import 'package:flutter/material.dart';

class AlumniItem {
  final String id;
  final String? userId;
  final String name;
  final String role;
  final String designation;
  final String email;
  final String phone;
  final String imagePath;
  final String batch;
  final String session;
  final String passingYear;
  final String currentPosition;
  final String company;
  final List<String> areasOfExpertise;
  final bool isApproved;
  final bool isVisible;
  final String createdByName;

  AlumniItem({
    required this.id,
    this.userId,
    required this.name,
    this.role = '',
    this.designation = '',
    this.email = '',
    this.phone = '',
    this.imagePath = '',
    this.batch = '',
    this.session = '',
    this.passingYear = '',
    this.currentPosition = '',
    this.company = '',
    this.areasOfExpertise = const [],
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  factory AlumniItem.fromJson(Map<String, dynamic> json) {
    final expertiseRaw = json['areas_of_expertise'];
    final List<String> expertise;
    if (expertiseRaw is List) {
      expertise = expertiseRaw.map((e) => e.toString()).toList();
    } else {
      expertise = [];
    }

    return AlumniItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      role: json['role'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      batch: json['batch'] as String? ?? '',
      session: json['session'] as String? ?? '',
      passingYear: json['passing_year'] as String? ?? '',
      currentPosition: json['current_position'] as String? ?? '',
      company: json['company'] as String? ?? '',
      areasOfExpertise: expertise,
      isApproved: json['is_approved'] as bool? ?? false,
      isVisible: json['is_visible'] as bool? ?? true,
      createdByName: json['created_by_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'role': role,
      'designation': designation,
      'email': email,
      'phone': phone,
      'image_path': imagePath,
      'batch': batch,
      'session': session,
      'passing_year': passingYear,
      'current_position': currentPosition,
      'company': company,
      'areas_of_expertise': areasOfExpertise,
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }
}

// Global Notifier
final ValueNotifier<List<AlumniItem>> alumniState = ValueNotifier([]);
