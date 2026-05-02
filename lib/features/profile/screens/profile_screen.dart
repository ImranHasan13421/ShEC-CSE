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

  String? _selectedSession;
  String? _selectedBatch;
  List<Map<String, dynamic>> _sessions = [];
  final List<String> _batches = List.generate(10, (index) => (index + 1).toString());

  String? _imageUrl;  
  File? _newImageFile; 
  bool _isUploading = false;

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
    _imageUrl = profile.imagePath;

    _fetchSessions();
    _checkLostData();
  }

  Future<void> _fetchSessions() async {
    try {
      final data = await AuthService.fetchSessions();
      if (mounted) {
        setState(() {
          _sessions = data;
          if (_selectedSession != null && !_sessions.any((s) => s['session'] == _selectedSession)) {
            // Keep current value if not in list yet
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
    }
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

      final updatedProfile = currentProfile.value.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        name: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        universityId: _universityIdController.text.trim(),
        classRoll: _classRollController.text.trim(),
        studentId: '${_universityIdController.text.trim()} / ${_classRollController.text.trim()}',
        session: _selectedSession ?? '',
        batch: _selectedBatch ?? '',
        phone: _phoneController.text.trim(),
        duRegNo: _duRegController.text.trim(),
        imagePath: finalImageUrl,
      );

      await AuthService.updateProfile(updatedProfile);

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
                              (currentProfile.value.firstName.isNotEmpty
                                  ? currentProfile.value.firstName[0]
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
              _buildTextField('Email (View Only)', _emailController, Icons.email, readOnly: true),
              
              const SizedBox(height: 24),
              _sectionLabel('Academic Information'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildTextField('University ID', _universityIdController, Icons.badge)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('Class Roll', _classRollController, Icons.numbers)),
              ]),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedSession,
                decoration: _inputDecoration('Session', Icons.date_range),
                isExpanded: true,
                items: _sessions.map((s) {
                  return DropdownMenuItem<String>(
                    value: s['session'] as String,
                    child: Text(s['session'] as String),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedSession = value),
                validator: (v) => v == null ? 'Select session' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedBatch,
                decoration: _inputDecoration('Batch', Icons.group),
                isExpanded: true,
                items: _batches.map((b) {
                  return DropdownMenuItem<String>(
                    value: b,
                    child: Text('Batch $b'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedBatch = value),
                validator: (v) => v == null ? 'Select batch' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField('Phone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('DU Registration No.', _duRegController, Icons.app_registration),
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