//lib/main.dart/
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/auth/screens/splash_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/set_new_password_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';

import 'package:ShEC_CSE/core/services/theme_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Theme Service
  await ThemeService.instance.init();
  
  // Initialize listener with navigation capability
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()),
      );
    }
  });

  AuthService.initializeAuthListener();

  final session = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = session != null;

  runApp(ShEcCseApp(isLoggedIn: isLoggedIn));
}

class ShEcCseApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const ShEcCseApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final themeService = ThemeService.instance;
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'ShEC CSE',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.sdkThemeMode,
          theme: themeService.getThemeData(false),
          darkTheme: themeService.getThemeData(true),
          home: SplashScreen(isLoggedIn: isLoggedIn),
        );
      },
    );
  }
}