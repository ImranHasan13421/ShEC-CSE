import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/features/dashboard/presentation/widgets/ambient_background.dart';
import 'package:ShEC_CSE/core/services/storage_service.dart';
import 'package:ShEC_CSE/core/services/image_processing_service.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:ShEC_CSE/core/utils/validation_rules.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';
import '../../../backend/services/auth_service.dart';
import '../../../features/auth/screens/pending_approval_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _classRollController = TextEditingController();
  final _duRegController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSession;
  String? _selectedBatch; 
  bool _isSessionsLoading = true;
  File? _profileImageFile;

  // Max 10 batches as requested
  final List<String> _batches = List.generate(10, (index) => (index + 1).toString());

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _universityIdController.dispose();
    _classRollController.dispose();
    _duRegController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    try {
      final data = await AuthService.fetchSessions();
      if (mounted) {
        setState(() {
          _sessions = data;
          _isSessionsLoading = false;
          if (_sessions.isEmpty) {
            _sessions = [
              {'session': '2025-2026'},
              {'session': '2024-2025'},
              {'session': '2023-2024'},
              {'session': '2022-2023'},
              {'session': '2021-2022'},
              {'session': '2020-2021'},
              {'session': '2019-2020'},
            ];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      if (mounted) {
        setState(() {
          _isSessionsLoading = false;
          _sessions = [
            {'session': '2025-2026'},
            {'session': '2024-2025'},
            {'session': '2023-2024'},
            {'session': '2022-2023'},
            {'session': '2021-2022'},
          ];
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (!mounted) return;
        
        final cropped = await ImageProcessingService.cropImage(
          context, 
          File(picked.path),
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        );
        
        if (cropped != null) {
          final processed = await ImageProcessingService.processAndConvert(cropped);
          if (processed != null) {
            setState(() => _profileImageFile = processed);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadProfilePic(File file) async {
    return StorageService.uploadFile(file, 'profile_pictures');
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a session'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? profilePicUrl;
      if (_profileImageFile != null) {
        profilePicUrl = await _uploadProfilePic(_profileImageFile!);
      }

      await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        batch: _selectedBatch!,
        session: _selectedSession!,
        duReg: _duRegController.text.trim(),
        phone: _phoneController.text.trim(),
        profilePic: profilePicUrl,
        universityId: _universityIdController.text.trim(),
        classRoll: ValidationRules.formatClassRoll(_classRollController.text),
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Registration submitted! Waiting for approval.');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Common Custom Field Renderer for unified premium styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    Widget? helper,
    TextInputType? keyboardType,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: colors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: colors.primary, size: 20),
        suffixIcon: suffixIcon,
        helper: helper,
        helperMaxLines: 2,
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    final colors = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: colors.surface,
      style: TextStyle(color: colors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: colors.primary, size: 20),
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Highlights format "54/21" for University ID
  Widget _buildUnivIdHelper() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurface.withValues(alpha: 0.6),
            height: 1.2,
          ),
          children: [
            const TextSpan(text: 'Format: '),
            TextSpan(
              text: '54/21',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const TextSpan(text: '|CSE-10 (Enter University ID part)'),
          ],
        ),
      ),
    );
  }

  // Highlights format "CSE-10" for Class Roll
  Widget _buildClassRollHelper() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurface.withValues(alpha: 0.6),
            height: 1.2,
          ),
          children: [
            const TextSpan(text: 'Format: 54/21|'),
            TextSpan(
              text: 'CSE-10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const TextSpan(text: ' (Enter Class Roll part)'),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({required String title, required IconData icon, required List<Widget> children}) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.withValues(alpha: isDark ? 0.35 : 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(thickness: 1, height: 1),
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AmbientTimeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Create an Account'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: colors.onSurface,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dynamic Header
                    Text(
                      'Join ShEC CSE',
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill in your details to register for access approval',
                      style: TextStyle(
                        fontSize: 13, 
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Card 1: Personal Details
                    _buildCardContainer(
                      title: 'Personal Details',
                      icon: Icons.person_outline_rounded,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.primary.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                                    backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                                    child: _profileImageFile == null
                                        ? Icon(Icons.add_a_photo_outlined, size: 36, color: colors.primary)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _firstNameController,
                                labelText: 'First Name',
                                hintText: 'e.g. John',
                                prefixIcon: Icons.person,
                                validator: (v) => ValidationRules.validateRequired(v, 'First name'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _lastNameController,
                                labelText: 'Last Name',
                                hintText: 'e.g. Doe',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => ValidationRules.validateRequired(v, 'Last name'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Card 2: Academic Details
                    _buildCardContainer(
                      title: 'Academic Details',
                      icon: Icons.school_outlined,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _universityIdController,
                                labelText: 'University ID',
                                hintText: 'e.g. 54/21',
                                prefixIcon: Icons.badge_outlined,
                                validator: ValidationRules.validateUniversityId,
                                helper: _buildUnivIdHelper(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _classRollController,
                                labelText: 'Class Roll',
                                hintText: 'e.g. CSE-10',
                                prefixIcon: Icons.format_list_numbered,
                                validator: ValidationRules.validateClassRoll,
                                helper: _buildClassRollHelper(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField<String>(
                                value: _selectedSession,
                                labelText: 'Session',
                                hintText: _isSessionsLoading ? 'Loading...' : 'Select Session',
                                prefixIcon: Icons.calendar_today_outlined,
                                items: _sessions.map((s) {
                                  final sessionVal = s['session'] as String;
                                  return DropdownMenuItem<String>(
                                    value: sessionVal,
                                    child: Text(sessionVal),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedSession = val),
                                validator: (v) => v == null ? 'Session is required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownField<String>(
                                value: _selectedBatch,
                                labelText: 'Batch',
                                hintText: 'Select Batch',
                                prefixIcon: Icons.group_outlined,
                                items: _batches.map((b) {
                                  return DropdownMenuItem<String>(
                                    value: b,
                                    child: Text('Batch $b'),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedBatch = val),
                                validator: (v) => v == null ? 'Batch is required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _duRegController,
                          labelText: 'DU Registration No.',
                          hintText: 'e.g. 568',
                          prefixIcon: Icons.app_registration_rounded,
                          keyboardType: TextInputType.number,
                          validator: ValidationRules.validateDuReg,
                        ),
                      ],
                    ),

                    // Card 3: Account & Contact Security
                    _buildCardContainer(
                      title: 'Contact & Security',
                      icon: Icons.lock_outline_rounded,
                      children: [
                        _buildTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number',
                          hintText: 'e.g. 01712345678',
                          prefixIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: ValidationRules.validatePhone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'e.g. student@du.ac.bd',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: ValidationRules.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Min. 6 chars, alphanumeric',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: !_passwordVisible,
                          validator: (v) => ValidationRules.validatePassword(v, isSignup: true),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: colors.primary,
                            ),
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          hintText: 'Re-enter your password',
                          prefixIcon: Icons.lock_reset_rounded,
                          obscureText: !_confirmPasswordVisible,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirm Password is required';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: colors.primary,
                            ),
                            onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Submit Registration Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        shadowColor: colors.primary.withValues(alpha: 0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Create Account', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
