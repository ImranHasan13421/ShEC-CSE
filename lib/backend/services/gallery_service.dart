import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/gallery/models/gallery_state.dart';

class GalleryService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchGalleryItems() async {
    final response = await _client
        .from('gallery')
        .select()
        .order('created_at', ascending: false);

    final List<GalleryItem> items = [];
    for (var row in response) {
      items.add(GalleryItem.fromJson(row));
    }

    galleryState.value = items;
  }

  static Future<void> addGalleryItemToDB(GalleryItem item) async {
    final data = item.toJson();
    final response = await _client
        .from('gallery')
        .insert(data)
        .select()
        .single();

    final newItem = GalleryItem.fromJson(response);
    galleryState.value = List.from(galleryState.value)..insert(0, newItem);
  }

  static Future<void> updateGalleryItemInDB(GalleryItem item) async {
    final data = item.toJson();
    await _client
        .from('gallery')
        .update(data)
        .eq('id', item.id);
  }

  static Future<void> deleteGalleryItemFromDB(GalleryItem item) async {
    await _client
        .from('gallery')
        .delete()
        .eq('id', item.id);

    galleryState.value = List.from(galleryState.value)..removeWhere((i) => i.id == item.id);
  }
}
