import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShECSparkleBackground extends StatefulWidget {
  final Widget? child;
  const ShECSparkleBackground({super.key, this.child});

  static const List<String> textGlyphs = ['ShEC', 'CPC', '0', '1', '{/}', '{', '}', '</>', ';'];

  @override
  State<ShECSparkleBackground> createState() => _ShECSparkleBackgroundState();
}

class _ShECSparkleBackgroundState extends State<ShECSparkleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SparkleParticle> _particles = [];
  final math.Random _random = math.Random();

  // ShEC Brand Colors
  final List<Color> _brandColors = [
    const Color(0xFF4169E1), // Royal Blue
    const Color(0xFF8B0000), // Deep Red
    const Color(0xFF228B22), // Forest Green
    const Color(0xFFFAF9F6), // Off-White
  ];

  final List<String> _textGlyphs = ShECSparkleBackground.textGlyphs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Spawn initial particles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        _initializeParticles(size);
      }
    });
  }

  void _initializeParticles(Size size) {
    for (int i = 0; i < 45; i++) {
      _particles.add(_createParticle(size, initial: true));
    }
  }

  SparkleParticle _createParticle(Size size, {bool initial = false}) {
    final isText = _random.nextDouble() < 0.40;
    return SparkleParticle(
      x: _random.nextDouble() * size.width,
      y: initial ? _random.nextDouble() * size.height : size.height + 10,
      size: _random.nextDouble() * 5 + 10,
      speed: _random.nextDouble() * 0.8 + 0.3,
      color: _brandColors[_random.nextInt(_brandColors.length)],
      char: _textGlyphs[_random.nextInt(_textGlyphs.length)],
      isText: isText,
      twinkleSpeed: _random.nextDouble() * 0.05 + 0.015,
      angle: _random.nextDouble() * math.pi * 2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Sparkle Paint Canvas
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Update particle positions
            for (var p in _particles) {
              p.y -= p.speed; // float upward
              p.angle += 0.01; // subtle rotation
              
              // Twinkle scale/opacity oscillation
              p.opacity += p.twinkleSpeed * p.fadeDir;
              if (p.opacity >= 0.85) {
                p.opacity = 0.85;
                p.fadeDir = -1;
              } else if (p.opacity <= 0.1) {
                p.opacity = 0.1;
                p.fadeDir = 1;
              }

              // Reset off-screen particles
              if (p.y < -20) {
                p.y = size.height + 20;
                p.x = _random.nextDouble() * size.width;
              }
            }

            return CustomPaint(
              painter: SparklePainter(particles: _particles),
              size: size,
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class SparkleParticle {
  double x, y;
  double size;
  double speed;
  double opacity = 0.5;
  double twinkleSpeed;
  int fadeDir = 1;
  Color color;
  String char;
  bool isText;
  double angle;

  SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.char,
    required this.isText,
    required this.twinkleSpeed,
    required this.angle,
  });
}

class SparklePainter extends CustomPainter {
  final List<SparkleParticle> particles;
  SparklePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      if (p.isText) {
        // Draw CSE/ShEC characters
        final textPainter = TextPainter(
          text: TextSpan(
            text: p.char,
            style: TextStyle(
              color: p.color.withValues(alpha: p.opacity * 0.8),
              fontSize: p.size * 1.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.angle);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      } else {
        // Draw Premium 4-pointed Star Sparkle
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.angle);

        starPaint.color = p.color.withValues(alpha: p.opacity);

        final Path starPath = Path();
        final double half = p.size / 2;

        starPath.moveTo(0, -half);
        // Top-Right curve
        starPath.quadraticBezierTo(0, 0, half, 0);
        // Bottom-Right curve
        starPath.quadraticBezierTo(0, 0, 0, half);
        // Bottom-Left curve
        starPath.quadraticBezierTo(0, 0, -half, 0);
        // Top-Left curve
        starPath.quadraticBezierTo(0, 0, 0, -half);
        starPath.close();

        // Draw soft glow behind the star
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: p.opacity * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.4);
        canvas.drawCircle(Offset.zero, half * 0.8, glowPaint);

        canvas.drawPath(starPath, starPaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
