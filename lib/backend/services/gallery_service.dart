import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/gallery/models/gallery_state.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/storage_service.dart';


class GalleryService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> fetchGalleryItems({bool forceRefresh = false}) async {
    if (!forceRefresh && !CacheService.isStale(CacheKeys.gallery)) return;
    
    final isAdmin = currentProfile.value.role != UserRole.student;
    
    var query = _client.from('gallery').select();
    if (!isAdmin) {
      query = query.eq('is_approved', true).eq('is_visible', true);
    }
    
    final response = await query.order('created_at', ascending: false);
    galleryState.value = (response as List).map((r) => GalleryItem.fromJson(r)).toList();
    CacheService.markFresh(CacheKeys.gallery);
  }

  static Future<void> addGalleryItemToDB(GalleryItem item) async {
    final profile = currentProfile.value;
    final isSuperUser = profile.designation == 'President' || profile.designation == 'Vice President';
    
    final data = item.toJson();
    data['is_approved'] = isSuperUser;
    data['is_visible'] = true;
    data['created_by_name'] = profile.name;
    
    final response = await _client
        .from('gallery')
        .insert(data)
        .select()
        .single();

    final newItem = GalleryItem.fromJson(response);
    galleryState.value = List.from(galleryState.value)..insert(0, newItem);
    CacheService.invalidate(CacheKeys.gallery);
  }

  static Future<void> updateGalleryItemInDB(GalleryItem item) async {
    final data = item.toJson();
    data.remove('is_approved'); // Don't overwrite existing status on normal edit
    
    await _client
        .from('gallery')
        .update(data)
        .eq('id', item.id);
        
    CacheService.invalidate(CacheKeys.gallery);
    fetchGalleryItems(forceRefresh: true);
  }

  static Future<void> approveGalleryItem(String id) async {
    await _client.from('gallery').update({'is_approved': true}).eq('id', id);
    CacheService.invalidate(CacheKeys.gallery);
    fetchGalleryItems(forceRefresh: true);
  }

  static Future<void> toggleGalleryVisibility(String id, bool isVisible) async {
    await _client.from('gallery').update({'is_visible': isVisible}).eq('id', id);
    CacheService.invalidate(CacheKeys.gallery);
    fetchGalleryItems(forceRefresh: true);
  }

  static Future<void> deleteGalleryItemFromDB(GalleryItem item) async {
    try {
      // 1. Delete image from storage
      if (item.imagePath.isNotEmpty) {
        await StorageService.deleteFile(item.imagePath);
      }

      // 2. Delete from DB
      await _client.from('gallery').delete().eq('id', item.id);

      galleryState.value = List.from(galleryState.value)..removeWhere((i) => i.id == item.id);
      CacheService.invalidate(CacheKeys.gallery);
    } catch (e) {
      debugPrint('Error deleting gallery item: $e');
      rethrow;
    }
  }

  static Future<String?> uploadImage(File file) async {
    return StorageService.uploadFile(file, 'gallery_images');
  }
}
