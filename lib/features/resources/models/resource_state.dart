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
}

// Global Notifier for Resources
final ValueNotifier<List<ResourceItem>> resourceState = ValueNotifier([
  ResourceItem(id: 'r1', name: 'Semester Final Question.pdf', size: '1.2 MB', date: 'Added 2 months ago', session: '20-21'),
  ResourceItem(id: 'r2', name: 'Semester Final All Course Notes.pdf', size: '36.6 MB', date: 'Added 3 months ago', session: '20-21'),
]);
