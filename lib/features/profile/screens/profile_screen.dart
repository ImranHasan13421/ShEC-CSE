// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _rollController;
  late TextEditingController _idController;
  late TextEditingController _duRegController;
  late TextEditingController _sessionController;

  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final profile = currentProfile.value;
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _rollController = TextEditingController(text: profile.roll);
    _idController = TextEditingController(text: profile.studentId);
    _duRegController = TextEditingController(text: profile.duRegNo);
    _sessionController = TextEditingController(text: profile.session);
    _imagePath = profile.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollController.dispose();
    _idController.dispose();
    _duRegController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        // Force a 1:1 square crop
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // Prevents user from changing the 1:1 ratio
            hideBottomControls: true, // Hides extra aspect ratio options
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imagePath = croppedFile.path;
        });
      }
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Update global state
      currentProfile.value = currentProfile.value.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        roll: _rollController.text,
        studentId: _idController.text,
        duRegNo: _duRegController.text,
        session: _sessionController.text,
        imagePath: _imagePath,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: colors.primary.withOpacity(0.1),
                      backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                      child: _imagePath == null
                          ? Icon(Icons.person, size: 60, color: colors.primary)
                          : null,
                    ),
                    GestureDetector(
                      onTap: _pickAndCropImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.primary,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              _buildTextField('Full Name', _nameController, Icons.person),
              const SizedBox(height: 16),
              _buildTextField('Email Address', _emailController, Icons.email),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField('Class Roll', _rollController, Icons.numbers)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Session', _sessionController, Icons.date_range)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Student ID', _idController, Icons.badge),
              const SizedBox(height: 16),
              _buildTextField('DU Registration No.', _duRegController, Icons.app_registration),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
    );
  }
}