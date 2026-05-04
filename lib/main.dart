//lib/main.dart/
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/features/auth/screens/splash_screen.dart';
import 'package:ShEC_CSE/features/auth/screens/set_new_password_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ShEC_CSE/backend/services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ShEC CSE',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00ADB5),
          brightness: Brightness.light,
          primary: const Color(0xFF00ADB5),
          secondary: const Color(0xFF393E46),
          surface: const Color(0xFFF7F9FC),
          surfaceContainer: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00ADB5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00ADB5),
          brightness: Brightness.dark,
          primary: const Color(0xFF00ADB5),
          secondary: const Color(0xFFEEEEEE),
          surface: const Color(0xFF1E2024),
          surfaceContainer: const Color(0xFF2A2D32),
        ),
        scaffoldBackgroundColor: const Color(0xFF1E2024),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E2024),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(isLoggedIn: isLoggedIn),
    );
  }
}