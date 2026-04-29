import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/resources/models/resource_state.dart';

class ResourceService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchResources() async {
    final response = await _client
        .from('resources')
        .select()
        .order('created_at', ascending: false);

    final List<ResourceItem> resources = [];
    for (var row in response) {
      resources.add(ResourceItem.fromJson(row));
    }

    resourceState.value = resources;
  }

  static Future<void> addResourceToDB(ResourceItem item) async {
    final data = item.toJson();
    final response = await _client
        .from('resources')
        .insert(data)
        .select()
        .single();

    final newItem = ResourceItem.fromJson(response);
    resourceState.value = List.from(resourceState.value)..insert(0, newItem);
  }

  static Future<void> updateResourceInDB(ResourceItem item) async {
    final data = item.toJson();
    await _client
        .from('resources')
        .update(data)
        .eq('id', item.id);
  }

  static Future<void> deleteResourceFromDB(ResourceItem item) async {
    await _client
        .from('resources')
        .delete()
        .eq('id', item.id);

    resourceState.value = List.from(resourceState.value)..removeWhere((i) => i.id == item.id);
  }
}
