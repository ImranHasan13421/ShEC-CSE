import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile_state.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/database_helper.dart';
import '../../core/services/connectivity_service.dart';
import 'package:ShEC_CSE/features/permissions/services/permissions_service.dart';
import 'notification_service.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  static void initializeAuthListener() {
    _client.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      if (session != null) {
        await fetchCurrentUserProfile();
        await NotificationService.syncFCMToken();
      }
    });
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String batch,
    required String session,
    required String duReg,
    required String phone,
    String? profilePic,
    String universityId = '',
    String classRoll = '',
  }) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to create an account.');
      throw Exception('Network connection required');
    }

    // Check if email already exists in profiles
    final emailCheck = await _client
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (emailCheck != null) {
      throw Exception('This email is already registered.');
    }

    // Check if DU Registration number already exists in profiles
    final duRegCheck = await _client
        .from('profiles')
        .select('id')
        .eq('du_reg', duReg)
        .maybeSingle();
    if (duRegCheck != null) {
      throw Exception('This DU Registration number is already registered.');
    }

    final AuthResponse res = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final User? user = res.user;
    if (user == null) {
      throw Exception('Failed to create user account.');
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'first_name': firstName,
      'last_name': lastName,
      'university_id': universityId,
      'class_roll': classRoll,
      'batch': batch,
      'session': session,
      'du_reg': duReg,
      'phone': phone,
      'profile_pic': profilePic,
      'role': 'member',
      'is_alumni': false,
      'email': email,
    });
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to log in.');
      throw Exception('Network connection required');
    }
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to log out.');
      throw Exception('Network connection required');
    }
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        await _client.from('profiles').update({'fcm_token': null}).eq('id', user.id);
      } catch (e) {
        debugPrint('Error clearing FCM token on sign out: $e');
      }
    }
    await _client.auth.signOut();
    PermissionsService.currentPermissions.value = null;
  }

  static Future<void> fetchCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      // Offline: Try loading from local SQLite database cache
      final cachedProfileStr = await DatabaseHelper.instance.getCache('current_profile');
      if (cachedProfileStr != null) {
        try {
          final decoded = json.decode(cachedProfileStr);
          currentProfile.value = ProfileData.fromJson(decoded);
          await PermissionsService.loadCurrentPermissions(currentProfile.value);
          debugPrint('Successfully loaded user profile from local SQLite database.');
          return;
        } catch (e) {
          debugPrint('Error deserializing cached profile: $e');
        }
      }
    }

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      UserRole parsedRole;
      switch (data['role']) {
        case 'superuser': parsedRole = UserRole.superUser; break;
        case 'committee': parsedRole = UserRole.committeeMember; break;
        default: parsedRole = UserRole.student; break;
      }

      final profile = ProfileData(
        id: data['id'],
        firstName: data['first_name'] ?? '',
        lastName: data['last_name'] ?? '',
        name: '${data['first_name']} ${data['last_name']}',
        email: user.email ?? '',
        universityId: data['university_id'] ?? '',
        classRoll: data['class_roll'] ?? '',
        duRegNo: data['du_reg'] ?? '',
        session: data['session'] ?? '',
        batch: data['batch'] ?? '',
        phone: data['phone'] ?? '',
        imagePath: data['profile_pic'],
        role: parsedRole,
        designation: data['designation'] ?? 'Student',
        isApproved: data['is_approved'] ?? false,
        isAlumni: data['is_alumni'] ?? false,
      );

      currentProfile.value = profile;
      await PermissionsService.loadCurrentPermissions(profile);

      // Cache this profile string in SQLite
      await DatabaseHelper.instance.saveCache(
        'current_profile',
        json.encode(profile.toJson()),
      );
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      
      // If token has expired or is invalid, force clear caches, sign out, and rethrow to redirect to login
      if (e is PostgrestException && (e.message.contains('JWT expired') || e.code == 'PGRST303' || e.code == '401')) {
        debugPrint('Session JWT has expired. Forcing sign out...');
        try {
          await DatabaseHelper.instance.clearCache('current_profile');
          await DatabaseHelper.instance.clearCache('all_members');
          final user = _client.auth.currentUser;
          if (user != null) {
            await _client.from('profiles').update({'fcm_token': null}).eq('id', user.id);
          }
          await _client.auth.signOut();
        } catch (_) {}
        currentProfile.value = ProfileData(name: 'Guest', email: '', duRegNo: '', session: '');
        PermissionsService.currentPermissions.value = null;
        throw Exception('JWT expired');
      }

      // If network call failed, attempt to fall back to SQLite cache as a last resort
      final cachedProfileStr = await DatabaseHelper.instance.getCache('current_profile');
      if (cachedProfileStr != null) {
        try {
          final decoded = json.decode(cachedProfileStr);
          currentProfile.value = ProfileData.fromJson(decoded);
          await PermissionsService.loadCurrentPermissions(currentProfile.value);
        } catch (_) {}
      }
    }
  }

  static Future<List<ProfileData>> fetchAllMembers() async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      final cachedMembersStr = await DatabaseHelper.instance.getCache('all_members');
      if (cachedMembersStr != null) {
        try {
          final List decoded = json.decode(cachedMembersStr);
          return decoded.map((m) => ProfileData.fromJson(m)).toList();
        } catch (e) {
          debugPrint('Error loading cached members: $e');
        }
      }
      return [];
    }

    final response = await _client
        .from('profiles')
        .select()
        .eq('is_alumni', false)
        .order('created_at', ascending: false);
    
    List<ProfileData> members = [];
    for (var data in response) {
      UserRole parsedRole;
      switch (data['role']) {
        case 'superuser': parsedRole = UserRole.superUser; break;
        case 'committee': parsedRole = UserRole.committeeMember; break;
        default: parsedRole = UserRole.student; break;
      }

      members.add(ProfileData(
        id: data['id'],
        firstName: data['first_name'] ?? '',
        lastName: data['last_name'] ?? '',
        name: '${data['first_name']} ${data['last_name']}',
        email: data['email'] ?? '', 
        universityId: data['university_id'] ?? '',
        classRoll: data['class_roll'] ?? '',
        duRegNo: data['du_reg'] ?? '',
        session: data['session'] ?? '',
        batch: data['batch'] ?? '',
        phone: data['phone'] ?? '',
        imagePath: data['profile_pic'],
        role: parsedRole,
        designation: data['designation'] ?? 'Student',
        isApproved: data['is_approved'] ?? false,
        isAlumni: data['is_alumni'] ?? false,
      ));
    }

    // Cache the complete members list in SQLite
    await DatabaseHelper.instance.saveCache(
      'all_members',
      json.encode(members.map((m) => m.toJson()).toList()),
    );

    return members;
  }

  static Future<void> updateUserRole(String userId, UserRole newRole, {String? designation}) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to modify member privileges.');
      throw Exception('Network connection required');
    }

    String roleString;
    switch (newRole) {
      case UserRole.superUser: roleString = 'superuser'; break;
      case UserRole.committeeMember: roleString = 'committee'; break;
      default: roleString = 'member'; break;
    }

    final Map<String, dynamic> updateData = {'role': roleString};
    if (designation != null) updateData['designation'] = designation;

    await _client.from('profiles').update(updateData).eq('id', userId);
  }

  static Future<void> updateProfile(ProfileData profile) async {
    await updateAnyProfile(profile);
    await fetchCurrentUserProfile();
  }

  static Future<void> updateAnyProfile(ProfileData profile) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to update profile details.');
      throw Exception('Network connection required');
    }

    await _client.from('profiles').update({
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'university_id': profile.universityId,
      'class_roll': profile.classRoll,
      'batch': profile.batch,
      'session': profile.session,
      'phone': profile.phone,
      'profile_pic': profile.imagePath, 
      'du_reg': profile.duRegNo,
    }).eq('id', profile.id);
  }

  static Future<void> approveUser(String userId) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to approve members.');
      throw Exception('Network connection required');
    }
    await _client.from('profiles').update({'is_approved': true}).eq('id', userId);
  }

  static Future<void> deleteUser(String userId) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to delete accounts.');
      throw Exception('Network connection required');
    }
    try {
      // 1. Fetch profile to get image path
      final data = await _client.from('profiles').select('profile_pic').eq('id', userId).single();
      final String? profilePic = data['profile_pic'];

      // 2. Delete image from storage
      if (profilePic != null && profilePic.isNotEmpty) {
        await StorageService.deleteFile(profilePic);
      }

      // 3. Delete from DB
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Error deleting user and profile pic: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSessions() async {
    try {
      final data = await _client.from('DUCMC_sessions_id').select().order('session', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Sessions fetch error: $e');
      return [];
    }
  }

  static Future<void> moveToAlumni(ProfileData member) async {
    final isOnline = await ConnectivityService.hasInternet();
    if (!isOnline) {
      ConnectivityService.showNoInternetToast(message: 'Internet connection required to transfer member to Alumni directory.');
      throw Exception('Network connection required');
    }
    await _client.from('profiles').update({
      'is_alumni': true,
      'role': 'member',
      'designation': 'Alumnus',
    }).eq('id', member.id);

    await _client.from('alumni').insert({
      'user_id': member.id,
      'name': member.name,
      'role': 'alumni',
      'designation': 'Alumnus',
      'email': member.email,
      'phone': member.phone,
      'image_path': member.imagePath,
      'batch': member.batch,
      'session': member.session,
      'is_approved': true,
      'is_visible': true,
      'profile_id': member.id,
    });
  }
}
