import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark, night }

enum AppColorTheme {
  teal,
  blue,
  purple,
  green,
  amber,
  crimson,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();

  ThemeService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  AppThemeMode _themeMode = AppThemeMode.system;
  AppColorTheme _colorTheme = AppColorTheme.teal;

  AppThemeMode get themeMode => _themeMode;
  AppColorTheme get colorTheme => _colorTheme;

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    final savedMode = _prefs.getString('theme_mode');
    if (savedMode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
    }

    final savedColor = _prefs.getString('color_theme');
    if (savedColor != null) {
      _colorTheme = AppColorTheme.values.firstWhere(
        (e) => e.name == savedColor,
        orElse: () => AppColorTheme.teal,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setColorTheme(AppColorTheme theme) async {
    _colorTheme = theme;
    await _prefs.setString('color_theme', theme.name);
    notifyListeners();
  }

  Color get primaryColor {
    switch (_colorTheme) {
      case AppColorTheme.teal:
        return const Color(0xFF00ADB5);
      case AppColorTheme.blue:
        return const Color(0xFF1E88E5);
      case AppColorTheme.purple:
        return const Color(0xFF8E24AA);
      case AppColorTheme.green:
        return const Color(0xFF43A047);
      case AppColorTheme.amber:
        return const Color(0xFFFFB300);
      case AppColorTheme.crimson:
        return const Color(0xFFE53935);
    }
  }

  String get colorThemeName {
    switch (_colorTheme) {
      case AppColorTheme.teal:
        return 'Teal';
      case AppColorTheme.blue:
        return 'Ocean Blue';
      case AppColorTheme.purple:
        return 'Cosmic Purple';
      case AppColorTheme.green:
        return 'Emerald';
      case AppColorTheme.amber:
        return 'Amber';
      case AppColorTheme.crimson:
        return 'Crimson';
    }
  }

  ThemeMode get sdkThemeMode {
    switch (_themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.night:
        return ThemeMode.dark;
    }
  }

  ThemeData getThemeData(bool isDark) {
    final primary = primaryColor;
    
    if (isDark) {
      final isNight = _themeMode == AppThemeMode.night;
      final background = isNight ? Colors.black : const Color(0xFF1E2024);
      final container = isNight ? const Color(0xFF121212) : const Color(0xFF2A2D32);
      
      return ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          primary: primary,
          secondary: const Color(0xFFEEEEEE),
          surface: background,
          surfaceContainer: container,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: const Color(0xFF393E46),
          surface: const Color(0xFFF7F9FC),
          surfaceContainer: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      );
    }
  }
}
