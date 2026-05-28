import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings-driven global ValueNotifiers for real-time live updates from any screen
final ValueNotifier<double> ambientAnimationSpeed = ValueNotifier(1.0); // Ranges from 0.2x to 3.0x
final ValueNotifier<int> ambientSparkleDensity = ValueNotifier(65); // Ranges from 10 to 150 particles
final ValueNotifier<bool> ambientBackgroundEnabled = ValueNotifier(true); // Toggle to completely turn off the ambient background
final ValueNotifier<String> ambientStyle = ValueNotifier('aurora'); // Options: aurora, cyberpunk, cosmic, ocean, autumn
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
      ambientStyle.value = prefs.getString('ambient_style') ?? 'aurora';
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

  @override
  void initState() {
    super.initState();
    
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
                          animationValue: _animationController.value,
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
                    timePeriod: _timePeriod,
                    showTimeSymbol: true, // Always true to render the glowing sun/moon in every mode!
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

class AuroraBlobsPainter extends CustomPainter {
  final double animationValue;
  final AmbientColors colors;
  final String style;
  final bool auroraEnabled;
  final bool isDark;
  final double speedFactor;

  AuroraBlobsPainter({
    required this.animationValue,
    required this.colors,
    required this.style,
    required this.auroraEnabled,
    required this.isDark,
    required this.speedFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background base color determination based on style settings
    Color baseBg = colors.baseBackground;
    
    if (style == 'cyberpunk' && auroraEnabled) {
      baseBg = const Color(0xFF07050A); // Extremely deep dark cyber void
    } else if (style == 'cosmic' && auroraEnabled) {
      baseBg = const Color(0xFF020107); // Absolute starry void black
    } else if (style == 'ocean' && auroraEnabled) {
      baseBg = const Color(0xFF040A12); // Deep abyssal ocean blue-black
    } else if (style == 'autumn' && auroraEnabled) {
      baseBg = const Color(0xFF0F0A06); // Deep rich forest bark brown-black
    }
    
    paint.color = baseBg;
    canvas.drawRect(Offset.zero & size, paint);

    // Dynamic style blobs driven by speed factor
    final double speededAnim = animationValue * speedFactor;

    if (auroraEnabled) {
      if (style == 'cyberpunk') {
        // Draw Magenta and Cyan glowing cyber-blobs
        final Color cyberColor1 = const Color(0xFFFF007F).withValues(alpha: isDark ? 0.22 : 0.36); // Neon Pink
        final Color cyberColor2 = const Color(0xFF00ADB5).withValues(alpha: isDark ? 0.22 : 0.36); // Neon Cyan

        final double angle1 = speededAnim * 2 * math.pi;
        final double dx1 = size.width * 0.3 + math.cos(angle1) * size.width * 0.22;
        final double dy1 = size.height * 0.3 + math.sin(angle1) * size.height * 0.12;
        paint.shader = RadialGradient(colors: [cyberColor1, cyberColor1.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.75));
        canvas.drawCircle(Offset(dx1, dy1), size.width * 0.75, paint);

        final double angle2 = (speededAnim + 0.5) * 2 * math.pi;
        final double dx2 = size.width * 0.7 + math.sin(angle2) * size.width * 0.22;
        final double dy2 = size.height * 0.7 + math.cos(angle2) * size.height * 0.12;
        paint.shader = RadialGradient(colors: [cyberColor2, cyberColor2.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.8));
        canvas.drawCircle(Offset(dx2, dy2), size.width * 0.8, paint);
        
      } else if (style == 'cosmic') {
        // Cosmic Nebula Circles (glowing deep violet & blue spaces)
        final Color spacePurple = const Color(0xFF7B2CBF).withValues(alpha: isDark ? 0.20 : 0.32);
        final Color spaceIndigo = const Color(0xFF3C096C).withValues(alpha: isDark ? 0.22 : 0.35);
        final Color spacePink = const Color(0xFFE0AAFF).withValues(alpha: isDark ? 0.12 : 0.22);

        final double angle1 = speededAnim * 2 * math.pi;
        final double dx1 = size.width * 0.5 + math.cos(angle1 * 0.5) * size.width * 0.25;
        final double dy1 = size.height * 0.4 + math.sin(angle1 * 0.5) * size.height * 0.15;
        paint.shader = RadialGradient(colors: [spacePurple, spacePurple.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.85));
        canvas.drawCircle(Offset(dx1, dy1), size.width * 0.85, paint);

        final double angle2 = (speededAnim + 0.3) * 2 * math.pi;
        final double dx2 = size.width * 0.4 + math.sin(angle2) * size.width * 0.22;
        final double dy2 = size.height * 0.7 + math.cos(angle2) * size.height * 0.12;
        paint.shader = RadialGradient(colors: [spaceIndigo, spaceIndigo.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.95));
        canvas.drawCircle(Offset(dx2, dy2), size.width * 0.95, paint);

        final double angle3 = (speededAnim + 0.6) * 2 * math.pi;
        final double dx3 = size.width * 0.6 + math.cos(angle3) * size.width * 0.22;
        final double dy3 = size.height * 0.5 + math.sin(angle3) * size.height * 0.12;
        paint.shader = RadialGradient(colors: [spacePink, spacePink.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: size.width * 0.7));
        canvas.drawCircle(Offset(dx3, dy3), size.width * 0.7, paint);

      } else if (style == 'ocean') {
        // Ocean calmness (teal, sky blue and marine green horizontal waves)
        final Color oceanTeal = const Color(0xFF00ADB5).withValues(alpha: isDark ? 0.20 : 0.32);
        final Color oceanBlue = const Color(0xFF1F4068).withValues(alpha: isDark ? 0.22 : 0.35);
        final Color oceanGreen = const Color(0xFF2E8B57).withValues(alpha: isDark ? 0.12 : 0.22);

        final double shift1 = math.sin(speededAnim * 2 * math.pi) * size.height * 0.08;
        paint.shader = RadialGradient(colors: [oceanTeal, oceanTeal.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(size.width * 0.3, size.height * 0.3 + shift1), radius: size.width * 0.9));
        canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3 + shift1), size.width * 0.9, paint);

        final double shift2 = math.cos((speededAnim + 0.5) * 2 * math.pi) * size.height * 0.08;
        paint.shader = RadialGradient(colors: [oceanBlue, oceanBlue.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(size.width * 0.7, size.height * 0.7 + shift2), radius: size.width * 0.95));
        canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7 + shift2), size.width * 0.95, paint);

        final double shift3 = math.sin((speededAnim + 0.25) * 2 * math.pi) * size.height * 0.06;
        paint.shader = RadialGradient(colors: [oceanGreen, oceanGreen.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.65 + shift3), radius: size.width * 0.75));
        canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.65 + shift3), size.width * 0.75, paint);

      } else if (style == 'autumn') {
        // Warm mahogany, amber and copper shades
        final Color autumnAmber = const Color(0xFFFFB300).withValues(alpha: isDark ? 0.20 : 0.32);
        final Color autumnCopper = const Color(0xFFD35400).withValues(alpha: isDark ? 0.22 : 0.35);
        final Color autumnRed = const Color(0xFFC0392B).withValues(alpha: isDark ? 0.12 : 0.22);

        final double angle1 = speededAnim * 2 * math.pi;
        final double dx1 = size.width * 0.3 + math.cos(angle1) * size.width * 0.22;
        final double dy1 = size.height * 0.35 + math.sin(angle1) * size.height * 0.10;
        paint.shader = RadialGradient(colors: [autumnAmber, autumnAmber.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.8));
        canvas.drawCircle(Offset(dx1, dy1), size.width * 0.8, paint);

        final double angle2 = (speededAnim + 0.4) * 2 * math.pi;
        final double dx2 = size.width * 0.7 + math.sin(angle2) * size.width * 0.22;
        final double dy2 = size.height * 0.65 + math.cos(angle2) * size.height * 0.10;
        paint.shader = RadialGradient(colors: [autumnCopper, autumnCopper.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.9));
        canvas.drawCircle(Offset(dx2, dy2), size.width * 0.9, paint);

        final double angle3 = (speededAnim + 0.7) * 2 * math.pi;
        final double dx3 = size.width * 0.4 + math.cos(angle3 * 1.2) * size.width * 0.15;
        final double dy3 = size.height * 0.5 + math.sin(angle3 * 1.2) * size.height * 0.12;
        paint.shader = RadialGradient(colors: [autumnRed, autumnRed.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: size.width * 0.75));
        canvas.drawCircle(Offset(dx3, dy3), size.width * 0.75, paint);

      } else {
        // DEFAULT TIME-BASED AURORA
        final double angle1 = speededAnim * 2 * math.pi;
        final double dx1 = size.width * 0.25 + math.cos(angle1) * size.width * 0.22;
        final double dy1 = size.height * 0.25 + math.sin(angle1) * size.height * 0.12;
        final double radius1 = size.width * 0.75;

        paint.shader = RadialGradient(
          colors: [colors.color1, colors.color1.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: radius1));
        canvas.drawCircle(Offset(dx1, dy1), radius1, paint);

        final double angle2 = (speededAnim + 0.33) * 2 * math.pi;
        final double dx2 = size.width * 0.75 + math.sin(angle2) * size.width * 0.22;
        final double dy2 = size.height * 0.75 + math.cos(angle2) * size.height * 0.12;
        final double radius2 = size.width * 0.8;

        paint.shader = RadialGradient(
          colors: [colors.color2, colors.color2.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: radius2));
        canvas.drawCircle(Offset(dx2, dy2), radius2, paint);

        final double angle3 = (speededAnim + 0.66) * 2 * math.pi;
        final double dx3 = size.width * 0.30 + math.cos(angle3 * 1.5) * size.width * 0.15;
        final double dy3 = size.height * 0.50 + math.sin(angle3 * 1.5) * size.height * 0.15;
        final double radius3 = size.width * 0.7;

        paint.shader = RadialGradient(
          colors: [colors.color3, colors.color3.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: radius3));
        canvas.drawCircle(Offset(dx3, dy3), radius3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AuroraBlobsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.colors != colors ||
        oldDelegate.style != style ||
        oldDelegate.auroraEnabled != auroraEnabled ||
        oldDelegate.isDark != isDark ||
        oldDelegate.speedFactor != speedFactor;
  }
}

