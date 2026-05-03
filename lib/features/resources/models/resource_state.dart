import 'package:flutter/material.dart';

class ResourceItem {
  final String id;
  final String name;
  final String size;
  final String date;
  final String session;

  ResourceItem({
    required this.id,
    required this.name,
    required this.size,
    required this.date,
    required this.session,
  });

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    return ResourceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as String,
      date: json['date'] as String,
      session: json['session'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'date': date,
      'session': session,
    };
  }
}

// Global Notifier for Resources
final ValueNotifier<List<ResourceItem>> resourceState = ValueNotifier([]);

