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

    // Enhanced opacities for Light theme (0.45 - 0.65) to prevent colors from washing out on white Scaffolds.
    // Sparkle colors dynamically shift to colored motes in Light theme so they contrast cleanly.
    switch (_timePeriod) {
      case TimePeriod.morning:
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.30 : 0.65),
          color2: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.25 : 0.60), // Amber
          color3: const Color(0xFFFF7043).withValues(alpha: isDark ? 0.20 : 0.50), // Peach/Coral
          baseBackground: baseBg,
          sparkleColor: isDark ? Colors.white : const Color(0xFFFFB300),
        );
      case TimePeriod.afternoon:
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.30 : 0.65),
          color2: const Color(0xFF00ADB5).withValues(alpha: isDark ? 0.25 : 0.60), // Teal
          color3: const Color(0xFF42A5F5).withValues(alpha: isDark ? 0.20 : 0.50), // Sky Blue
          baseBackground: baseBg,
          sparkleColor: isDark ? Colors.white : const Color(0xFF00ADB5),
        );
      case TimePeriod.evening:
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.30 : 0.65),
          color2: const Color(0xFFAB47BC).withValues(alpha: isDark ? 0.25 : 0.60), // Muted Purple
          color3: const Color(0xFFEC407A).withValues(alpha: isDark ? 0.20 : 0.50), // Rose/Sunset
          baseBackground: baseBg,
          sparkleColor: isDark ? Colors.white : const Color(0xFFEC407A),
        );
      case TimePeriod.night:
        return AmbientColors(
          color1: primary.withValues(alpha: isDark ? 0.25 : 0.60),
          color2: const Color(0xFF3F51B5).withValues(alpha: isDark ? 0.20 : 0.50), // Indigo
          color3: const Color(0xFF1A237E).withValues(alpha: isDark ? 0.15 : 0.45), // Midnight Space Blue
          baseBackground: baseBg,
          sparkleColor: isDark ? Colors.white : const Color(0xFF3F51B5),
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
      ]),
      builder: (context, _) {
        final speedFactor = widget.overrideSpeed ?? ambientAnimationSpeed.value;
        final densityCount = widget.overrideDensity ?? ambientSparkleDensity.value;
        final isSparklesEnabled = widget.overrideEnabled ?? ambientBackgroundEnabled.value;
        final currentStyle = widget.overrideStyle ?? ambientStyle.value;
        final currentPattern = widget.overridePattern ?? ambientPattern.value;
        final isAuroraEnabled = widget.overrideAuroraEnabled ?? ambientAuroraEnabled.value;
        final currentWallpaper = widget.overrideWallpaper ?? ambientWallpaper.value;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Draw flat container only if absolutely nothing is enabled (no sparkles, no auroras, no patterns, no custom wallpapers)
        if (!isSparklesEnabled && !isAuroraEnabled && currentPattern == 'none' && currentWallpaper == 'none') {
          return Container(
            color: colors.baseBackground,
            child: widget.useSafeArea ? SafeArea(child: widget.child) : widget.child,
          );
        }

        return Stack(
          children: [
            // 1. Slow Aurora Mesh Blobs / Wallpapers / Patterns Layer
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: AuroraBlobsPainter(
                    animationValue: _animationController.value,
                    colors: colors,
                    style: currentStyle,
                    pattern: currentPattern,
                    auroraEnabled: isAuroraEnabled,
                    wallpaper: currentWallpaper,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            // 2. High-Performance Gaussian Soft Blur (Only rendered when dynamic auroras are enabled to diffuse colors)
            if (isAuroraEnabled)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(color: Colors.transparent),
                ),
              ),
            // 3. Crisp, High-Density Sparkles floating over the blurred backdrop (Only rendered when sparkles are enabled)
            if (isSparklesEnabled)
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: SparklesPainter(
                      animationValue: _animationController.value,
                      particles: _particles,
                      sparkleColor: colors.sparkleColor,
                      speedFactor: speedFactor,
                      density: densityCount,
                      style: currentStyle,
                    ),
                  ),
                ),
              ),
            // 4. Child Content Layer
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
  final String pattern;
  final bool auroraEnabled;
  final String wallpaper;
  final bool isDark;

  AuroraBlobsPainter({
    required this.animationValue,
    required this.colors,
    required this.style,
    required this.pattern,
    required this.auroraEnabled,
    required this.wallpaper,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background color determination
    Color baseBg = colors.baseBackground;
    
    if (wallpaper == 'starry') {
      baseBg = const Color(0xFF02020A); // Very deep starry space void
    } else if (wallpaper == 'geometric') {
      baseBg = isDark ? const Color(0xFF0C0B12) : const Color(0xFFF3F5F9);
    } else if (wallpaper == 'wave') {
      baseBg = isDark ? const Color(0xFF06060E) : const Color(0xFFF9FAFD);
    } else if (wallpaper == 'tech_grid') {
      baseBg = isDark ? const Color(0xFF07090F) : const Color(0xFFEFF1F6);
    } else {
      // Standard style background fallback
      if (style == 'cyberpunk' && auroraEnabled) {
        baseBg = const Color(0xFF0C0B10); // Extremely dark cyber slate
      } else if (style == 'cosmic' && auroraEnabled) {
        baseBg = const Color(0xFF03020A); // Deep void black
      } else if (style == 'ocean' && auroraEnabled) {
        baseBg = const Color(0xFF08121E); // Deep ocean abyssal navy
      } else if (style == 'autumn' && auroraEnabled) {
        baseBg = const Color(0xFF1B110B); // Warm forest bark brown
      }
    }
    
    paint.color = baseBg;
    canvas.drawRect(Offset.zero & size, paint);

    // Render wallpaper designs if active
    if (wallpaper != 'none') {
      if (wallpaper == 'starry') {
        // Draw static constellation lines
        final linePaint = Paint()
          ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        
        // Draw constellations
        canvas.drawLine(Offset(size.width * 0.15, size.height * 0.2), Offset(size.width * 0.35, size.height * 0.15), linePaint);
        canvas.drawLine(Offset(size.width * 0.35, size.height * 0.15), Offset(size.width * 0.45, size.height * 0.3), linePaint);
        canvas.drawLine(Offset(size.width * 0.45, size.height * 0.3), Offset(size.width * 0.25, size.height * 0.35), linePaint);
        canvas.drawLine(Offset(size.width * 0.25, size.height * 0.35), Offset(size.width * 0.15, size.height * 0.2), linePaint);
        
        canvas.drawLine(Offset(size.width * 0.65, size.height * 0.6), Offset(size.width * 0.8, size.height * 0.55), linePaint);
        canvas.drawLine(Offset(size.width * 0.8, size.height * 0.55), Offset(size.width * 0.9, size.height * 0.72), linePaint);
        canvas.drawLine(Offset(size.width * 0.9, size.height * 0.72), Offset(size.width * 0.7, size.height * 0.78), linePaint);
        canvas.drawLine(Offset(size.width * 0.7, size.height * 0.78), Offset(size.width * 0.65, size.height * 0.6), linePaint);

        // Glowing star dots
        final starPaint = Paint()..color = isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25);
        canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 2.5, starPaint);
        canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.15), 3.2, starPaint);
        canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.3), 2.0, starPaint);
        canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.35), 2.5, starPaint);
        canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.6), 3.0, starPaint);
        canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.55), 2.0, starPaint);
        canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.72), 3.5, starPaint);
        canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.78), 2.5, starPaint);
      } else if (wallpaper == 'geometric') {
        final shapePaint = Paint()
          ..style = PaintingStyle.fill
          ..color = colors.color1.withValues(alpha: isDark ? 0.045 : 0.035);
        
        // Drawing overlapping circles and large diamond shapes
        canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.28), size.width * 0.38, shapePaint);
        shapePaint.color = colors.color2.withValues(alpha: isDark ? 0.035 : 0.025);
        canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.72), size.width * 0.42, shapePaint);
        
        shapePaint.color = colors.color3.withValues(alpha: isDark ? 0.025 : 0.015);
        final Path diamond = Path()
          ..moveTo(size.width * 0.5, size.height * 0.22)
          ..lineTo(size.width * 0.78, size.height * 0.42)
          ..lineTo(size.width * 0.5, size.height * 0.62)
          ..lineTo(size.width * 0.22, size.height * 0.42)
          ..close();
        canvas.drawPath(diamond, shapePaint);
      } else if (wallpaper == 'wave') {
        final wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        
        for (int i = 0; i < 3; i++) {
          wavePaint.color = (i == 0 
              ? colors.color1 
              : i == 1 
                  ? colors.color2 
                  : colors.color3).withValues(alpha: isDark ? 0.08 : 0.05);
          final Path path = Path();
          final double startY = size.height * (0.3 + i * 0.22);
          path.moveTo(0, startY);
          for (double x = 0; x <= size.width; x += 10) {
            final double y = startY + math.sin(x / 45 + i) * 16;
            path.lineTo(x, y);
          }
          canvas.drawPath(path, wavePaint);
        }
      } else if (wallpaper == 'tech_grid') {
        final gridPaint = Paint()
          ..color = colors.color1.withValues(alpha: isDark ? 0.03 : 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

        // Grid lines
        const double spacing = 48.0;
        for (double x = 0; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
        }

        // Concentric technology crosshairs/dots
        final markPaint = Paint()
          ..color = colors.color2.withValues(alpha: isDark ? 0.06 : 0.04)
          ..style = PaintingStyle.fill;
        
        for (double x = 0; x < size.width; x += spacing * 2) {
          for (double y = 0; y < size.height; y += spacing * 2) {
            canvas.drawCircle(Offset(x, y), 1.8, markPaint);
          }
        }
      }
    }

    // Dynamic style blobs
    if (auroraEnabled) {
      if (style == 'cyberpunk') {
      // 1. Neon Cyber Grids (Draw standard lines with opacity for digital feel)
      final gridPaint = Paint()
        ..color = colors.color1.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      const double gap = 40.0;
      for (double x = 0; x < size.width; x += gap) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

      // Draw Magenta and Cyan glowing cyber-blobs
      final Color cyberColor1 = const Color(0xFFFF007F).withValues(alpha: 0.15); // Neon Pink
      final Color cyberColor2 = const Color(0xFF00ADB5).withValues(alpha: 0.15); // Neon Cyan

      final double angle1 = animationValue * 2 * math.pi;
      final double dx1 = size.width * 0.3 + math.cos(angle1) * size.width * 0.1;
      final double dy1 = size.height * 0.3 + math.sin(angle1) * size.height * 0.05;
      paint.shader = RadialGradient(colors: [cyberColor1, cyberColor1.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.6));
      canvas.drawCircle(Offset(dx1, dy1), size.width * 0.6, paint);

      final double angle2 = (animationValue + 0.5) * 2 * math.pi;
      final double dx2 = size.width * 0.7 + math.sin(angle2) * size.width * 0.1;
      final double dy2 = size.height * 0.7 + math.cos(angle2) * size.height * 0.05;
      paint.shader = RadialGradient(colors: [cyberColor2, cyberColor2.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.65));
      canvas.drawCircle(Offset(dx2, dy2), size.width * 0.65, paint);
      
    } else if (style == 'cosmic') {
      // Cosmic Nebula Circles (glowing deep violet & blue spaces)
      final Color spacePurple = const Color(0xFF7B2CBF).withValues(alpha: 0.12);
      final Color spaceIndigo = const Color(0xFF3C096C).withValues(alpha: 0.15);
      final Color spacePink = const Color(0xFFE0AAFF).withValues(alpha: 0.08);

      final double angle1 = animationValue * 2 * math.pi;
      final double dx1 = size.width * 0.5 + math.cos(angle1 * 0.5) * size.width * 0.15;
      final double dy1 = size.height * 0.4 + math.sin(angle1 * 0.5) * size.height * 0.1;
      paint.shader = RadialGradient(colors: [spacePurple, spacePurple.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.75));
      canvas.drawCircle(Offset(dx1, dy1), size.width * 0.75, paint);

      final double angle2 = (animationValue + 0.3) * 2 * math.pi;
      final double dx2 = size.width * 0.4 + math.sin(angle2) * size.width * 0.12;
      final double dy2 = size.height * 0.7 + math.cos(angle2) * size.height * 0.08;
      paint.shader = RadialGradient(colors: [spaceIndigo, spaceIndigo.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.8));
      canvas.drawCircle(Offset(dx2, dy2), size.width * 0.8, paint);

      final double angle3 = (animationValue + 0.6) * 2 * math.pi;
      final double dx3 = size.width * 0.6 + math.cos(angle3) * size.width * 0.1;
      final double dy3 = size.height * 0.5 + math.sin(angle3) * size.height * 0.08;
      paint.shader = RadialGradient(colors: [spacePink, spacePink.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: size.width * 0.5));
      canvas.drawCircle(Offset(dx3, dy3), size.width * 0.5, paint);

    } else if (style == 'ocean') {
      // Ocean calmness (teal, sky blue and marine green horizontal waves)
      final Color oceanTeal = const Color(0xFF00ADB5).withValues(alpha: 0.12);
      final Color oceanBlue = const Color(0xFF1F4068).withValues(alpha: 0.15);
      final Color oceanGreen = const Color(0xFF2E8B57).withValues(alpha: 0.08);

      final double shift1 = math.sin(animationValue * 2 * math.pi) * size.height * 0.05;
      paint.shader = RadialGradient(colors: [oceanTeal, oceanTeal.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(size.width * 0.3, size.height * 0.3 + shift1), radius: size.width * 0.8));
      canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3 + shift1), size.width * 0.8, paint);

      final double shift2 = math.cos((animationValue + 0.5) * 2 * math.pi) * size.height * 0.05;
      paint.shader = RadialGradient(colors: [oceanBlue, oceanBlue.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(size.width * 0.7, size.height * 0.7 + shift2), radius: size.width * 0.85));
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7 + shift2), size.width * 0.85, paint);

      final double shift3 = math.sin((animationValue + 0.25) * 2 * math.pi) * size.height * 0.04;
      paint.shader = RadialGradient(colors: [oceanGreen, oceanGreen.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.65 + shift3), radius: size.width * 0.6));
      canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.65 + shift3), size.width * 0.6, paint);

    } else if (style == 'autumn') {
      // Warm mahogany, amber and copper shades
      final Color autumnAmber = const Color(0xFFFFB300).withValues(alpha: 0.12);
      final Color autumnCopper = const Color(0xFFD35400).withValues(alpha: 0.15);
      final Color autumnRed = const Color(0xFFC0392B).withValues(alpha: 0.08);

      final double angle1 = animationValue * 2 * math.pi;
      final double dx1 = size.width * 0.3 + math.cos(angle1) * size.width * 0.12;
      final double dy1 = size.height * 0.35 + math.sin(angle1) * size.height * 0.06;
      paint.shader = RadialGradient(colors: [autumnAmber, autumnAmber.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.7));
      canvas.drawCircle(Offset(dx1, dy1), size.width * 0.7, paint);

      final double angle2 = (animationValue + 0.4) * 2 * math.pi;
      final double dx2 = size.width * 0.7 + math.sin(angle2) * size.width * 0.1;
      final double dy2 = size.height * 0.65 + math.cos(angle2) * size.height * 0.06;
      paint.shader = RadialGradient(colors: [autumnCopper, autumnCopper.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.8));
      canvas.drawCircle(Offset(dx2, dy2), size.width * 0.8, paint);

      final double angle3 = (animationValue + 0.7) * 2 * math.pi;
      final double dx3 = size.width * 0.4 + math.cos(angle3 * 1.2) * size.width * 0.08;
      final double dy3 = size.height * 0.5 + math.sin(angle3 * 1.2) * size.height * 0.08;
      paint.shader = RadialGradient(colors: [autumnRed, autumnRed.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: size.width * 0.6));
      canvas.drawCircle(Offset(dx3, dy3), size.width * 0.6, paint);

    } else {
      // DEFAULT AURORA TIME-BASED
      // 2. Draw Blob 1 (Top-Left moving slowly)
      final double angle1 = animationValue * 2 * math.pi;
      final double dx1 = size.width * 0.25 + math.cos(angle1) * size.width * 0.15;
      final double dy1 = size.height * 0.25 + math.sin(angle1) * size.height * 0.08;
      final double radius1 = size.width * 0.65;

      paint.shader = RadialGradient(
        colors: [colors.color1, colors.color1.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: radius1));
      canvas.drawCircle(Offset(dx1, dy1), radius1, paint);

      // 3. Draw Blob 2 (Bottom-Right moving ovally)
      final double angle2 = (animationValue + 0.33) * 2 * math.pi;
      final double dx2 = size.width * 0.75 + math.sin(angle2) * size.width * 0.15;
      final double dy2 = size.height * 0.75 + math.cos(angle2) * size.height * 0.08;
      final double radius2 = size.width * 0.70;

      paint.shader = RadialGradient(
        colors: [colors.color2, colors.color2.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: radius2));
      canvas.drawCircle(Offset(dx2, dy2), radius2, paint);

      // 4. Draw Blob 3 (Center-Left drifting)
      final double angle3 = (animationValue + 0.66) * 2 * math.pi;
      final double dx3 = size.width * 0.30 + math.cos(angle3 * 1.5) * size.width * 0.10;
      final double dy3 = size.height * 0.50 + math.sin(angle3 * 1.5) * size.height * 0.10;
      final double radius3 = size.width * 0.60;

      paint.shader = RadialGradient(
        colors: [colors.color3, colors.color3.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: radius3));
      canvas.drawCircle(Offset(dx3, dy3), radius3, paint);
    }
  }

  // Draw static background patterns
  if (pattern != 'none') {
    final patternPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.035) : Colors.black.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke;

    if (pattern == 'dots') {
      patternPaint.style = PaintingStyle.fill;
      const double spacing = 24.0;
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.2, patternPaint);
        }
      }
    } else if (pattern == 'grid') {
      patternPaint.strokeWidth = 0.8;
      const double spacing = 32.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), patternPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), patternPaint);
      }
    } else if (pattern == 'waves') {
      patternPaint.strokeWidth = 1.0;
      const double spacing = 40.0;
      for (double y = spacing; y < size.height; y += spacing) {
        final Path path = Path();
        path.moveTo(0, y);
        for (double x = 0; x < size.width; x += 12) {
          path.lineTo(x, y + math.sin(x / 30) * 4);
        }
        canvas.drawPath(path, patternPaint);
      }
    } else if (pattern == 'stripes') {
      patternPaint.strokeWidth = 1.2;
      const double spacing = 45.0;
      for (double i = -size.height; i < size.width; i += spacing) {
        canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), patternPaint);
      }
    }
  }
}

