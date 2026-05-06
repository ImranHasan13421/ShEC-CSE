import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ShEC_CSE/core/services/storage_service.dart';
import 'package:ShEC_CSE/core/services/image_processing_service.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../backend/services/auth_service.dart';
import '../screens/pending_approval_screen.dart';
import '../../dashboard/screens/main_screen.dart';
import 'forgot_password_screen.dart';

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
            _sessions = [{'session': '2024-2025'}, {'session': '2023-2024'}];
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
    if (_loginEmailController.text.isEmpty || _loginPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(email: _loginEmailController.text.trim(), password: _loginPasswordController.text.trim());
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeLayout()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
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
        batch: _selectedBatch ?? '1',
        session: _selectedSession ?? '2024-2025',
        duReg: _signupDuRegController.text.trim(),
        phone: _signupPhoneController.text.trim(),
        profilePic: profilePicUrl,
        universityId: _signupUniversityIdController.text.trim(),
        classRoll: _signupClassRollController.text.trim(),
      );
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PendingApprovalScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final cropped = await ImageProcessingService.cropImage(context, File(picked.path), aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
      if (cropped != null) {
        final processed = await ImageProcessingService.processAndConvert(cropped);
        if (processed != null) setState(() => _profileImageFile = processed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
          Positioned(
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_isLoginActive ? "Don't have an account? " : "Already have an account? ", style: const TextStyle(color: Color(0xFF636E72), letterSpacing: 0.5)),
                TextButton(
                  onPressed: _isLoading ? null : _toggleAuth,
                  child: Text(_isLoginActive ? "JOIN NOW" : "LOGIN", style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
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

    // Sophisticated 3D Rotational Transition
    if (offsetMultiplier == 1) { // LOGIN CARD
      if (_isLoginActive) {
        // Active -> Rotating away to the left
        rotation = progress * -math.pi; 
        translateY = progress * -20; // Slight lift
        scale = 1.0 - (progress * 0.2);
        opacity = (1.0 - progress).clamp(0.0, 1.0);
      } else {
        // Inactive -> Rotating back into center
        rotation = (1 - progress) * math.pi;
        scale = 0.8 + (progress * 0.2);
        opacity = progress;
      }
    } else { // SIGNUP CARD
      if (!_isLoginActive) {
        // Active -> Rotating away to the right
        rotation = (1 - progress) * math.pi;
        translateY = (1 - progress) * -20;
        scale = 1.0 - ((1 - progress) * 0.2);
        opacity = progress;
      } else {
        // Inactive -> Waiting rotated
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
            ..setEntry(3, 2, 0.001) // Perspective
            ..translate(0.0, translateY)
            ..rotateY(rotation)
            ..scale(scale),
          child: Container(
            width: size.width * 0.88,
            height: size.height * 0.78, // Slightly taller for light mode layout
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
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
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      color: Colors.white.withValues(alpha: 0.3),
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF2D3436), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4),
                      ),
                    ),
                    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), child: child)),
                    _GlowButton(text: title == 'Login' ? 'LOG IN' : 'CREATE ACCOUNT', onTap: title == 'Login' ? _login : _signUp),
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
    return Column(
      children: [
        const SizedBox(height: 30),
        _buildGlowTextField(controller: _loginEmailController, hint: 'EMAIL / USERNAME', icon: Icons.alternate_email_rounded),
        const SizedBox(height: 25),
        _buildGlowTextField(
          controller: _loginPasswordController, hint: 'PASSWORD', icon: Icons.lock_person_outlined, obscure: !_loginPasswordVisible,
          suffix: IconButton(
            icon: Icon(_loginPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF6C63FF)),
            onPressed: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
          ),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
            child: const Text('FORGOT PASSWORD?', style: TextStyle(color: Colors.black38, fontSize: 10, letterSpacing: 1)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          _buildProgressiveItem(0, _buildSignupAvatar()),
          const SizedBox(height: 20),
          _buildProgressiveItem(1, _buildGlowTextField(controller: _signupFirstNameController, hint: 'FIRST NAME', icon: Icons.person_outline)),
          const SizedBox(height: 15),
          _buildProgressiveItem(2, _buildGlowTextField(controller: _signupLastNameController, hint: 'LAST NAME', icon: Icons.person_outline)),
          const SizedBox(height: 15),
          _buildProgressiveItem(3, _buildGlowTextField(controller: _signupUniversityIdController, hint: 'UNIVERSITY ID', icon: Icons.badge_outlined)),
          const SizedBox(height: 15),
          _buildProgressiveItem(4, _buildGlowTextField(controller: _signupClassRollController, hint: 'CLASS ROLL', icon: Icons.format_list_numbered_rounded)),
          const SizedBox(height: 15),
          _buildProgressiveItem(5, _buildGlowTextField(controller: _signupDuRegController, hint: 'DU REGISTRATION', icon: Icons.app_registration_rounded)),
          const SizedBox(height: 15),
          _buildProgressiveItem(6, _buildGlowDropdown('SESSION', Icons.calendar_month_outlined, _sessions.map((s) => s['session'] as String).toList(), (v) => _selectedSession = v)),
          const SizedBox(height: 15),
          _buildProgressiveItem(7, _buildGlowDropdown('BATCH', Icons.school_outlined, _batches, (v) => _selectedBatch = v)),
          const SizedBox(height: 15),
          _buildProgressiveItem(8, _buildGlowTextField(controller: _signupPhoneController, hint: 'PHONE', icon: Icons.phone_android_outlined)),
          const SizedBox(height: 15),
          _buildProgressiveItem(9, _buildGlowTextField(controller: _signupEmailController, hint: 'EMAIL', icon: Icons.email_outlined)),
          const SizedBox(height: 15),
          _buildProgressiveItem(10, _buildGlowTextField(
            controller: _signupPasswordController, hint: 'PASSWORD', icon: Icons.lock_outline, obscure: !_signupPasswordVisible,
            suffix: IconButton(
              icon: Icon(_signupPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF6C63FF)),
              onPressed: () => setState(() => _signupPasswordVisible = !_signupPasswordVisible),
            ),
          )),
          const SizedBox(height: 15),
          _buildProgressiveItem(11, _buildGlowTextField(
            controller: _signupConfirmPasswordController, hint: 'CONFIRM PASSWORD', icon: Icons.lock_reset_rounded, obscure: !_signupConfirmPasswordVisible,
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
        final start = index * 0.08;
        final anim = CurvedAnimation(parent: _signupFieldsController, curve: Interval(start.clamp(0, 0.9), (start + 0.2).clamp(0, 1), curve: Curves.easeOutCubic));
        return Transform.translate(offset: Offset(0, 20 * (1 - anim.value)), child: Opacity(opacity: anim.value, child: child));
      },
    );
  }

  Widget _buildSignupAvatar() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3))),
        child: CircleAvatar(
          radius: 35, backgroundColor: Colors.black.withValues(alpha: 0.05),
          backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
          child: _profileImageFile == null ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF6C63FF)) : null,
        ),
      ),
    );
  }

  Widget _buildGlowTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: TextFormField(
        controller: controller, obscureText: obscure,
        style: const TextStyle(color: Color(0xFF2D3436), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Colors.black26, fontSize: 12, letterSpacing: 1),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          suffixIcon: suffix, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGlowDropdown(String hint, IconData icon, List<String> items, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.white, iconEnabledColor: const Color(0xFF6C63FF),
        style: const TextStyle(color: Color(0xFF2D3436), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Colors.black26, fontSize: 12, letterSpacing: 1),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); _backgroundController.dispose(); _signupFieldsController.dispose();
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
        width: double.infinity, height: 70,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00ADB5), Color(0xFF6C63FF)])),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16))),
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
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: size * 0.5, spreadRadius: 0)]));
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
      final glowPaint = Paint()..color = (i % 2 == 0 ? const Color(0xFF00ADB5) : const Color(0xFF6C63FF)).withValues(alpha: 0.03)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(x, y), 60 + i * 15, glowPaint);
    }
  }
  @override
  bool shouldRepaint(LightCosmicPainter oldDelegate) => true;
}
