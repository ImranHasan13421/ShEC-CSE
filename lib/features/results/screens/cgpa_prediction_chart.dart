import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/result_state.dart';

class CgpaPredictionChart extends StatefulWidget {
  final List<ExamResult> results;
  final bool showPredictions;

  const CgpaPredictionChart({
    super.key,
    required this.results,
    this.showPredictions = true,
  });

  @override
  State<CgpaPredictionChart> createState() => _CgpaPredictionChartState();
}

class _CgpaPredictionChartState extends State<CgpaPredictionChart> {
  double _targetFutureGpa = 3.50; // Default expected GPA for future semesters

  // Map exam names to semesters 1-8 based on DU conventions
  int _parseSemesterNumber(String examName) {
    final name = examName.toLowerCase();
    if (name.contains('1st year 1st') || name.contains('1st sem') || name.contains('1-1') || (name.contains('1st year') && name.contains('1st'))) return 1;
    if (name.contains('1st year 2nd') || name.contains('2nd sem') || name.contains('1-2') || (name.contains('1st year') && name.contains('2nd'))) return 2;
    if (name.contains('2nd year 1st') || name.contains('3rd sem') || name.contains('2-1') || (name.contains('2nd year') && name.contains('1st'))) return 3;
    if (name.contains('2nd year 2nd') || name.contains('4th sem') || name.contains('2-2') || (name.contains('2nd year') && name.contains('2nd'))) return 4;
    if (name.contains('3rd year 1st') || name.contains('5th sem') || name.contains('3-1') || (name.contains('3rd year') && name.contains('1st'))) return 5;
    if (name.contains('3rd year 2nd') || name.contains('6th sem') || name.contains('3-2') || (name.contains('3rd year') && name.contains('2nd'))) return 6;
    if (name.contains('4th year 1st') || name.contains('7th sem') || name.contains('4-1') || (name.contains('4th year') && name.contains('1st'))) return 7;
    if (name.contains('4th year 2nd') || name.contains('8th sem') || name.contains('4-2') || (name.contains('4th year') && name.contains('2nd'))) return 8;

    // Fallbacks
    if (name.contains('1st')) return 1;
    if (name.contains('2nd')) return 2;
    if (name.contains('3rd')) return 3;
    if (name.contains('4th')) return 4;
    if (name.contains('5th')) return 5;
    if (name.contains('6th')) return 6;
    if (name.contains('7th')) return 7;
    if (name.contains('8th')) return 8;

    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 1. Group actual GPAs and CGPAs by semester
    final Map<int, double> completedGpas = {};
    final Map<int, double> completedCgpas = {};
    for (var r in widget.results) {
      final sem = r.semester ?? _parseSemesterNumber(r.examName);
      final gpaVal = double.tryParse(r.gpa) ?? 0.0;
      final cgpaVal = double.tryParse(r.cgpa) ?? 0.0;
      if (gpaVal > 0.0) {
        completedGpas[sem] = gpaVal;
      }
      if (cgpaVal > 0.0) {
        completedCgpas[sem] = cgpaVal;
      }
    }

    // 2. Find highest completed semester
    final K = completedGpas.keys.isEmpty 
        ? 0 
        : completedGpas.keys.reduce((max, key) => key > max ? key : max);

    // 3. Compute actual and projected CGPAs for semesters 1-8
    final List<double?> actualCgpas = List.filled(8, null);
    final List<double> projectedCgpas = List.filled(8, 0.0);
    final List<double?> actualGpas = List.filled(8, null);
    final List<double> projectedGpas = List.filled(8, 0.0);

    double actualSum = 0.0;
    int actualCount = 0;

    for (int s = 1; s <= 8; s++) {
      if (completedGpas.containsKey(s)) {
        actualSum += completedGpas[s]!;
        actualCount++;
        final cgpaVal = completedCgpas[s] ?? (actualSum / actualCount);
        actualCgpas[s - 1] = cgpaVal;
        projectedCgpas[s - 1] = cgpaVal;
        
        actualGpas[s - 1] = completedGpas[s]!;
        projectedGpas[s - 1] = completedGpas[s]!;
      } else {
        actualGpas[s - 1] = null;
        projectedGpas[s - 1] = _targetFutureGpa;
        
        if (s == 1) {
          projectedCgpas[s - 1] = _targetFutureGpa;
        } else {
          if (s > K && K > 0) {
            // Future semester prediction using the previous cumulative CGPA
            projectedCgpas[s - 1] = (projectedCgpas[s - 2] * (s - 1) + _targetFutureGpa) / s;
          } else {
            // Missing intermediate semester, or no results at all
            projectedCgpas[s - 1] = projectedCgpas[s - 2];
          }
        }
      }
    }

    // Latest actual CGPA
    final currentCgpa = K > 0 && actualCgpas[K - 1] != null 
        ? actualCgpas[K - 1]! 
        : 0.0;
    final predictedFinalCgpa = projectedCgpas[7];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.15)),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Present CGPA',
                      style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentCgpa > 0 ? currentCgpa.toStringAsFixed(2) : 'N/A',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: colors.outline.withValues(alpha: 0.2),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.showPredictions ? 'Predicted Final CGPA' : 'Completed Semesters',
                      style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.showPredictions 
                          ? predictedFinalCgpa.toStringAsFixed(2) 
                          : '$K / 8',
                      style: TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold, 
                        color: widget.showPredictions ? colors.primary : colors.onSurface, 
                        letterSpacing: -0.5
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart area
            AspectRatio(
              aspectRatio: 1.8,
              child: CustomPaint(
                painter: CgpaLineChartPainter(
                  actualCgpas: actualCgpas,
                  projectedCgpas: projectedCgpas,
                  actualGpas: actualGpas,
                  projectedGpas: projectedGpas,
                  lastActualIndex: K - 1,
                  themeColors: colors,
                  showPredictions: widget.showPredictions,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  colors.primary,
                  'Cumulative CGPA',
                ),
                const SizedBox(width: 20),
                _buildLegendItem(
                  colors.secondary,
                  'Semester GPA',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Slider (Visible only if there are future semesters to predict)
            if (widget.showPredictions) ...[
              if (K < 8) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expected Future GPA',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Set expected GPA for remaining ${8 - K} semesters',
                            style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _targetFutureGpa.toStringAsFixed(2),
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: colors.primary.withValues(alpha: 0.15),
                    thumbColor: colors.primary,
                    overlayColor: colors.primary.withValues(alpha: 0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _targetFutureGpa,
                    min: 2.00,
                    max: 4.00,
                    divisions: 40,
                    onChanged: (val) {
                      setState(() => _targetFutureGpa = val);
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Congratulations! All 8 semesters completed.',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class CgpaLineChartPainter extends CustomPainter {
  final List<double?> actualCgpas;
  final List<double> projectedCgpas;
  final List<double?> actualGpas;
  final List<double> projectedGpas;
  final int lastActualIndex; // -1 means none completed
  final ColorScheme themeColors;
  final bool showPredictions;

  CgpaLineChartPainter({
    required this.actualCgpas,
    required this.projectedCgpas,
    required this.actualGpas,
    required this.projectedGpas,
    required this.lastActualIndex,
    required this.themeColors,
    required this.showPredictions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 32.0;
    final double paddingRight = 16.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 20.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final Paint gridPaint = Paint()
      ..color = themeColors.outline.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // 1. Draw horizontal grid lines and y-axis labels
    final List<double> yValues = [2.00, 2.50, 3.00, 3.50, 4.00];
    for (var yVal in yValues) {
      // Normalize y: 2.0 is bottom, 4.0 is top
      final double normalizedY = (yVal - 2.0) / 2.0;
      final double yPos = size.height - paddingBottom - (normalizedY * chartHeight);

      // Draw grid line
      canvas.drawLine(
        Offset(paddingLeft, yPos),
        Offset(size.width - paddingRight, yPos),
        gridPaint,
      );

      // Draw y label
      textPainter.text = TextSpan(
        text: yVal.toStringAsFixed(2),
        style: TextStyle(
          color: themeColors.onSurface.withValues(alpha: 0.4),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, yPos - textPainter.height / 2),
      );
    }

    // 2. Draw x-axis labels
    final double xStep = chartWidth / 7.0;
    for (int i = 0; i < 8; i++) {
      final double xPos = paddingLeft + (i * xStep);

      textPainter.text = TextSpan(
        text: 'S${i + 1}',
        style: TextStyle(
          color: themeColors.onSurface.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xPos - textPainter.width / 2, size.height - paddingBottom + 6),
      );
    }

    // Draw chart elements only if data is present
    final List<Offset> actualPoints = [];
    final List<Offset> projectedPoints = [];
    final List<Offset> actualGpaPoints = [];
    final List<Offset> projectedGpaPoints = [];

    final Color gpaLineColor = themeColors.secondary;

    for (int i = 0; i < 8; i++) {
      final double xPos = paddingLeft + (i * xStep);
      
      // Actual CGPA plotting
      if (i <= lastActualIndex && actualCgpas[i] != null) {
        final double normalizedY = (actualCgpas[i]! - 2.0) / 2.0;
        final double yPos = size.height - paddingBottom - (normalizedY.clamp(0.0, 1.0) * chartHeight);
        actualPoints.add(Offset(xPos, yPos));
      }

      // Projected CGPA plotting
      final double normalizedProjY = (projectedCgpas[i] - 2.0) / 2.0;
      final double yProjPos = size.height - paddingBottom - (normalizedProjY.clamp(0.0, 1.0) * chartHeight);
      projectedPoints.add(Offset(xPos, yProjPos));

      // Actual GPA plotting
      if (i <= lastActualIndex && actualGpas[i] != null) {
        final double normalizedY = (actualGpas[i]! - 2.0) / 2.0;
        final double yPos = size.height - paddingBottom - (normalizedY.clamp(0.0, 1.0) * chartHeight);
        actualGpaPoints.add(Offset(xPos, yPos));
      }

      // Projected GPA plotting
      final double normalizedProjGpaY = (projectedGpas[i] - 2.0) / 2.0;
      final double yProjGpaPos = size.height - paddingBottom - (normalizedProjGpaY.clamp(0.0, 1.0) * chartHeight);
      projectedGpaPoints.add(Offset(xPos, yProjGpaPos));
    }

    // 3. Draw Projected GPA Line (Dashed)
    if (showPredictions && projectedGpaPoints.length > 1) {
      final Paint projectedGpaPaint = Paint()
        ..color = gpaLineColor.withValues(alpha: 0.35)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final Path path = Path();
      path.moveTo(projectedGpaPoints[0].dx, projectedGpaPoints[0].dy);
      for (int i = 1; i < projectedGpaPoints.length; i++) {
        path.lineTo(projectedGpaPoints[i].dx, projectedGpaPoints[i].dy);
      }
      _drawDashedPath(canvas, path, projectedGpaPaint, [6, 5]);
    }

    // 4. Draw Projected CGPA Line (Dashed)
    if (showPredictions && projectedPoints.length > 1) {
      final Paint projectedPaint = Paint()
        ..color = themeColors.primary.withValues(alpha: 0.4)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      final Path path = Path();
      path.moveTo(projectedPoints[0].dx, projectedPoints[0].dy);
      for (int i = 1; i < projectedPoints.length; i++) {
        path.lineTo(projectedPoints[i].dx, projectedPoints[i].dy);
      }
      _drawDashedPath(canvas, path, projectedPaint, [8, 6]);
    }

    // 5. Draw Actual GPA Line (Solid)
    if (actualGpaPoints.isNotEmpty) {
      final Paint actualGpaPaint = Paint()
        ..color = gpaLineColor.withValues(alpha: 0.75)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path actualGpaPath = Path();
      actualGpaPath.moveTo(actualGpaPoints[0].dx, actualGpaPoints[0].dy);
      for (int i = 1; i < actualGpaPoints.length; i++) {
        actualGpaPath.lineTo(actualGpaPoints[i].dx, actualGpaPoints[i].dy);
      }
      canvas.drawPath(actualGpaPath, actualGpaPaint);
    }

    // 6. Draw Actual CGPA Line (Gradient & Solid)
    if (actualPoints.isNotEmpty) {
      final Paint actualPaint = Paint()
        ..shader = ui.Gradient.linear(
          actualPoints.first,
          actualPoints.last,
          [themeColors.primary, themeColors.primary.withRed(150)],
        )
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path actualPath = Path();
      actualPath.moveTo(actualPoints[0].dx, actualPoints[0].dy);
      for (int i = 1; i < actualPoints.length; i++) {
        actualPath.lineTo(actualPoints[i].dx, actualPoints[i].dy);
      }
      canvas.drawPath(actualPath, actualPaint);

      // Gradient area fill under actual line
      final Path fillPath = Path()
        ..moveTo(actualPoints[0].dx, size.height - paddingBottom)
        ..lineTo(actualPoints[0].dx, actualPoints[0].dy);
      for (int i = 1; i < actualPoints.length; i++) {
        fillPath.lineTo(actualPoints[i].dx, actualPoints[i].dy);
      }
      fillPath.lineTo(actualPoints.last.dx, size.height - paddingBottom);
      fillPath.close();

      final Paint fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, paddingTop),
          Offset(0, size.height - paddingBottom),
          [themeColors.primary.withValues(alpha: 0.12), themeColors.primary.withValues(alpha: 0.0)],
        )
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(fillPath, fillPaint);
    }

    // 7. Draw dots and values
    final Paint activeDotPaint = Paint()
      ..color = themeColors.primary
      ..style = PaintingStyle.fill;

    final Paint borderDotPaint = Paint()
      ..color = themeColors.surface
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint projectedDotPaint = Paint()
      ..color = themeColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint gpaDotPaint = Paint()
      ..color = gpaLineColor
      ..style = PaintingStyle.fill;

    final Paint projectedGpaDotPaint = Paint()
      ..color = gpaLineColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      if (!showPredictions && i > lastActualIndex) continue;
      final Offset ptCgpa = projectedPoints[i];
      final Offset ptGpa = projectedGpaPoints[i];
      
      final double cgpaVal = i <= lastActualIndex ? (actualCgpas[i] ?? 0.0) : projectedCgpas[i];
      final double gpaVal = i <= lastActualIndex ? (actualGpas[i] ?? 0.0) : projectedGpas[i];

      // Draw GPA dots
      if (i <= lastActualIndex) {
        canvas.drawCircle(ptGpa, 4.0, gpaDotPaint);
        canvas.drawCircle(ptGpa, 4.0, borderDotPaint);
      } else {
        canvas.drawCircle(ptGpa, 3.0, Paint()..color = themeColors.surface..style = PaintingStyle.fill);
        canvas.drawCircle(ptGpa, 3.0, projectedGpaDotPaint);
      }

      // Draw CGPA dots
      if (i <= lastActualIndex) {
        canvas.drawCircle(ptCgpa, 5.5, activeDotPaint);
        canvas.drawCircle(ptCgpa, 5.5, borderDotPaint);
      } else {
        canvas.drawCircle(ptCgpa, 4.5, Paint()..color = themeColors.surface..style = PaintingStyle.fill);
        canvas.drawCircle(ptCgpa, 4.5, projectedDotPaint);
      }

      // Dynamic collision avoidance: determine label directions based on vertical ordering
      // ptCgpa.dy > ptGpa.dy means CGPA is lower on the screen than GPA
      final bool cgpaIsLower = ptCgpa.dy > ptGpa.dy;

      final double cgpaLabelY = cgpaIsLower ? ptCgpa.dy + 6 : ptCgpa.dy - 16;
      final double gpaLabelY = cgpaIsLower ? ptGpa.dy - 16 : ptGpa.dy + 6;

      // Draw GPA label
      if (gpaVal > 0.0) {
        textPainter.text = TextSpan(
          text: gpaVal.toStringAsFixed(2),
          style: TextStyle(
            color: i <= lastActualIndex ? gpaLineColor : gpaLineColor.withValues(alpha: 0.6),
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(ptGpa.dx - textPainter.width / 2, gpaLabelY),
        );
      }

      // Draw CGPA label
      if (cgpaVal > 0.0) {
        textPainter.text = TextSpan(
          text: cgpaVal.toStringAsFixed(2),
          style: TextStyle(
            color: i <= lastActualIndex ? themeColors.primary : themeColors.primary.withValues(alpha: 0.6),
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(ptCgpa.dx - textPainter.width / 2, cgpaLabelY),
        );
      }
    }
  }

  // Dashed path helper
  void _drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> dashArray) {
    final Path dest = Path();
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray[draw ? 0 : 1];
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, (distance + len).clamp(0.0, metric.length)),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dest, paint);
  }

  @override
  bool shouldRepaint(covariant CgpaLineChartPainter oldDelegate) {
    return oldDelegate.actualCgpas != actualCgpas ||
        oldDelegate.projectedCgpas != projectedCgpas ||
        oldDelegate.actualGpas != actualGpas ||
        oldDelegate.projectedGpas != projectedGpas ||
        oldDelegate.lastActualIndex != lastActualIndex ||
        oldDelegate.themeColors != themeColors ||
        oldDelegate.showPredictions != showPredictions;
  }
}
