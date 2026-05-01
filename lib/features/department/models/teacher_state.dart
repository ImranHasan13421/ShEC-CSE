import 'package:flutter/material.dart';

class TeacherContact {
  final String id;
  final String name;
  final String designation;
  final String phone;
  final String email;
   final String imagePath;
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
    this.isApproved = false,
    this.isVisible = true,
    this.createdByName = '',
  });

  factory TeacherContact.fromJson(Map<String, dynamic> json) {
    return TeacherContact(
      id: json['id'] as String,
      name: json['name'] as String,
      designation: json['designation'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
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
      'is_approved': isApproved,
      'is_visible': isVisible,
      'created_by_name': createdByName,
    };
  }
}

// Global Notifier
final ValueNotifier<List<TeacherContact>> teachersState = ValueNotifier([]);
