import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/resources/models/resource_state.dart';
import '../../core/services/cache_service.dart';

class ResourceService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchResources({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.resources)) return;

    final response = await _client
        .from('resources')
        .select()
        .order('created_at', ascending: false);

    final List<ResourceItem> resources = [];
    for (var row in response) {
      resources.add(ResourceItem.fromJson(row));
    }

    resourceState.value = resources;
    CacheService.markFresh(CacheKeys.resources);
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
    CacheService.invalidate(CacheKeys.resources);
  }

  static Future<void> updateResourceInDB(ResourceItem item) async {
    final data = item.toJson();
    await _client
        .from('resources')
        .update(data)
        .eq('id', item.id);
    CacheService.invalidate(CacheKeys.resources);
  }

  static Future<void> deleteResourceFromDB(ResourceItem item) async {
    await _client
        .from('resources')
        .delete()
        .eq('id', item.id);

    resourceState.value = List.from(resourceState.value)..removeWhere((i) => i.id == item.id);
    CacheService.invalidate(CacheKeys.resources);
  }
}
