// lib/features/profile/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _universityIdController;
  late TextEditingController _classRollController;
  late TextEditingController _phoneController;
  late TextEditingController _duRegController;
  late TextEditingController _passwordController;

  String? _selectedSession;
  String? _selectedBatch;

  String? _imageUrl;  
  File? _newImageFile; 
  bool _isUploading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final profile = currentProfile.value;
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _universityIdController = TextEditingController(text: profile.universityId);
    _classRollController = TextEditingController(text: profile.classRoll);
    _selectedSession = profile.session.isNotEmpty ? profile.session : null;
    _selectedBatch = profile.batch.isNotEmpty ? profile.batch : null;
    _phoneController = TextEditingController(text: profile.phone);
    _duRegController = TextEditingController(text: profile.duRegNo);
    _passwordController = TextEditingController();
    _imageUrl = profile.imagePath;

    _checkLostData();
  }


  Future<void> _checkLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) return;
    if (response.file != null) {
      setState(() => _newImageFile = File(response.file!.path));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _universityIdController.dispose();
    _classRollController.dispose();
    _phoneController.dispose();
    _duRegController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() => _newImageFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadProfilePic(File file) async {
    try {
      final userId = currentProfile.value.id;
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final client = Supabase.instance.client;
      await client.storage.from('profile_pictures').upload(fileName, file);
      return client.storage.from('profile_pictures').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Profile pic upload error: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      String? finalImageUrl = _imageUrl;

      if (_newImageFile != null) {
        finalImageUrl = await _uploadProfilePic(_newImageFile!);
        if (finalImageUrl == null) {
           throw Exception('Failed to upload image. Please try again.');
        }
      }

      final profile = currentProfile.value;
      final isSuperuser = profile.designation == 'President' || profile.designation == 'Vice President';

      // 1. Update Profile Metadata
      final updatedProfile = profile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        name: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        imagePath: finalImageUrl,
        // Allow superusers to save these fields too
        studentId: isSuperuser ? _universityIdController.text.trim() : profile.studentId,
        universityId: isSuperuser ? _universityIdController.text.trim() : profile.universityId,
        classRoll: isSuperuser ? _classRollController.text.trim() : profile.classRoll,
        session: isSuperuser ? (_selectedSession ?? profile.session) : profile.session,
        batch: isSuperuser ? (_selectedBatch ?? profile.batch) : profile.batch,
        phone: isSuperuser ? _phoneController.text.trim() : profile.phone,
        duRegNo: isSuperuser ? _duRegController.text.trim() : profile.duRegNo,
      );

      await AuthService.updateProfile(updatedProfile);

      // 2. Update Password if provided
      if (_passwordController.text.isNotEmpty) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim()),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  ImageProvider? get _displayImage {
    if (_newImageFile != null) return FileImage(_newImageFile!);
    if (_imageUrl != null && _imageUrl!.isNotEmpty && _imageUrl!.startsWith('http')) {
      return NetworkImage(_imageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profile = currentProfile.value;
    final isSuperuser = profile.designation == 'President' || profile.designation == 'Vice President';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: colors.primaryContainer,
                      backgroundImage: _displayImage,
                      child: _displayImage == null
                          ? Text(
                              (profile.firstName.isNotEmpty
                                  ? profile.firstName[0]
                                  : '?').toUpperCase(),
                              style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: colors.onPrimaryContainer),
                            )
                          : null,
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: colors.primary,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _sectionLabel('Personal Information'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildTextField('First Name', _firstNameController, Icons.person)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('Last Name', _lastNameController, Icons.person_outline)),
              ]),
              const SizedBox(height: 16),
              _buildTextField('Email (Read Only)', _emailController, Icons.email, readOnly: true),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: _inputDecoration('Change Password', Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  hintText: 'Leave empty to keep current',
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel(isSuperuser ? 'Academic Information' : 'Academic Information (Locked)'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildTextField('University ID', _universityIdController, Icons.badge, readOnly: !isSuperuser)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('Class Roll', _classRollController, Icons.numbers, readOnly: !isSuperuser)),
              ]),
              const SizedBox(height: 16),
              
              if (isSuperuser) ...[
                Row(
                  children: [
                    Expanded(
                      child: Builder(builder: (context) {
                        final generatedSessions = [for (var i = 2015; i <= 2026; i++) '${i}-${i + 1}'];
                        if (_selectedSession != null && _selectedSession!.isNotEmpty && !generatedSessions.contains(_selectedSession)) {
                          generatedSessions.add(_selectedSession!);
                          generatedSessions.sort((a, b) => b.compareTo(a));
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedSession,
                          decoration: _inputDecoration('Session', Icons.date_range),
                          items: generatedSessions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _selectedSession = val),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Builder(builder: (context) {
                        final generatedBatches = [for (var i = 1; i <= 10; i++) '$i'];
                        if (_selectedBatch != null && _selectedBatch!.isNotEmpty && !generatedBatches.contains(_selectedBatch)) {
                          generatedBatches.add(_selectedBatch!);
                        }
                        generatedBatches.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                        return DropdownButtonFormField<String>(
                          value: _selectedBatch,
                          decoration: _inputDecoration('Batch', Icons.group),
                          items: generatedBatches.map((s) => DropdownMenuItem(value: s, child: Text('Batch $s'))).toList(),
                          onChanged: (val) => setState(() => _selectedBatch = val),
                        );
                      }),
                    ),
                  ],
                ),
              ] else ...[
                _buildTextField('Session', TextEditingController(text: _selectedSession), Icons.date_range, readOnly: true),
                const SizedBox(height: 16),
                _buildTextField('Batch', TextEditingController(text: _selectedBatch != null ? 'Batch $_selectedBatch' : ''), Icons.group, readOnly: true),
              ],
              
              const SizedBox(height: 16),
              
              _buildTextField('Phone', _phoneController, Icons.phone, readOnly: !isSuperuser),
              const SizedBox(height: 16),
              _buildTextField('DU Registration No.', _duRegController, Icons.app_registration, readOnly: !isSuperuser),
              
              if (!isSuperuser)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Contact admin to update academic details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isUploading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isUploading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
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

  InputDecoration _inputDecoration(String label, IconData icon, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: readOnly,
      fillColor: readOnly ? Colors.grey.shade50 : null,
      isDense: true,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool readOnly = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon, readOnly: readOnly),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}