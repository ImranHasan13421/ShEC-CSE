import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../ambient_settings.dart';

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
    } else if (style == 'shec' && auroraEnabled) {
      baseBg = const Color(0xFF030805); // Deep green-black
    }
    
    paint.color = baseBg;
    canvas.drawRect(Offset.zero & size, paint);

    // Use the continuous elapsed time in seconds to ensure perfectly smooth, infinite, non-looping motion
    final double t = animationValue * speedFactor * 0.8;

    if (auroraEnabled) {
      if (style == 'cyberpunk') {
        // Draw Magenta and Cyan glowing cyber-blobs
        final Color cyberColor1 = const Color(0xFFFF007F).withValues(alpha: isDark ? 0.22 : 0.36); // Neon Pink
        final Color cyberColor2 = const Color(0xFF00ADB5).withValues(alpha: isDark ? 0.22 : 0.36); // Neon Cyan

        final double dx1 = size.width * 0.35 + (math.cos(t * 0.7) * 0.18 + math.sin(t * 1.3) * 0.07) * size.width;
        final double dy1 = size.height * 0.35 + (math.sin(t * 1.1) * 0.12 + math.cos(t * 0.5) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [cyberColor1, cyberColor1.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.75));
        canvas.drawCircle(Offset(dx1, dy1), size.width * 0.75, paint);

        final double dx2 = size.width * 0.65 + (math.sin(t * 0.9) * 0.18 + math.cos(t * 1.5) * 0.07) * size.width;
        final double dy2 = size.height * 0.65 + (math.cos(t * 1.3) * 0.12 + math.sin(t * 0.8) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [cyberColor2, cyberColor2.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.8));
        canvas.drawCircle(Offset(dx2, dy2), size.width * 0.8, paint);
        
      } else if (style == 'cosmic') {
        // Cosmic Nebula Circles (glowing deep violet & blue spaces)
        final Color spacePurple = const Color(0xFF7B2CBF).withValues(alpha: isDark ? 0.20 : 0.32);
        final Color spaceIndigo = const Color(0xFF3C096C).withValues(alpha: isDark ? 0.22 : 0.35);
        final Color spacePink = const Color(0xFFE0AAFF).withValues(alpha: isDark ? 0.12 : 0.22);

        final double dx1 = size.width * 0.5 + (math.cos(t * 0.5) * 0.18 + math.sin(t * 1.1) * 0.06) * size.width;
        final double dy1 = size.height * 0.4 + (math.sin(t * 0.8) * 0.12 + math.cos(t * 0.4) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [spacePurple, spacePurple.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.85));
        canvas.drawCircle(Offset(dx1, dy1), size.width * 0.85, paint);

        final double dx2 = size.width * 0.4 + (math.sin(t * 0.75) * 0.16 + math.cos(t * 1.25) * 0.06) * size.width;
        final double dy2 = size.height * 0.7 + (math.cos(t * 0.95) * 0.12 + math.sin(t * 0.55) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [spaceIndigo, spaceIndigo.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.95));
        canvas.drawCircle(Offset(dx2, dy2), size.width * 0.95, paint);

        final double dx3 = size.width * 0.65 + (math.cos(t * 0.9) * 0.16 + math.sin(t * 1.4) * 0.06) * size.width;
        final double dy3 = size.height * 0.5 + (math.sin(t * 1.15) * 0.12 + math.cos(t * 0.7) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [spacePink, spacePink.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: size.width * 0.7));
        canvas.drawCircle(Offset(dx3, dy3), size.width * 0.7, paint);

      } else if (style == 'ocean') {
        // Ocean calmness (teal, sky blue and marine green horizontal waves)
        final Color oceanTeal = const Color(0xFF00ADB5).withValues(alpha: isDark ? 0.20 : 0.32);
        final Color oceanBlue = const Color(0xFF1F4068).withValues(alpha: isDark ? 0.22 : 0.35);
        final Color oceanGreen = const Color(0xFF2E8B57).withValues(alpha: isDark ? 0.12 : 0.22);

        final double shift1 = (math.sin(t * 0.6) * 0.08 + math.cos(t * 1.1) * 0.03) * size.height;
        final double dx1 = size.width * 0.3 + (math.cos(t * 0.5) * 0.05) * size.width;
        paint.shader = RadialGradient(colors: [oceanTeal, oceanTeal.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, size.height * 0.3 + shift1), radius: size.width * 0.9));
        canvas.drawCircle(Offset(dx1, size.height * 0.3 + shift1), size.width * 0.9, paint);

        final double shift2 = (math.cos(t * 0.8) * 0.08 + math.sin(t * 1.3) * 0.03) * size.height;
        final double dx2 = size.width * 0.7 + (math.sin(t * 0.6) * 0.05) * size.width;
        paint.shader = RadialGradient(colors: [oceanBlue, oceanBlue.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, size.height * 0.7 + shift2), radius: size.width * 0.95));
        canvas.drawCircle(Offset(dx2, size.height * 0.7 + shift2), size.width * 0.95, paint);

        final double shift3 = (math.sin(t * 0.7) * 0.06 + math.cos(t * 1.2) * 0.02) * size.height;
        final double dx3 = size.width * 0.2 + (math.cos(t * 0.8) * 0.04) * size.width;
        paint.shader = RadialGradient(colors: [oceanGreen, oceanGreen.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, size.height * 0.65 + shift3), radius: size.width * 0.75));
        canvas.drawCircle(Offset(dx3, size.height * 0.65 + shift3), size.width * 0.75, paint);

      } else if (style == 'autumn') {
        // Warm mahogany, amber and copper shades
        final Color autumnAmber = const Color(0xFFFFB300).withValues(alpha: isDark ? 0.20 : 0.32);
        final Color autumnCopper = const Color(0xFFD35400).withValues(alpha: isDark ? 0.22 : 0.35);
        final Color autumnRed = const Color(0xFFC0392B).withValues(alpha: isDark ? 0.12 : 0.22);

        final double dx1 = size.width * 0.35 + (math.cos(t * 0.65) * 0.18 + math.sin(t * 1.25) * 0.06) * size.width;
        final double dy1 = size.height * 0.35 + (math.sin(t * 0.95) * 0.10 + math.cos(t * 0.55) * 0.04) * size.height;
        paint.shader = RadialGradient(colors: [autumnAmber, autumnAmber.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.8));
        canvas.drawCircle(Offset(dx1, dy1), size.width * 0.8, paint);

        final double dx2 = size.width * 0.65 + (math.sin(t * 0.85) * 0.18 + math.cos(t * 1.35) * 0.06) * size.width;
        final double dy2 = size.height * 0.65 + (math.cos(t * 1.05) * 0.10 + math.sin(t * 0.65) * 0.04) * size.height;
        paint.shader = RadialGradient(colors: [autumnCopper, autumnCopper.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.9));
        canvas.drawCircle(Offset(dx2, dy2), size.width * 0.9, paint);

        final double dx3 = size.width * 0.45 + (math.cos(t * 0.8) * 0.14 + math.sin(t * 1.45) * 0.05) * size.width;
        final double dy3 = size.height * 0.5 + (math.sin(t * 1.15) * 0.12 + math.cos(t * 0.75) * 0.04) * size.height;
        paint.shader = RadialGradient(colors: [autumnRed, autumnRed.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: size.width * 0.75));
        canvas.drawCircle(Offset(dx3, dy3), size.width * 0.75, paint);

      } else if (style == 'shec') {
        // ShEC Brand color nebulae (Forest Green, Royal Blue, and Deep Red)
        final Color shecGreen = const Color(0xFF228B22).withValues(alpha: isDark ? 0.16 : 0.28);
        final Color shecBlue = const Color(0xFF4169E1).withValues(alpha: isDark ? 0.18 : 0.30);
        final Color shecRed = const Color(0xFF8B0000).withValues(alpha: isDark ? 0.10 : 0.20);

        final double dx1 = size.width * 0.3 + (math.cos(t * 0.7) * 0.18 + math.sin(t * 1.3) * 0.07) * size.width;
        final double dy1 = size.height * 0.35 + (math.sin(t * 1.1) * 0.12 + math.cos(t * 0.5) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [shecGreen, shecGreen.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: size.width * 0.8));
        canvas.drawCircle(Offset(dx1, dy1), size.width * 0.8, paint);

        final double dx2 = size.width * 0.7 + (math.sin(t * 0.9) * 0.18 + math.cos(t * 1.5) * 0.07) * size.width;
        final double dy2 = size.height * 0.65 + (math.cos(t * 1.3) * 0.12 + math.sin(t * 0.8) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [shecBlue, shecBlue.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: size.width * 0.85));
        canvas.drawCircle(Offset(dx2, dy2), size.width * 0.85, paint);

        final double dx3 = size.width * 0.5 + (math.cos(t * 0.8) * 0.14 + math.sin(t * 1.4) * 0.05) * size.width;
        final double dy3 = size.height * 0.5 + (math.sin(t * 1.2) * 0.12 + math.cos(t * 0.6) * 0.05) * size.height;
        paint.shader = RadialGradient(colors: [shecRed, shecRed.withValues(alpha: 0.0)]).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: size.width * 0.7));
        canvas.drawCircle(Offset(dx3, dy3), size.width * 0.7, paint);

      } else {
        // DEFAULT TIME-BASED AURORA
        final double dx1 = size.width * 0.3 + (math.cos(t * 0.7) * 0.18 + math.sin(t * 1.3) * 0.07) * size.width;
        final double dy1 = size.height * 0.3 + (math.sin(t * 1.1) * 0.12 + math.cos(t * 0.5) * 0.05) * size.height;
        final double radius1 = size.width * 0.75;

        paint.shader = RadialGradient(
          colors: [colors.color1, colors.color1.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: radius1));
        canvas.drawCircle(Offset(dx1, dy1), radius1, paint);

        final double dx2 = size.width * 0.7 + (math.sin(t * 0.9) * 0.18 + math.cos(t * 1.5) * 0.07) * size.width;
        final double dy2 = size.height * 0.7 + (math.cos(t * 1.3) * 0.12 + math.sin(t * 0.8) * 0.05) * size.height;
        final double radius2 = size.width * 0.8;

        paint.shader = RadialGradient(
          colors: [colors.color2, colors.color2.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: radius2));
        canvas.drawCircle(Offset(dx2, dy2), radius2, paint);

        final double dx3 = size.width * 0.4 + (math.cos(t * 0.8) * 0.14 + math.sin(t * 1.4) * 0.05) * size.width;
        final double dy3 = size.height * 0.5 + (math.sin(t * 1.2) * 0.12 + math.cos(t * 0.6) * 0.05) * size.height;
        final double radius3 = size.width * 0.7;

        paint.shader = RadialGradient(
          colors: [colors.color3, colors.color3.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: radius3));
        canvas.drawCircle(Offset(dx3, dy3), radius3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AuroraBlobsPainter oldDelegate) => true;
}
