import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ShEC_CSE/core/services/storage_service.dart';
import 'package:ShEC_CSE/core/services/image_processing_service.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../backend/services/auth_service.dart';
import '../screens/pending_approval_screen.dart';
import '../../dashboard/screens/main_screen.dart';
import 'forgot_password_screen.dart';
import '../../../core/utils/validation_rules.dart';
import '../../../core/utils/snackbar_utils.dart';


class AuthAnimatedScreen extends StatefulWidget {
  const AuthAnimatedScreen({super.key});

  @override
  State<AuthAnimatedScreen> createState() => _AuthAnimatedScreenState();
}

class _AuthAnimatedScreenState extends State<AuthAnimatedScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  late AnimationController _signupFieldsController;
  bool _isLoginActive = true;
  bool _isLoading = false;

  // Login Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginPasswordVisible = false;

  // Signup Controllers
  final _signupFormKey = GlobalKey<FormState>();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _signupFirstNameController = TextEditingController();
  final _signupLastNameController = TextEditingController();
  final _signupUniversityIdController = TextEditingController();
  final _signupClassRollController = TextEditingController();
  final _signupDuRegController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  
  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSession;
  String? _selectedBatch;
  bool _isSessionsLoading = true;
  File? _profileImageFile;
  bool _signupPasswordVisible = false;
  bool _signupConfirmPasswordVisible = false;

  // Max 10 batches as requested
  final List<String> _batches = List.generate(10, (index) => (index + 1).toString());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _signupFieldsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fetchSessions();
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
            ];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSessionsLoading = false);
    }
  }

  void _toggleAuth() {
    setState(() {
      _isLoginActive = !_isLoginActive;
      if (_isLoginActive) {
        _controller.reverse();
        _signupFieldsController.reset();
      } else {
        _controller.forward();
        _signupFieldsController.forward();
      }
    });
  }

  // --- Auth Logic ---
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(
        email: _loginEmailController.text.trim(), 
        password: _loginPasswordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeLayout()));
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    if (_selectedSession == null) {
      SnackBarUtils.showError(context, 'Please select a session');
      return;
    }
    if (_selectedBatch == null) {
      SnackBarUtils.showError(context, 'Please select a batch');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? profilePicUrl;
      if (_profileImageFile != null) {
        profilePicUrl = await StorageService.uploadFile(_profileImageFile!, 'profile_pictures');
      }
      await AuthService.signUp(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text.trim(),
        firstName: _signupFirstNameController.text.trim(),
        lastName: _signupLastNameController.text.trim(),
        batch: _selectedBatch!,
        session: _selectedSession!,
        duReg: _signupDuRegController.text.trim(),
        phone: _signupPhoneController.text.trim(),
        profilePic: profilePicUrl,
        universityId: _signupUniversityIdController.text.trim(),
        classRoll: ValidationRules.formatClassRoll(_signupClassRollController.text),
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PendingApprovalScreen()));
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final cropped = await ImageProcessingService.cropImage(
        context, 
        File(picked.path), 
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      );
      if (cropped != null) {
        final processed = await ImageProcessingService.processAndConvert(cropped);
        if (processed != null) setState(() => _profileImageFile = processed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(painter: LightCosmicPainter(_backgroundController.value), size: size);
            },
          ),
          Positioned(top: size.height * 0.1, left: -50, child: _GlowOrb(color: Colors.blue.withValues(alpha: 0.1), size: 300)),
          Positioned(bottom: size.height * 0.1, right: -100, child: _GlowOrb(color: Colors.pink.withValues(alpha: 0.05), size: 400)),
          Positioned(
            top: size.height * 0.1,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildCard(size: size, title: 'Login', isActive: _isLoginActive, child: _buildLoginForm(), offsetMultiplier: 1),
                    _buildCard(size: size, title: 'Sign Up', isActive: !_isLoginActive, child: _buildSignupForm(), offsetMultiplier: -1),
                  ],
                );
              },
            ),
          ),
          if (!isKeyboardOpen)
            Positioned(
              bottom: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoginActive ? "Don't have an account? " : "Already have an account? ", 
                    style: const TextStyle(color: Color(0xFF636E72), letterSpacing: 0.5, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleAuth,
                    child: Text(
                      _isLoginActive ? "JOIN NOW" : "LOGIN", 
                      style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (_isLoading) Container(color: Colors.white70, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildCard({required Size size, required String title, required bool isActive, required Widget child, required int offsetMultiplier}) {
    final progress = _controller.value;
    double rotation = 0;
    double translateY = 0;
    double scale = 1.0;
    double opacity = 1.0;

    if (offsetMultiplier == 1) { // LOGIN CARD
      if (_isLoginActive) {
        rotation = progress * -math.pi; 
        translateY = progress * -20;
        scale = 1.0 - (progress * 0.2);
        opacity = (1.0 - progress).clamp(0.0, 1.0);
      } else {
        rotation = (1 - progress) * math.pi;
        scale = 0.8 + (progress * 0.2);
        opacity = progress;
      }
    } else { // SIGNUP CARD
      if (!_isLoginActive) {
        rotation = (1 - progress) * math.pi;
        translateY = (1 - progress) * -20;
        scale = 1.0 - ((1 - progress) * 0.2);
        opacity = progress;
      } else {
        rotation = -math.pi;
        opacity = 0.0;
      }
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !isActive,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) 
            ..translate(0.0, translateY)
            ..rotateY(rotation)
            ..scale(scale),
          child: Container(
            width: size.width * 0.88,
            height: size.height * 0.76, 
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 20)),
                BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.05), blurRadius: 15, spreadRadius: -5),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      color: Colors.white.withValues(alpha: 0.4),
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF2D3436), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
                        child: child,
                      ),
                    ),
                    _GlowButton(
                      text: title == 'Login' ? 'LOG IN' : 'CREATE ACCOUNT', 
                      onTap: title == 'Login' ? _login : _signUp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildGlowTextField(
            controller: _loginEmailController, 
            labelText: 'Email Address',
            hint: 'e.g. student@domain.com',
            icon: Icons.alternate_email_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              return ValidationRules.validateEmail(v);
            },
          ),
          const SizedBox(height: 18),
          _buildGlowTextField(
            controller: _loginPasswordController, 
            labelText: 'Password',
            hint: 'Enter your password', 
            icon: Icons.lock_person_outlined, 
            obscure: !_loginPasswordVisible,
            validator: (v) => ValidationRules.validateRequired(v, 'Password'),
            suffix: IconButton(
              icon: Icon(_loginPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF6C63FF)),
              onPressed: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: const Text('FORGOT PASSWORD?', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          _buildProgressiveItem(0, _buildSignupAvatar()),
          const SizedBox(height: 20),
          _buildProgressiveItem(1, _buildGlowTextField(
            controller: _signupFirstNameController, 
            labelText: 'First Name',
            hint: 'e.g. John', 
            icon: Icons.person_outline,
            validator: (v) => ValidationRules.validateRequired(v, 'First name'),
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(2, _buildGlowTextField(
            controller: _signupLastNameController, 
            labelText: 'Last Name',
            hint: 'e.g. Doe', 
            icon: Icons.person_outline,
            validator: (v) => ValidationRules.validateRequired(v, 'Last name'),
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(3, _buildGlowTextField(
            controller: _signupUniversityIdController, 
            labelText: 'University ID',
            hint: 'e.g. 54/21', 
            icon: Icons.badge_outlined,
            validator: ValidationRules.validateUniversityId,
            helper: _buildUnivIdHelper(),
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(4, _buildGlowTextField(
            controller: _signupClassRollController, 
            labelText: 'Class Roll',
            hint: 'e.g. CSE-10', 
            icon: Icons.format_list_numbered_rounded,
            validator: ValidationRules.validateClassRoll,
            helper: _buildClassRollHelper(),
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(5, _buildGlowTextField(
            controller: _signupDuRegController, 
            labelText: 'DU Registration No.',
            hint: 'e.g. 2018425167', 
            icon: Icons.app_registration_rounded,
            keyboardType: TextInputType.number,
            validator: ValidationRules.validateDuReg,
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(6, _buildGlowDropdown(
            labelText: 'SESSION',
            hint: _isSessionsLoading ? 'Loading...' : 'Select Session', 
            icon: Icons.calendar_month_outlined, 
            items: _sessions.map((s) => s['session'] as String).toList(), 
            onChanged: (v) => setState(() => _selectedSession = v),
            validator: (v) => ValidationRules.validateRequired(v, 'Session'),
            value: _selectedSession,
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(7, _buildGlowDropdown(
            labelText: 'BATCH',
            hint: 'Select Batch', 
            icon: Icons.school_outlined, 
            items: _batches, 
            onChanged: (v) => setState(() => _selectedBatch = v),
            validator: (v) => ValidationRules.validateRequired(v, 'Batch'),
            value: _selectedBatch,
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(8, _buildGlowTextField(
            controller: _signupPhoneController, 
            labelText: 'Phone Number',
            hint: 'e.g. 01712345678', 
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            validator: ValidationRules.validatePhone,
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(9, _buildGlowTextField(
            controller: _signupEmailController, 
            labelText: 'Email Address',
            hint: 'e.g. student@du.ac.bd', 
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: ValidationRules.validateEmail,
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(10, _buildGlowTextField(
            controller: _signupPasswordController, 
            labelText: 'Password',
            hint: 'Min. 6 chars, alphanumeric', 
            icon: Icons.lock_outline, 
            obscure: !_signupPasswordVisible,
            validator: (v) => ValidationRules.validatePassword(v, isSignup: true),
            suffix: IconButton(
              icon: Icon(_signupPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF6C63FF)),
              onPressed: () => setState(() => _signupPasswordVisible = !_signupPasswordVisible),
            ),
          )),
          const SizedBox(height: 16),
          _buildProgressiveItem(11, _buildGlowTextField(
            controller: _signupConfirmPasswordController, 
            labelText: 'Confirm Password',
            hint: 'Re-enter your password', 
            icon: Icons.lock_reset_rounded, 
            obscure: !_signupConfirmPasswordVisible,
            validator: (v) {
              if (v != _signupPasswordController.text) return 'Passwords do not match';
              return ValidationRules.validatePassword(v, isSignup: true);
            },
            suffix: IconButton(
              icon: Icon(_signupConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF6C63FF)),
              onPressed: () => setState(() => _signupConfirmPasswordVisible = !_signupConfirmPasswordVisible),
            ),
          )),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProgressiveItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _signupFieldsController,
      builder: (context, _) {
        final start = index * 0.06;
        final anim = CurvedAnimation(
          parent: _signupFieldsController, 
          curve: Interval(start.clamp(0, 0.9), (start + 0.15).clamp(0, 1), curve: Curves.easeOutCubic),
        );
        return Transform.translate(
          offset: Offset(0, 15 * (1 - anim.value)), 
          child: Opacity(opacity: anim.value, child: child),
        );
      },
    );
  }

  Widget _buildSignupAvatar() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), width: 1.5),
        ),
        child: CircleAvatar(
          radius: 38, 
          backgroundColor: Colors.black.withValues(alpha: 0.03),
          backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
          child: _profileImageFile == null 
              ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF6C63FF), size: 28) 
              : null,
        ),
      ),
    );
  }

  Widget _buildGlowTextField({
    required TextEditingController controller, 
    required String labelText,
    required String hint, 
    required IconData icon, 
    bool obscure = false, 
    Widget? suffix,
    String? Function(String?)? validator,
    Widget? helper,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller, 
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF2D3436), fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hint, 
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        suffixIcon: suffix, 
        helper: helper,
        helperMaxLines: 2,
        isDense: true,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }

  Widget _buildGlowDropdown({
    required String labelText,
    required String hint, 
    required IconData icon, 
    required List<String> items, 
    required Function(String?) onChanged, 
    String? Function(String?)? validator,
    String? value,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white, 
      iconEnabledColor: const Color(0xFF6C63FF),
      style: const TextStyle(color: Color(0xFF2D3436), fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hint, 
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      items: items.map((i) {
        return DropdownMenuItem<String>(
          value: i, 
          child: Text(labelText == 'BATCH' ? 'Batch $i' : i),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildUnivIdHelper() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
            height: 1.2,
          ),
          children: [
            TextSpan(text: 'Format: '),
            TextSpan(
              text: '54/21',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            TextSpan(text: '|CSE-10 (Enter University ID part)'),
          ],
        ),
      ),
    );
  }

  Widget _buildClassRollHelper() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
            height: 1.2,
          ),
          children: [
            TextSpan(text: 'Format: 54/21|'),
            TextSpan(
              text: 'CSE-10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            TextSpan(text: ' (Enter Class Roll part)'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); 
    _backgroundController.dispose(); 
    _signupFieldsController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupFirstNameController.dispose();
    _signupLastNameController.dispose();
    _signupUniversityIdController.dispose();
    _signupClassRollController.dispose();
    _signupDuRegController.dispose();
    _signupPhoneController.dispose();
    super.dispose();
  }
}

class _GlowButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GlowButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 60,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00ADB5), Color(0xFF6C63FF)])),
        child: Center(
          child: Text(
            text, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, 
      height: size, 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.5, spreadRadius: 0)],
      ),
    );
  }
}

class LightCosmicPainter extends CustomPainter {
  final double progress;
  LightCosmicPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = const Color(0xFF6C63FF).withValues(alpha: 0.1);
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + progress * 100) % size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 2, paint);
    }
    for (int i = 0; i < 4; i++) {
      final p = (progress + i * 0.25) % 1.0;
      final x = math.sin(p * 2 * math.pi) * 30 + size.width * (i / 4);
      final y = size.height * (1 - p);
      final glowPaint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFF00ADB5) : const Color(0xFF6C63FF)).withValues(alpha: 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(x, y), 60 + i * 15, glowPaint);
    }
  }
  @override
  bool shouldRepaint(LightCosmicPainter oldDelegate) => true;
}
