import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

Future<void> fetchResources() async {
  try {
    final response = await Supabase.instance.client
        .from('resources')
        .select()
        .order('created_at', ascending: false);

    final List<ResourceItem> resources = [];
    for (var row in response) {
      resources.add(ResourceItem.fromJson(row));
    }

    resourceState.value = resources;
  } catch (e) {
    debugPrint('Error fetching resources: $e');
  }
}

Future<void> addResourceToDB(ResourceItem item) async {
  try {
    final data = item.toJson();
    final response = await Supabase.instance.client
        .from('resources')
        .insert(data)
        .select()
        .single();

    final newItem = ResourceItem.fromJson(response);
    resourceState.value = List.from(resourceState.value)..insert(0, newItem);
  } catch (e) {
    debugPrint('Error adding resource: $e');
  }
}

Future<void> updateResourceInDB(ResourceItem item) async {
  try {
    final data = item.toJson();
    await Supabase.instance.client
        .from('resources')
        .update(data)
        .eq('id', item.id);
  } catch (e) {
    debugPrint('Error updating resource: $e');
  }
}

Future<void> deleteResourceFromDB(ResourceItem item) async {
  try {
    await Supabase.instance.client
        .from('resources')
        .delete()
        .eq('id', item.id);

    resourceState.value = List.from(resourceState.value)..removeWhere((i) => i.id == item.id);
  } catch (e) {
    debugPrint('Error deleting resource: $e');
  }
}
