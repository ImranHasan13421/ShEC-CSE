import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile_state.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  static void initializeAuthListener() {
    _client.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      if (session != null) {
        await fetchCurrentUserProfile();
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
    });
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> fetchCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user != null) {
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

        currentProfile.value = ProfileData(
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
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }
    }
  }

  static Future<List<ProfileData>> fetchAllMembers() async {
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
        email: '', 
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
    return members;
  }

  static Future<void> updateUserRole(String userId, UserRole newRole, {String? designation}) async {
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
    await _client.from('profiles').update({'is_approved': true}).eq('id', userId);
  }

  static Future<void> deleteUser(String userId) async {
    try {
      // 1. Fetch profile to get image path
      final data = await _client.from('profiles').select('profile_pic').eq('id', userId).single();
      final String? profilePic = data['profile_pic'];

      // 2. Delete image from storage
      if (profilePic != null && profilePic.isNotEmpty) {
        final uri = Uri.parse(profilePic);
        final fileName = uri.pathSegments.last;
        await _client.storage.from('profile_pictures').remove([fileName]);
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
