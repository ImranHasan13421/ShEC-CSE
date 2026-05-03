// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/dashboard/screens/main_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/login_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/pending_approval_screen.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';

import '../../../backend/services/auth_service.dart';

enum GifSize { small, medium, large, custom }

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn; // Receives the login status from main.dart
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _startExitTimer();
  }

  Future<void> _startExitTimer() async {
    // 1. Wait for the GIF to play out
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    // 2. If logged in, ensure profile is fetched before moving on
    if (widget.isLoggedIn && currentProfile.value.id.isEmpty) {
      try {
        await AuthService.fetchCurrentUserProfile();
      } catch (e) {
        debugPrint('Splash profile fetch error: $e');
      }
    }

    // 2. Start fading out the GIF and Text
    setState(() {
      _isExiting = true;
    });

    // ── 🆕 FIXED TIMING ──
    // Wait exactly 800ms. This matches the duration of the text's
    // AnimatedOpacity and AnimatedSlide so it fully vanishes before the next screen!
    await Future.delayed(const Duration(milliseconds: 800));

    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;

    Widget nextScreen;
    if (widget.isLoggedIn) {
      if (currentProfile.value.id.isNotEmpty && !currentProfile.value.isApproved) {
        nextScreen = const PendingApprovalScreen();
      } else {
        nextScreen = const HomeLayout();
      }
    } else {
      nextScreen = const LoginScreen();
    }

    // Premium Cross-Fade to App
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
      ),
    );
  }

  double _getGifSize(GifSize size) {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (size) {
      case GifSize.small:
        return screenWidth * 0.4;
      case GifSize.large:
        return screenWidth * 0.8;
      case GifSize.medium:
        return screenWidth * 0.6;
      case GifSize.custom:
      default:
        return 350.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentSize = _getGifSize(GifSize.custom);

    return Scaffold(
      backgroundColor: Colors.black, // Matching your original provided code exactly
      body: Stack(
        children: [
          // ── CENTER ANIMATED GIF ──
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isExiting ? 0.0 : 1.0,
              child: Image.asset(
                'assets/branding/splash.gif',
                width: currentSize,
                height: currentSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}