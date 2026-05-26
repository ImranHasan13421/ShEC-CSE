import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/committee_permission.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/services/connectivity_service.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';

class PermissionsService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Global reactive permission state for the currently logged-in user
  static final ValueNotifier<CommitteePermission?> currentPermissions = ValueNotifier(null);

  /// Synchronously and asynchronously loads permissions for the currently logged-in user.
  static Future<void> loadCurrentPermissions(ProfileData profile) async {
    if (profile.id.isEmpty) {
      currentPermissions.value = null;
      return;
    }

    if (profile.role == UserRole.superUser ||
        profile.designation == 'President' ||
        profile.designation == 'Vice President') {
      currentPermissions.value = CommitteePermission.fullAdmin(profile.id);
      debugPrint('Superuser/President permissions loaded: full access');
      return;
    }

    if (profile.role == UserRole.committeeMember) {
      try {
        final perm = await fetchUserPermissions(profile.id);
        currentPermissions.value = perm;
        debugPrint('Committee member permissions loaded for ${profile.name}');
      } catch (e) {
        debugPrint('Error loading committee permissions: $e');
        currentPermissions.value = CommitteePermission.viewOnly(profile.id);
      }
      return;
    }

    currentPermissions.value = null;
    debugPrint('Student/Member permissions loaded: no administrative access');
  }

  /// Fetches all permissions for committee members. Caches in SQLite if online.
  static Future<List<CommitteePermission>> fetchAllPermissions() async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      final cachedStr = await DatabaseHelper.instance.getCache('committee_permissions');
      if (cachedStr != null) {
        try {
          final List decoded = json.decode(cachedStr);
          debugPrint('Successfully loaded committee permissions from SQLite.');
          return decoded.map((e) => CommitteePermission.fromMap(e as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('Error deserializing cached permissions: $e');
        }
      }
      return [];
    }

    try {
      final response = await _client.from('committee_permissions').select();
      final List<CommitteePermission> list = (response as List)
          .map((e) => CommitteePermission.fromMap(e as Map<String, dynamic>))
          .toList();

      // Cache
      await DatabaseHelper.instance.saveCache('committee_permissions', json.encode(response));

      return list;
    } catch (e) {
      debugPrint('Error fetching committee permissions: $e');
      rethrow;
    }
  }

  /// Fetches permissions for a specific user, defaulting to all false if not found.
  static Future<CommitteePermission> fetchUserPermissions(String userId) async {
    final list = await fetchAllPermissions();
    return list.firstWhere(
      (p) => p.userId == userId,
      orElse: () => CommitteePermission(userId: userId),
    );
  }

  /// Updates or inserts permissions for a user in Supabase.
  static Future<void> updatePermissions(CommitteePermission permission) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to modify permissions.');
      throw Exception('Network connection required');
    }

    try {
      // Upsert into Supabase
      await _client.from('committee_permissions').upsert(permission.toMap());

      // Refresh online cache and save to SQLite in the background
      final freshResponse = await _client.from('committee_permissions').select();
      await DatabaseHelper.instance.saveCache('committee_permissions', json.encode(freshResponse));

      // Sync local global state immediately if the user is modifying their own permissions
      if (permission.userId == currentProfile.value.id) {
        currentPermissions.value = permission;
      }
    } catch (e) {
      debugPrint('Error updating permissions: $e');
      rethrow;
    }
  }
}
