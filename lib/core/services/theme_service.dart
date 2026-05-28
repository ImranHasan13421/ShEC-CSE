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
  custom,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();

  ThemeService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  AppThemeMode _themeMode = AppThemeMode.system;
  AppColorTheme _colorTheme = AppColorTheme.teal;
  int _customColorValue = 0xFF00ADB5;

  AppThemeMode get themeMode => _themeMode;
  AppColorTheme get colorTheme => _colorTheme;
  int get customColorValue => _customColorValue;

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

    _customColorValue = _prefs.getInt('custom_color_value') ?? 0xFF00ADB5;

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

  Future<void> setCustomColorValue(int value) async {
    _customColorValue = value;
    await _prefs.setInt('custom_color_value', value);
    if (_colorTheme == AppColorTheme.custom) {
      notifyListeners();
    }
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
      case AppColorTheme.custom:
        return Color(_customColorValue);
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
      case AppColorTheme.custom:
        return 'Custom';
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
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFFB0B3B8),
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: background.withValues(alpha: 0.92),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
          bodySmall: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600, fontSize: 16),
          titleSmall: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500, fontSize: 14),
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
          onSurface: const Color(0xFF0F172A), // Very high-contrast slate-900
          onSurfaceVariant: const Color(0xFF475569), // Readable slate-600
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF7F9FC).withValues(alpha: 0.92),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          actionsIconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF334155), fontSize: 14), // Readable slate-700
          bodySmall: TextStyle(color: Color(0xFF475569), fontSize: 12), // Readable slate-600
          titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 16),
          titleSmall: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500, fontSize: 14),
        ),
        useMaterial3: true,
      );
    }
  }
}
