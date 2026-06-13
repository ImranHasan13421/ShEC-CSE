import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ShEC_CSE/core/widgets/shec_sparkle_background.dart';
import '../ambient_settings.dart';

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
      } else if (style == 'shec') {
        // ShEC floating particles (slow upward drift)
        particle.y -= particle.speed * speedFactor * 0.8;
        particle.x += math.sin(animationValue * 2 * math.pi + particle.randomOffset) * 0.35;

        // Reset if off-screen
        if (particle.y < -15) {
          particle.y = size.height + 15;
          particle.x = math.Random().nextDouble() * size.width;
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
        } else if (style == 'shec') {
          pColor = i % 4 == 0 
              ? const Color(0xFF1E5631) // Forest Green (darker)
              : i % 4 == 1 
                  ? const Color(0xFF0D47A1) // Royal Blue (darker)
                  : i % 4 == 2
                      ? const Color(0xFF8B0000) // Deep Red (darker)
                      : const Color(0xFF333333); // Off-Black
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
        } else if (style == 'shec') {
          pColor = i % 4 == 0 
              ? const Color(0xFF228B22) // Forest Green
              : i % 4 == 1 
                  ? const Color(0xFF4169E1) // Royal Blue
                  : i % 4 == 2
                      ? const Color(0xFFE53935) // Deep Red
                      : const Color(0xFFFAF9F6); // Off-White
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
      } else if (style == 'shec') {
        // Draw alternate 4-pointed star sparkles and digital ShEC code characters
        if (i % 2 == 0) {
          canvas.save();
          canvas.translate(particle.x, particle.y);
          canvas.rotate(animationValue * 2 * math.pi + particle.randomOffset);

          final Path starPath = Path();
          final double half = (particle.size * 1.5) / 2; // slightly larger stars

          starPath.moveTo(0, -half);
          starPath.quadraticBezierTo(0, 0, half, 0);
          starPath.quadraticBezierTo(0, 0, 0, half);
          starPath.quadraticBezierTo(0, 0, -half, 0);
          starPath.quadraticBezierTo(0, 0, 0, -half);
          starPath.close();

          // Draw soft glow behind the star
          final glowPaint = Paint()
            ..color = pColor.withValues(alpha: paint.color.opacity * 0.35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.4);
          canvas.drawCircle(Offset.zero, half * 0.8, glowPaint);

          canvas.drawPath(starPath, paint);
          canvas.restore();
        } else {
          // Digital ShEC / Code Characters
          final String word = ShECSparkleBackground.textGlyphs[i % ShECSparkleBackground.textGlyphs.length];
          final textPainter = TextPainter(
            text: TextSpan(
              text: word,
              style: TextStyle(
                color: pColor.withValues(alpha: paint.color.opacity * 0.75),
                fontSize: 11.0 + particle.size * 3.5,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          canvas.save();
          canvas.translate(particle.x, particle.y);
          canvas.rotate(animationValue * 0.5 * math.pi + particle.randomOffset);
          textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
          canvas.restore();
        }
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
