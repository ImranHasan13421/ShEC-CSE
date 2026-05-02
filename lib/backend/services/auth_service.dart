import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/profile_state.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Listen to auth state changes to update currentProfile
  static void initializeAuthListener() {
    _client.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      if (session != null) {
        // User is logged in, fetch their profile
        await fetchCurrentUserProfile();
      }
    });
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String classId,
    required String batch,
    required String session,
    required String duReg,
    required String phone,
    String? profilePic,
    String universityId = '',
    String classRoll = '',
  }) async {
    // 1. Sign up the user in Supabase Auth
    final AuthResponse res = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final User? user = res.user;
    if (user == null) {
      throw Exception('Failed to create user account.');
    }

    // 2. Insert into profiles table
    await _client.from('profiles').insert({
      'id': user.id,
      'first_name': firstName,
      'last_name': lastName,
      'class_id': classId,
      'university_id': universityId,
      'class_roll': classRoll,
      'batch': batch,
      'session': session,
      'du_reg': duReg,
      'phone': phone,
      'profile_pic': profilePic,
      'role': 'member',
    });
    
    // Automatically sets session and triggers the auth listener
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    // Profile is fetched via auth state listener
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
          case 'superuser':
            parsedRole = UserRole.superUser;
            break;
          case 'committee':
            parsedRole = UserRole.committeeMember;
            break;
          case 'member':
          default:
            parsedRole = UserRole.student;
            break;
        }

        currentProfile.value = ProfileData(
          id: data['id'],
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          name: '${data['first_name']} ${data['last_name']}',
          email: user.email ?? '',
          roll: data['class_id'] ?? '',
          studentId: data['class_id'] ?? '',
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
        );
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }
    }
  }

  // Superuser capabilities
  static Future<List<ProfileData>> fetchAllMembers() async {
    final response = await _client.from('profiles').select().order('created_at', ascending: false);
    
    List<ProfileData> members = [];
    for (var data in response) {
      UserRole parsedRole;
      switch (data['role']) {
        case 'superuser':
          parsedRole = UserRole.superUser;
          break;
        case 'committee':
          parsedRole = UserRole.committeeMember;
          break;
        case 'member':
        default:
          parsedRole = UserRole.student;
          break;
      }

      members.add(ProfileData(
        id: data['id'],
        firstName: data['first_name'] ?? '',
        lastName: data['last_name'] ?? '',
        name: '${data['first_name']} ${data['last_name']}',
        email: '', 
        roll: data['class_id'] ?? '',
        studentId: data['class_id'] ?? '',
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
      ));
    }
    return members;
  }

  static Future<void> updateUserRole(String userId, UserRole newRole, {String? designation}) async {
    String roleString;
    switch (newRole) {
      case UserRole.superUser:
        roleString = 'superuser';
        break;
      case UserRole.committeeMember:
        roleString = 'committee';
        break;
      case UserRole.student:
      default:
        roleString = 'member';
        break;
    }

    final Map<String, dynamic> updateData = {'role': roleString};
    if (designation != null) {
      updateData['designation'] = designation;
    }

    await _client
        .from('profiles')
        .update(updateData)
        .eq('id', userId);
  }

  static Future<void> updateProfile(ProfileData profile) async {
    await _client.from('profiles').update({
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'class_id': profile.studentId,
      'university_id': profile.universityId,
      'class_roll': profile.classRoll,
      'batch': profile.batch,
      'session': profile.session,
      'phone': profile.phone,
      'profile_pic': profile.imagePath, 
      'du_reg': profile.duRegNo,
    }).eq('id', profile.id);
    await fetchCurrentUserProfile();
  }

  static Future<void> approveUser(String userId) async {
    await _client.from('profiles').update({'is_approved': true}).eq('id', userId);
  }

  static Future<void> deleteUser(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }

  static Future<List<Map<String, dynamic>>> fetchSessions() async {
    final data = await _client.from('DUCMC_sessions_id').select().order('session', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> moveToAlumni(ProfileData member) async {
    // 1. Insert into alumni table
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
    });

    // 2. Delete from profiles table
    await _client.from('profiles').delete().eq('id', member.id);
  }
}
