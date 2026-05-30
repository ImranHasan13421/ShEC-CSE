import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'ambient_settings.dart';
import 'painters/aurora_blobs_painter.dart';
import 'painters/wallpaper_pattern_painter.dart';
import 'painters/sparkles_painter.dart';

class AmbientTimeBackground extends StatefulWidget {
  final Widget child;
  final bool useSafeArea;
  final bool? overrideEnabled;
  final double? overrideSpeed;
  final int? overrideDensity;
  final String? overrideStyle;
  final ColorScheme? overrideColorScheme;
  final String? overridePattern;
  final bool? overrideAuroraEnabled;
  final String? overrideWallpaper;
  final bool? overrideWallpaperEnabled;
  final double? overrideWallpaperDensity;

  const AmbientTimeBackground({
    super.key,
    required this.child,
    this.useSafeArea = false,
    this.overrideEnabled,
    this.overrideSpeed,
    this.overrideDensity,
    this.overrideStyle,
    this.overrideColorScheme,
    this.overridePattern,
    this.overrideAuroraEnabled,
    this.overrideWallpaper,
    this.overrideWallpaperEnabled,
    this.overrideWallpaperDensity,
  });

  @override
  State<AmbientTimeBackground> createState() => _AmbientTimeBackgroundState();
}

class _AmbientTimeBackgroundState extends State<AmbientTimeBackground> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  TimePeriod _timePeriod = TimePeriod.night;
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    // 12-second continuous looping duration for highly visible yet smooth flow
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _updateTimePeriod();

    // Pre-initialize exactly 150 high-density sparkles to support sliders seamlessly without allocations
    for (int i = 0; i < 150; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * 500, // Safe starting width
          y: _random.nextDouble() * 1000, // Safe starting height
          speed: 0.3 + _random.nextDouble() * 0.7, // Drifting speeds
          size: 1.2 + _random.nextDouble() * 2.8, // Sparkle sizes
          opacity: 0.2 + _random.nextDouble() * 0.6, // Base opacities
          randomOffset: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateTimePeriod() {
    final hour = DateTime.now().hour;
    TimePeriod currentPeriod;
    if (hour >= 5 && hour < 12) {
      currentPeriod = TimePeriod.morning;
    } else if (hour >= 12 && hour < 17) {
      currentPeriod = TimePeriod.afternoon;
    } else if (hour >= 17 && hour < 21) {
      currentPeriod = TimePeriod.evening;
    } else {
      currentPeriod = TimePeriod.night;
    }

    if (currentPeriod != _timePeriod) {
      setState(() {
        _timePeriod = currentPeriod;
      });
    }
  }

  AmbientColors _getColors(BuildContext context) {
    final colorScheme = widget.overrideColorScheme ?? Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final baseBg = colorScheme.surface;

    // Enhanced opacities for both Light theme (0.50 - 0.70) and Dark theme (0.45 - 0.55) to make auroras glow intensely
    // Sparkle colors dynamically shift to colored motes in Light theme so they contrast cleanly.
    switch (_timePeriod) {
      case TimePeriod.morning: // Sunrise Golden Yellow & Vibrant Orange Glow
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.48 : 0.68),
          color2: const Color(0xFFFF9100).withValues(alpha: isDark ? 0.42 : 0.62), // Orange Glow
          color3: const Color(0xFFFFD600).withValues(alpha: isDark ? 0.38 : 0.58), // Bright Golden Yellow
          baseBackground: baseBg,
          sparkleColor: isDark ? const Color(0xFFFFD600) : const Color(0xFFFF9100),
        );
      case TimePeriod.afternoon: // Sky Cyan & Radiant Energetic Green
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.48 : 0.68),
          color2: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.42 : 0.62), // Cyan
          color3: const Color(0xFF00E676).withValues(alpha: isDark ? 0.35 : 0.55), // Emerald Green
          baseBackground: baseBg,
          sparkleColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00E676),
        );
      case TimePeriod.evening: // Sunset Crimson & Twilight Magenta
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.52 : 0.72),
          color2: const Color(0xFFFF1744).withValues(alpha: isDark ? 0.48 : 0.68), // Twilight Crimson Red
          color3: const Color(0xFFD500F9).withValues(alpha: isDark ? 0.42 : 0.62), // Twilight Neon Magenta
          baseBackground: baseBg,
          sparkleColor: isDark ? const Color(0xFFD500F9) : const Color(0xFFFF1744),
        );
      case TimePeriod.night: // Cosmic Neon Blue & Cyber Purple
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.45 : 0.65),
          color2: const Color(0xFF2979FF).withValues(alpha: isDark ? 0.40 : 0.60), // Electric Blue
          color3: const Color(0xFF651FFF).withValues(alpha: isDark ? 0.35 : 0.55), // Cyber Indigo Purple
          baseBackground: baseBg,
          sparkleColor: isDark ? const Color(0xFF2979FF) : const Color(0xFF651FFF),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateTimePeriod(); // Ensure time context is updated on active rebuilds
    final colors = _getColors(context);

    // ListenableBuilder merges animation tickers with user preferences to enable live adjustments on the fly
    return ListenableBuilder(
      listenable: Listenable.merge([
        _animationController,
        ambientAnimationSpeed,
        ambientSparkleDensity,
        ambientBackgroundEnabled,
        ambientStyle,
        ambientPattern,
        ambientAuroraEnabled,
        ambientWallpaper,
        ambientWallpaperEnabled,
        ambientWallpaperDensity,
      ]),
      builder: (context, _) {
        final speedFactor = widget.overrideSpeed ?? ambientAnimationSpeed.value;
        final densityCount = widget.overrideDensity ?? ambientSparkleDensity.value;
        final isSparklesEnabled = widget.overrideEnabled ?? ambientBackgroundEnabled.value;
        final currentStyle = widget.overrideStyle ?? ambientStyle.value;
        final ColorScheme activeScheme = widget.overrideColorScheme ?? Theme.of(context).colorScheme;
        final isDark = activeScheme.brightness == Brightness.dark;
        final isAuroraEnabled = !isDark ? false : (widget.overrideAuroraEnabled ?? ambientAuroraEnabled.value);
        final isWallpaperEnabled = widget.overrideWallpaperEnabled ?? ambientWallpaperEnabled.value;
        final currentWallpaper = isWallpaperEnabled ? (widget.overrideWallpaper ?? ambientWallpaper.value) : 'none';
        final currentPattern = isWallpaperEnabled ? (widget.overridePattern ?? ambientPattern.value) : 'none';
        final currentWallpaperDensity = widget.overrideWallpaperDensity ?? ambientWallpaperDensity.value;
        final double elapsedSeconds = DateTime.now().difference(_startTime).inMilliseconds / 1000.0;

        // Base background color determination matching the active style, providing an opaque backdrop
        Color baseBg = colors.baseBackground;
        if (isDark) {
          if (currentStyle == 'cyberpunk') {
            baseBg = const Color(0xFF07050A);
          } else if (currentStyle == 'cosmic') {
            baseBg = const Color(0xFF020107);
          } else if (currentStyle == 'ocean') {
            baseBg = const Color(0xFF040A12);
          } else if (currentStyle == 'autumn') {
            baseBg = const Color(0xFF0F0A06);
          }
        }

        return Stack(
          children: [
            // 0. Solid Base Opaque Background (Prevents behind-drawer elements from bleeding through when drawer is closed or dynamic auroras are toggled off)
            Positioned.fill(
              child: Container(
                color: baseBg,
              ),
            ),
            // 1. Slow Aurora Mesh Blobs Layer (Rendered below blur)
            Positioned.fill(
              child: isAuroraEnabled
                  ? RepaintBoundary(
                      child: CustomPaint(
                        painter: AuroraBlobsPainter(
                          animationValue: elapsedSeconds,
                          colors: colors,
                          style: currentStyle,
                          auroraEnabled: isAuroraEnabled,
                          isDark: isDark,
                          speedFactor: speedFactor,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // 2. High-Performance Gaussian Soft Blur (Only rendered when dynamic auroras are enabled to diffuse colors)
            Positioned.fill(
              child: isAuroraEnabled
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                      child: Container(color: Colors.transparent),
                    )
                  : const SizedBox.shrink(),
            ),
            // 3. Crisp, Static Background Wallpaper and Pattern Layer (Drawn OVER the blurred auroras so they stay crisp and sharp!)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: WallpaperAndPatternPainter(
                    colors: colors,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    pattern: currentPattern,
                    wallpaper: currentWallpaper,
                    isDark: isDark,
                    density: currentWallpaperDensity,
                    animationValue: _animationController.value, // Pass animation value for custom pulsing light effect!
                  ),
                ),
              ),
            ),
            // 4. Crisp, High-Density Sparkles floating over the backdrop (Only rendered when sparkles are enabled)
            Positioned.fill(
              child: isSparklesEnabled
                  ? RepaintBoundary(
                      child: CustomPaint(
                        painter: SparklesPainter(
                          animationValue: _animationController.value,
                          particles: _particles,
                          sparkleColor: colors.sparkleColor,
                          speedFactor: speedFactor,
                          density: densityCount,
                          style: currentStyle,
                          isDark: isDark,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // 5. Child Content Layer (Always structurally stable!)
            Positioned.fill(
              child: widget.useSafeArea ? SafeArea(child: widget.child) : widget.child,
            ),
          ],
        );
      },
    );
  }
}
