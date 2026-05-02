import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../backend/services/auth_service.dart';
import 'login_screen.dart';
import '../../../features/auth/screens/pending_approval_screen.dart';
import '../../../features/profile/models/profile_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _universityIdController = TextEditingController(); // e.g. 54/21
  final _classRollController = TextEditingController();    // e.g. CSE-10
  final _batchController = TextEditingController();
  final _duRegController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSession;

  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      final data = await AuthService.fetchSessions();
      if (mounted) {
        setState(() {
          _sessions = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImageFile = File(picked.path));
    }
  }

  Future<String?> _uploadProfilePic(File file) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final client = Supabase.instance.client;
      await client.storage.from('profile_pictures').upload(fileName, file);
      return client.storage.from('profile_pictures').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Profile pic upload error: $e');
      return null;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload profile picture if selected
      String? profilePicUrl;
      if (_profileImageFile != null) {
        profilePicUrl = await _uploadProfilePic(_profileImageFile!);
      }

      // Combine university_id + class_roll into class_id for backward compat
      final classId = '${_universityIdController.text.trim()} / ${_classRollController.text.trim()}';

      await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        classId: classId,
        batch: _batchController.text.trim(),
        session: _selectedSession ?? '',
        duReg: _duRegController.text.trim(),
        phone: _phoneController.text.trim(),
        profilePic: profilePicUrl,
        universityId: _universityIdController.text.trim(),
        classRoll: _classRollController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration submitted! Waiting for approval.')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration(String label, {IconData? prefixIcon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffix,
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create an Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join ShEC CSE',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your details to register as a Member',
                  style: TextStyle(fontSize: 14, color: colors.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── Profile Picture ──
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colors.primaryContainer,
                          backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                          child: _profileImageFile == null
                              ? Icon(Icons.person, size: 48, color: colors.onPrimaryContainer)
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section Label ──
                _sectionLabel('Personal Information'),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: _decoration('First Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: _decoration('Last Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Academic Info ──
                _sectionLabel('Academic Information'),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _universityIdController,
                      decoration: _decoration('University ID (e.g. 54/21)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _classRollController,
                      decoration: _decoration('Class Roll (e.g. CSE-10)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSession,
                      decoration: _decoration('Session'),
                      isExpanded: true,
                      items: _sessions.isEmpty 
                        ? [const DropdownMenuItem(value: '', child: Text('Loading sessions...'))]
                        : _sessions.map((s) {
                          return DropdownMenuItem<String>(
                            value: s['session'] as String,
                            child: Text(s['session'] as String),
                          );
                        }).toList(),
                      onChanged: (value) => setState(() => _selectedSession = value),
                      validator: (v) => v == null || v.isEmpty ? 'Select session' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _batchController,
                      decoration: _decoration('Batch'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _duRegController,
                  decoration: _decoration('DU Registration No.'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // ── Contact Info ──
                _sectionLabel('Contact & Account'),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  decoration: _decoration('Phone Number', prefixIcon: Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: _decoration('Email Address', prefixIcon: Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: _decoration(
                    'Password',
                    prefixIcon: Icons.lock,
                    suffix: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: _decoration(
                    'Confirm Password',
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_confirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                  ),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}