@override
bool shouldRepaint(covariant AuroraBlobsPainter oldDelegate) {
  return oldDelegate.animationValue != animationValue ||
      oldDelegate.colors != colors ||
      oldDelegate.style != style ||
      oldDelegate.pattern != pattern ||
      oldDelegate.auroraEnabled != auroraEnabled ||
      oldDelegate.wallpaper != wallpaper ||
      oldDelegate.isDark != isDark;
}
}

class SparklesPainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;
  final Color sparkleColor;
  final double speedFactor;
  final int density;
  final String style;

  SparklesPainter({
    required this.animationValue,
    required this.particles,
    required this.sparkleColor,
    required this.speedFactor,
    required this.density,
    required this.style,
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
      if (style == 'cyberpunk') {
        pColor = i % 2 == 0 ? const Color(0xFFFF007F) : const Color(0xFF00F5FF);
      } else if (style == 'cosmic') {
        pColor = Colors.white.withValues(alpha: particle.opacity);
      } else if (style == 'ocean') {
        pColor = Colors.cyanAccent.withValues(alpha: particle.opacity * 0.6);
      } else if (style == 'autumn') {
        pColor = i % 3 == 0 
            ? const Color(0xFFD35400) // orange
            : i % 3 == 1 
                ? const Color(0xFFFFB300) // gold
                : const Color(0xFFC0392B); // red-brown
      }

      paint.color = pColor.withValues(alpha: particle.opacity * 0.55);

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
        oldDelegate.style != style;
  }
}