class WallpaperAndPatternPainter extends CustomPainter {
  final AmbientColors colors;
  final Color primaryColor;
  final String pattern;
  final String wallpaper;
  final bool isDark;
  final TimePeriod timePeriod;
  final bool showTimeSymbol;
  final double density;
  final double animationValue;

  WallpaperAndPatternPainter({
    required this.colors,
    required this.primaryColor,
    required this.pattern,
    required this.wallpaper,
    required this.isDark,
    required this.timePeriod,
    required this.showTimeSymbol,
    required this.density,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double paintAlphaMultiplier = isDark ? 1.0 : 0.8;
    final double pulse = 0.5 + 0.5 * math.sin(animationValue * 2 * math.pi);

    // 1. Draw static background wallpapers (with boosted legibility)
    if (wallpaper != 'none') {
      if (wallpaper == 'starry') {
        final linePaint = Paint()
          ..color = isDark 
              ? Colors.white.withValues(alpha: 0.35) 
              : primaryColor.withValues(alpha: 0.26)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        
        // Draw constellation linkages
        canvas.drawLine(Offset(size.width * 0.15, size.height * 0.2), Offset(size.width * 0.35, size.height * 0.15), linePaint);
        canvas.drawLine(Offset(size.width * 0.35, size.height * 0.15), Offset(size.width * 0.45, size.height * 0.3), linePaint);
        canvas.drawLine(Offset(size.width * 0.45, size.height * 0.3), Offset(size.width * 0.25, size.height * 0.35), linePaint);
        canvas.drawLine(Offset(size.width * 0.25, size.height * 0.35), Offset(size.width * 0.15, size.height * 0.2), linePaint);
        
        canvas.drawLine(Offset(size.width * 0.65, size.height * 0.6), Offset(size.width * 0.8, size.height * 0.55), linePaint);
        canvas.drawLine(Offset(size.width * 0.8, size.height * 0.55), Offset(size.width * 0.9, size.height * 0.72), linePaint);
        canvas.drawLine(Offset(size.width * 0.9, size.height * 0.72), Offset(size.width * 0.7, size.height * 0.78), linePaint);
        canvas.drawLine(Offset(size.width * 0.7, size.height * 0.78), Offset(size.width * 0.65, size.height * 0.6), linePaint);

        // Star bodies with actual circular glows
        final starPaint = Paint()..color = isDark ? Colors.white.withValues(alpha: 0.75) : primaryColor.withValues(alpha: 0.60);
        canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 3.5, starPaint);
        canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.15), 4.2, starPaint);
        canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.3), 3.0, starPaint);
        canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.35), 3.5, starPaint);
        canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.6), 4.0, starPaint);
        canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.55), 3.0, starPaint);
        canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.72), 4.5, starPaint);
        canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.78), 3.5, starPaint);

        // EXTRA density starry constellations
        if (density > 1.2) {
          canvas.drawLine(Offset(size.width * 0.1, size.height * 0.5), Offset(size.width * 0.3, size.height * 0.48), linePaint);
          canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.5), 3.0, starPaint);
          canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.48), 3.5, starPaint);
        }
        if (density > 1.6) {
          canvas.drawLine(Offset(size.width * 0.5, size.height * 0.8), Offset(size.width * 0.7, size.height * 0.82), linePaint);
          canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), 3.0, starPaint);
          canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.82), 3.5, starPaint);
        }

      } else if (wallpaper == 'geometric') {
        final shapePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = (isDark ? colors.color1 : primaryColor).withValues(alpha: isDark ? 0.28 : 0.20);
        
        // Boosted overlapping circles and geometric bounds
        canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.28), size.width * 0.38 * density, shapePaint);
        shapePaint.color = (isDark ? colors.color2 : primaryColor).withValues(alpha: isDark ? 0.24 : 0.18);
        canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.72), size.width * 0.42 * density, shapePaint);
        
        shapePaint.color = (isDark ? colors.color3 : primaryColor).withValues(alpha: isDark ? 0.20 : 0.14);
        final Path diamond = Path()
          ..moveTo(size.width * 0.5, size.height * (0.42 - 0.20 * density))
          ..lineTo(size.width * (0.5 + 0.28 * density), size.height * 0.42)
          ..lineTo(size.width * 0.5, size.height * (0.42 + 0.20 * density))
          ..lineTo(size.width * (0.5 - 0.28 * density), size.height * 0.42)
          ..close();
        canvas.drawPath(diamond, shapePaint);

      } else if (wallpaper == 'wave') {
        final wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5; // Thickened waves
        
        final int waveCount = (3 * density).round().clamp(1, 6);
        for (int i = 0; i < waveCount; i++) {
          wavePaint.color = (i % 3 == 0 
              ? colors.color1 
              : i % 3 == 1 
                  ? colors.color2 
                  : colors.color3).withValues(alpha: isDark ? 0.35 : 0.25);
          final Path path = Path();
          final double startY = size.height * (0.2 + i * (0.6 / waveCount));
          path.moveTo(0, startY);
          for (double x = 0; x <= size.width; x += 10) {
            final double y = startY + math.sin(x / 45 + i) * 16;
            path.lineTo(x, y);
          }
          canvas.drawPath(path, wavePaint);
        }

      } else if (wallpaper == 'tech_grid') {
        final gridPaint = Paint()
          ..color = (isDark ? colors.color1 : primaryColor).withValues(alpha: isDark ? 0.24 : 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

        // Blueprint Grid
        final double spacing = 48.0 / density;
        for (double x = 0; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
        }

        // Tech crosshairs/dots
        final markPaint = Paint()
          ..color = (isDark ? colors.color2 : primaryColor).withValues(alpha: isDark ? 0.35 : 0.24)
          ..style = PaintingStyle.fill;
        
        for (double x = 0; x < size.width; x += spacing * 2) {
          for (double y = 0; y < size.height; y += spacing * 2) {
            canvas.drawCircle(Offset(x, y), 2.5, markPaint);
          }
        }
      }
    }

    // 2. Draw static background patterns
    if (pattern != 'none') {
      final patternPaint = Paint()
        ..color = (isDark ? Colors.white : primaryColor).withValues(alpha: isDark ? 0.22 * paintAlphaMultiplier : 0.16 * paintAlphaMultiplier)
        ..style = PaintingStyle.stroke;

      if (pattern == 'dots') {
        patternPaint.style = PaintingStyle.fill;
        final double spacing = 24.0 / density;
        for (double x = spacing / 2; x < size.width; x += spacing) {
          for (double y = spacing / 2; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 2.0, patternPaint); // Slightly larger dots
          }
        }
      } else if (pattern == 'grid') {
        patternPaint.strokeWidth = 1.0;
        final double spacing = 32.0 / density;
        for (double x = 0; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), patternPaint);
        }
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), patternPaint);
        }
      } else if (pattern == 'waves') {
        patternPaint.strokeWidth = 1.4;
        final double spacing = 40.0 / density;
        for (double y = spacing; y < size.height; y += spacing) {
          final Path path = Path();
          path.moveTo(0, y);
          for (double x = 0; x < size.width; x += 12) {
            path.lineTo(x, y + math.sin(x / 30) * 4);
          }
          canvas.drawPath(path, patternPaint);
        }
      } else if (pattern == 'stripes') {
        patternPaint.strokeWidth = 1.5;
        final double spacing = 45.0 / density;
        for (double i = -size.height; i < size.width; i += spacing) {
          canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), patternPaint);
        }
      }
    }

    // 3. Draw subtle, premium time-based symbols (Sunrise, Sun, Sunset, Moon) scaled up and eye-catching!
    if (showTimeSymbol) {
      // Outlines and Fills color adaptations based on theme brightness:
      // In Light Mode, lines are thick and highly visible.
      // In Dark/Night modes, lines are soft neon glows utilizing style palettes.
      final symbolPaint = Paint()
        ..color = isDark 
            ? colors.color1.withValues(alpha: isDark ? 0.50 : 0.40) 
            : primaryColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isDark ? 2.5 : 3.2;

      final fillPaint = Paint()
        ..color = isDark 
            ? colors.color2.withValues(alpha: isDark ? 0.18 : 0.12) 
            : primaryColor.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill;

      // Positioned in upper right quadrant - scaled and noticeable
      final Offset symCenter = Offset(size.width * 0.82, size.height * 0.12);

      switch (timePeriod) {
        case TimePeriod.morning: // Sunrise
          // Soft glowing aura that pulses breathing light
          final double morningGlowRadius = 30.0 + 8.0 * pulse;
          final morningGlowPaint = Paint()
            ..color = (isDark ? colors.color2 : primaryColor).withValues(alpha: (isDark ? 0.14 : 0.08) * pulse)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(symCenter, morningGlowRadius, morningGlowPaint);

          // Draw rising rays
          for (double angle = 0; angle <= math.pi; angle += math.pi / 4) {
            final double rayLen = 32 + 6.0 * (angle % 2 == 0 ? pulse : (1.0 - pulse));
            final double startX = symCenter.dx + math.cos(angle - math.pi) * 32;
            final double startY = symCenter.dy + math.sin(angle - math.pi) * 32;
            final double endX = symCenter.dx + math.cos(angle - math.pi) * rayLen;
            final double endY = symCenter.dy + math.sin(angle - math.pi) * rayLen;
            canvas.drawLine(Offset(startX, startY), Offset(endX, endY), symbolPaint..strokeWidth = 2.0);
          }

          // Sunrise half-circle
          canvas.drawLine(
            Offset(symCenter.dx - 48, symCenter.dy + 16),
            Offset(symCenter.dx + 48, symCenter.dy + 16),
            symbolPaint..strokeWidth = 2.0,
          );
          final rect = Rect.fromCircle(center: symCenter, radius: 30);
          canvas.drawArc(rect, math.pi, math.pi, false, fillPaint);
          canvas.drawArc(rect, math.pi, math.pi, false, symbolPaint..strokeWidth = isDark ? 2.5 : 3.2);
          break;

        case TimePeriod.afternoon: // Full Sun with glowing pulse
          // Soft breathing light halo
          final double sunGlowRadius = 28.0 + 10.0 * pulse;
          final sunGlowPaint = Paint()
            ..color = (isDark ? colors.color2 : primaryColor).withValues(alpha: (isDark ? 0.16 : 0.08) * (0.3 + 0.7 * pulse))
            ..style = PaintingStyle.fill;
          canvas.drawCircle(symCenter, sunGlowRadius, sunGlowPaint);
          canvas.drawCircle(symCenter, sunGlowRadius + 6.0 * (1.0 - pulse), Paint()..color = sunGlowPaint.color.withValues(alpha: sunGlowPaint.color.a * 0.4)..style = PaintingStyle.fill);

          // Animate radiating solar rays expanding/contracting
          for (int i = 0; i < 8; i++) {
            final double angle = i * math.pi / 4;
            final double rayLen = 34 + 6.0 * (i % 2 == 0 ? pulse : (1.0 - pulse));
            final double startX = symCenter.dx + math.cos(angle) * 34;
            final double startY = symCenter.dy + math.sin(angle) * 34;
            final double endX = symCenter.dx + math.cos(angle) * rayLen;
            final double endY = symCenter.dy + math.sin(angle) * rayLen;
            canvas.drawLine(Offset(startX, startY), Offset(endX, endY), symbolPaint..strokeWidth = 2.0);
          }

          // Central sun body
          canvas.drawCircle(symCenter, 28, fillPaint);
          canvas.drawCircle(symCenter, 28, symbolPaint..strokeWidth = isDark ? 2.5 : 3.2);
          break;

        case TimePeriod.evening: // Sunset
          // Evening glowing red/sunset aura
          final double eveningGlowRadius = 30.0 + 8.0 * pulse;
          final eveningGlowPaint = Paint()
            ..color = (isDark ? colors.color3 : primaryColor).withValues(alpha: (isDark ? 0.14 : 0.08) * pulse)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(symCenter.dx, symCenter.dy + 8), eveningGlowRadius, eveningGlowPaint);

          // Ray projections
          for (double angle = 0; angle <= math.pi; angle += math.pi / 4) {
            final double rayLen = 32 + 5.0 * pulse;
            final double startX = symCenter.dx + math.cos(angle - math.pi) * 32;
            final double startY = symCenter.dy + math.sin(angle - math.pi) * 32;
            final double endX = symCenter.dx + math.cos(angle - math.pi) * rayLen;
            final double endY = symCenter.dy + math.sin(angle - math.pi) * rayLen;
            canvas.drawLine(Offset(startX, startY), Offset(endX, endY), symbolPaint..strokeWidth = 2.0);
          }

          // Sunset half-circle and reflection ripples
          canvas.drawLine(
            Offset(symCenter.dx - 48, symCenter.dy + 16),
            Offset(symCenter.dx + 48, symCenter.dy + 16),
            symbolPaint..strokeWidth = 2.0,
          );
          final rectSunset = Rect.fromCircle(center: Offset(symCenter.dx, symCenter.dy + 8), radius: 30);
          canvas.drawArc(rectSunset, math.pi, math.pi, false, fillPaint);
          canvas.drawArc(rectSunset, math.pi, math.pi, false, symbolPaint..strokeWidth = isDark ? 2.5 : 3.2);

          canvas.drawLine(
            Offset(symCenter.dx - 32, symCenter.dy + 24),
            Offset(symCenter.dx + 32, symCenter.dy + 24),
            symbolPaint..strokeWidth = 1.5,
          );
          canvas.drawLine(
            Offset(symCenter.dx - 16, symCenter.dy + 32),
            Offset(symCenter.dx + 16, symCenter.dy + 32),
            symbolPaint..strokeWidth = 1.5,
          );
          break;

        case TimePeriod.night: // Crescent Moon with glowing halo
          // Pulsing moon halo
          final double moonGlowRadius = 24.0 + 8.0 * pulse;
          final moonGlowPaint = Paint()
            ..color = (isDark ? colors.color2 : primaryColor).withValues(alpha: (isDark ? 0.16 : 0.08) * (0.3 + 0.7 * pulse))
            ..style = PaintingStyle.fill;
          canvas.drawCircle(symCenter, moonGlowRadius, moonGlowPaint);

          // Beautiful scaled crescent moon path
          final Path moonPath = Path()
            ..moveTo(symCenter.dx + 12, symCenter.dy - 30)
            ..quadraticBezierTo(symCenter.dx - 26, symCenter.dy, symCenter.dx + 12, symCenter.dy + 30)
            ..quadraticBezierTo(symCenter.dx - 8, symCenter.dy, symCenter.dx + 12, symCenter.dy - 30)
            ..close();
          canvas.drawPath(moonPath, fillPaint);
          canvas.drawPath(moonPath, symbolPaint..strokeWidth = isDark ? 2.5 : 3.2);

          // Glowing space star next to the moon that blinks in alternate rhythm
          final double starPulse = 1.0 - pulse;
          final starPaint = Paint()
            ..color = (isDark ? Colors.white : primaryColor).withValues(alpha: (isDark ? 0.35 : 0.25) + 0.5 * starPulse)
            ..style = PaintingStyle.fill;
          
          final Path starPath = Path()
            ..moveTo(symCenter.dx - 28, symCenter.dy - 12)
            ..quadraticBezierTo(symCenter.dx - 24, symCenter.dy - 12, symCenter.dx - 24, symCenter.dy - 16)
            ..quadraticBezierTo(symCenter.dx - 24, symCenter.dy - 12, symCenter.dx - 20, symCenter.dy - 12)
            ..quadraticBezierTo(symCenter.dx - 24, symCenter.dy - 12, symCenter.dx - 24, symCenter.dy - 8)
            ..quadraticBezierTo(symCenter.dx - 24, symCenter.dy - 12, symCenter.dx - 28, symCenter.dy - 12)
            ..close();
          canvas.drawPath(starPath, starPaint);
          
          canvas.drawCircle(Offset(symCenter.dx - 18, symCenter.dy + 14), 3.0, starPaint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant WallpaperAndPatternPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.pattern != pattern ||
        oldDelegate.wallpaper != wallpaper ||
        oldDelegate.isDark != isDark ||
        oldDelegate.timePeriod != timePeriod ||
        oldDelegate.showTimeSymbol != showTimeSymbol ||
        oldDelegate.density != density ||
        oldDelegate.animationValue != animationValue;
  }
}

class SparklesPainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;
  final Color sparkleColor;
  final double speedFactor;
  final int density;
  final String style;
  final bool isDark;

  SparklesPainter({
    required this.animationValue,
    required this.particles,
    required this.sparkleColor,
    required this.speedFactor,
    required this.density,
    required this.style,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamically limit drawing loop to the selected density preference
    final paintCount = math.min(density, particles.length);

    for (int i = 0; i < paintCount; i++) {
      final particle = particles[i];

      // Dynamically adjust starting bounds if they exceed canvas size
      if (particle.x > size.width) {
        particle.x = math.Random().nextDouble() * size.width;
      }
      if (particle.y > size.height) {
        particle.y = math.Random().nextDouble() * size.height;
      }

      // PHYSICS & MOVEMENT LOGIC PER STYLE
      if (style == 'cyberpunk') {
        // Digital horizontal flow (right to left)
        particle.x -= particle.speed * speedFactor * 2.0;
        
        // Reset horizontal
        if (particle.x < -10) {
          particle.x = size.width + 10;
          particle.y = math.Random().nextDouble() * size.height;
        }
      } else if (style == 'cosmic') {
        // expanding starfield centered
        final double centerX = size.width / 2;
        final double centerY = size.height / 2;

        double dx = particle.x - centerX;
        double dy = particle.y - centerY;
        double radius = math.sqrt(dx * dx + dy * dy);
        double angle = math.atan2(dy, dx);

        // expansion physics
        radius += particle.speed * speedFactor * 4.0;
        if (radius > math.max(size.width, size.height)) {
          radius = 5 + math.Random().nextDouble() * 20; // reset near center
          angle = math.Random().nextDouble() * 2 * math.pi;
        }

        particle.x = centerX + math.cos(angle) * radius;
        particle.y = centerY + math.sin(angle) * radius;
      } else if (style == 'ocean') {
        // gentle upward bubble floating
        particle.y -= particle.speed * speedFactor * 0.7;
        particle.x += math.sin(animationValue * 2 * math.pi + particle.randomOffset) * 0.4;

        if (particle.y < -15) {
          particle.y = size.height + 15;
          particle.x = math.Random().nextDouble() * size.width;
        }
      } else if (style == 'autumn') {
        // gentle diagonal fall wind (top-right to bottom-left)
        particle.y += particle.speed * speedFactor * 1.2;
        particle.x -= particle.speed * speedFactor * 0.8;

        if (particle.y > size.height + 15 || particle.x < -15) {
          particle.y = -15;
          particle.x = math.Random().nextDouble() * (size.width + 100);
        }
      } else {
        // Default Aurora drift upward
        particle.y -= particle.speed * speedFactor;
        particle.x += math.sin(animationValue * 2 * math.pi + particle.randomOffset) * 0.35;

        // Reset if off-screen
        if (particle.y < -10) {
          particle.y = size.height + 10;
          particle.x = math.Random().nextDouble() * size.width;
        }
      }

      // COLORS & SHAPES PAINTING PER STYLE
      final paint = Paint()..style = PaintingStyle.fill;
      
      // Color choices
      Color pColor = sparkleColor;
      if (!isDark) {
        // In light mode, map white/cyan/yellow to deeper rich saturated variants so they pop on white scaffolds
        if (style == 'cyberpunk') {
          pColor = i % 2 == 0 ? const Color(0xFFD0006F) : const Color(0xFF007E85);
        } else if (style == 'cosmic') {
          pColor = const Color(0xFF5E35B1); // Deep rich cosmic violet sparkles instead of white!
        } else if (style == 'ocean') {
          pColor = const Color(0xFF006064); // Dark cyan/blue bubble rings instead of light cyan!
        } else if (style == 'autumn') {
          pColor = i % 3 == 0 
              ? const Color(0xFFB33600) // Deep warm rust orange
              : i % 3 == 1 
                  ? const Color(0xFFC48600) // Deep gold
                  : const Color(0xFF8B0000); // Deep crimson
        } else {
          // Default time-based: ensure it has rich visibility
          pColor = sparkleColor.withValues(alpha: 1.0);
        }
      } else {
        // Dark mode colors (original)
        if (style == 'cyberpunk') {
          pColor = i % 2 == 0 ? const Color(0xFFFF007F) : const Color(0xFF00F5FF);
        } else if (style == 'cosmic') {
          pColor = Colors.white;
        } else if (style == 'ocean') {
          pColor = Colors.cyanAccent;
        } else if (style == 'autumn') {
          pColor = i % 3 == 0 
              ? const Color(0xFFD35400)
              : i % 3 == 1 
                  ? const Color(0xFFFFB300)
                  : const Color(0xFFC0392B);
        }
      }

      final double opacityFactor = isDark ? 0.55 : 0.90;
      paint.color = pColor.withValues(alpha: particle.opacity * opacityFactor);

      if (style == 'cyberpunk') {
        // Square code motes
        final rect = Rect.fromCenter(
          center: Offset(particle.x, particle.y),
          width: particle.size * 1.3,
          height: particle.size * 1.3,
        );
        canvas.drawRect(rect, paint);
      } else if (style == 'ocean') {
        // Hollow floating bubble rings
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.8;
        canvas.drawCircle(Offset(particle.x, particle.y), particle.size * 1.6, paint);
      } else if (style == 'autumn') {
        // Diamond leaf shape path
        final Path leafPath = Path()
          ..moveTo(particle.x, particle.y - particle.size)
          ..lineTo(particle.x + particle.size * 0.8, particle.y)
          ..lineTo(particle.x, particle.y + particle.size)
          ..lineTo(particle.x - particle.size * 0.8, particle.y)
          ..close();
        canvas.drawPath(leafPath, paint);
      } else {
        // Circular sparkly sparkles
        canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SparklesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.particles != particles ||
        oldDelegate.sparkleColor != sparkleColor ||
        oldDelegate.speedFactor != speedFactor ||
        oldDelegate.density != density ||
        oldDelegate.style != style ||
        oldDelegate.isDark != isDark;
  }
}
