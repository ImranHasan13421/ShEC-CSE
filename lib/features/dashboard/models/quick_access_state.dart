// lib/models/quick_access_state.dart
import 'package:flutter/material.dart';

class ShortcutItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const ShortcutItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

// The Master List of all available shortcuts in the app
final List<ShortcutItem> availableShortcuts = [
  const ShortcutItem(id: 'tab_notices', title: 'Notices Tab', icon: Icons.notifications, color: Colors.amber),
  const ShortcutItem(id: 'tab_messenger', title: 'Messenger Tab', icon: Icons.message, color: Colors.blue),
  const ShortcutItem(id: 'tab_jobs', title: 'Jobs Tab', icon: Icons.work, color: Colors.green),
  const ShortcutItem(id: 'tab_contests', title: 'Contests Tab', icon: Icons.emoji_events, color: Colors.redAccent),
  const ShortcutItem(id: 'cgpa_calc', title: 'CGPA Calculator', icon: Icons.calculate, color: Colors.purple),
  const ShortcutItem(id: 'res_main', title: 'All Resources', icon: Icons.folder_copy, color: Colors.indigo),

  // Specific Deep Link Examples
  const ShortcutItem(id: 'res_3_1_20', title: '3rd Yr Sem 1 (20-21)', icon: Icons.picture_as_pdf, color: Colors.teal),

  const ShortcutItem(id: 'dept_info', title: 'Department Info', icon: Icons.school, color: Colors.brown),
  const ShortcutItem(id: 'prog_club', title: 'Programming Club', icon: Icons.code, color: Colors.deepOrange),
];

// The Active List (The user's currently selected shortcuts)
// We initialize it with 4 default items
final ValueNotifier<List<ShortcutItem>> activeShortcuts = ValueNotifier([
  availableShortcuts[0], // Notices
  availableShortcuts[1], // Messenger
  availableShortcuts[4], // CGPA Calc
  availableShortcuts[5], // All Resources
]);