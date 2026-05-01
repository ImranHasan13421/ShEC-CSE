import 'package:flutter/material.dart';

class TeacherContact {
  final String id;
  final String name;
  final String designation;
  final String phone;
  final String email;
  final String imagePath;
  final bool isApproved;

  TeacherContact({
    required this.id,
    required this.name,
    required this.designation,
    this.phone = '',
    this.email = '',
    this.imagePath = '',
    this.isApproved = false,
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
    };
  }
}

// Global Notifier
final ValueNotifier<List<TeacherContact>> teachersState = ValueNotifier([]);
