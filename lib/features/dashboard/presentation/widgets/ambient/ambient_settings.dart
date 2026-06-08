import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings-driven global ValueNotifiers for real-time live updates from any screen
final ValueNotifier<double> ambientAnimationSpeed = ValueNotifier(1.0); // Ranges from 0.2x to 3.0x
final ValueNotifier<int> ambientSparkleDensity = ValueNotifier(65); // Ranges from 10 to 150 particles
final ValueNotifier<bool> ambientBackgroundEnabled = ValueNotifier(true); // Toggle to completely turn off the ambient background
final ValueNotifier<String> ambientStyle = ValueNotifier('shec'); // Options: aurora, cyberpunk, cosmic, ocean, autumn, shec
final ValueNotifier<String> ambientPattern = ValueNotifier('none'); // Options: none, dots, grid, waves, stripes
final ValueNotifier<bool> ambientAuroraEnabled = ValueNotifier(true); // Toggle on/off for aesthetic dynamic blobs
final ValueNotifier<String> ambientWallpaper = ValueNotifier('none'); // Options: none, starry, geometric, wave, tech_grid
final ValueNotifier<bool> ambientWallpaperEnabled = ValueNotifier(true); // Toggle on/off for static wallpaper
final ValueNotifier<double> ambientWallpaperDensity = ValueNotifier(1.0); // Ranges from 0.5 to 2.0

class AmbientSettings {
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      ambientAnimationSpeed.value = prefs.getDouble('ambient_animation_speed') ?? 1.0;
      ambientSparkleDensity.value = prefs.getInt('ambient_sparkle_density') ?? 65;
      ambientBackgroundEnabled.value = prefs.getBool('ambient_background_enabled') ?? true;
      ambientStyle.value = prefs.getString('ambient_style') ?? 'shec';
      ambientPattern.value = prefs.getString('ambient_pattern') ?? 'none';
      ambientAuroraEnabled.value = prefs.getBool('ambient_aurora_enabled') ?? true;
      ambientWallpaper.value = prefs.getString('ambient_wallpaper') ?? 'none';
      ambientWallpaperEnabled.value = prefs.getBool('ambient_wallpaper_enabled') ?? true;
      ambientWallpaperDensity.value = prefs.getDouble('ambient_wallpaper_density') ?? 1.0;
    } catch (e) {
      debugPrint('Error loading ambient background settings: $e');
    }

    // Attach listener callbacks to persist state dynamically
    ambientAnimationSpeed.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ambient_animation_speed', ambientAnimationSpeed.value);
    });
    ambientSparkleDensity.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ambient_sparkle_density', ambientSparkleDensity.value);
    });
    ambientBackgroundEnabled.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ambient_background_enabled', ambientBackgroundEnabled.value);
    });
    ambientStyle.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ambient_style', ambientStyle.value);
    });
    ambientPattern.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ambient_pattern', ambientPattern.value);
    });
    ambientAuroraEnabled.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ambient_aurora_enabled', ambientAuroraEnabled.value);
    });
    ambientWallpaper.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ambient_wallpaper', ambientWallpaper.value);
    });
    ambientWallpaperEnabled.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ambient_wallpaper_enabled', ambientWallpaperEnabled.value);
    });
    ambientWallpaperDensity.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ambient_wallpaper_density', ambientWallpaperDensity.value);
    });
  }
}

enum TimePeriod { morning, afternoon, evening, night }

class AmbientColors {
  final Color color1;
  final Color color2;
  final Color color3;
  final Color baseBackground;
  final Color sparkleColor;

  AmbientColors({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.baseBackground,
    required this.sparkleColor,
  });
}

class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  final double randomOffset;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.randomOffset,
  });
}
