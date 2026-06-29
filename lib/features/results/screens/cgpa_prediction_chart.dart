import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/result_state.dart';

/// A dynamic CGPA/GPA prediction chart supporting both main and improvement results.
///
/// Lines:
///  1. Official CGPA (blue, solid) — from main exam results
///  2. Official Semester GPA (secondary, solid) — from main exam results
///  3. Effective CGPA (amber, solid) — after applying improvement calculated GPAs
///  4. Improvement Semester GPA (orange, dashed) — from improvement results' calculatedGpa
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
  double _targetFutureGpa = 3.50;

  // Line visibility toggles
  bool _showMainCgpa = true;
  bool _showMainGpa = true;
  bool _showEffectiveCgpa = true;
  bool _showImprovementGpa = true;

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

    // Split main vs improvement results
    final mainResults = widget.results.where((r) => !r.isImprovement).toList();
    final improvementResults = widget.results.where((r) => r.isImprovement).toList();
    final hasImprovements = improvementResults.isNotEmpty;

    // ── 1. Build main GPA/CGPA maps ──────────────────────────────────────────
    // Maps semester number -> ExamResult for O(1) lookup
    final Map<int, ExamResult> mainBySem = {};
    for (var r in mainResults) {
      final sem = r.semester ?? _parseSemesterNumber(r.examName);
      mainBySem[sem] = r;
    }
    final Map<int, double> mainGpas  = mainBySem.map((s, r) => MapEntry(s, double.tryParse(r.gpa)  ?? 0.0));
    final Map<int, double> mainCgpas = mainBySem.map((s, r) => MapEntry(s, double.tryParse(r.cgpa) ?? 0.0));

    // ── 2. Effective CGPA from DB (stored after recalculation) ───────────────
    // effectiveCgpa field on main results is set by ResultService.recalculateEffectiveCgpa
    final Map<int, double> storedEffectiveCgpas = {};
    for (var r in mainResults) {
      final sem = r.semester ?? _parseSemesterNumber(r.examName);
      if (r.effectiveCgpa != null && r.effectiveCgpa! > 0) {
        storedEffectiveCgpas[sem] = r.effectiveCgpa!;
      }
    }

    // ── 3. Build improvement GPA map (per semester) ─────────────────────────
    final Map<int, double> impGpas = {};
    for (var r in improvementResults) {
      final sem = r.semester ?? _parseSemesterNumber(r.examName);
      final calcGpa = r.calculatedGpa;
      if (calcGpa != null && calcGpa > 0.0) {
        if (!impGpas.containsKey(sem) || calcGpa > impGpas[sem]!) {
          impGpas[sem] = calcGpa;
        }
      }
    }

    // ── 4. Find highest completed main semester ───────────────────────────────
    final K = mainGpas.keys.isEmpty
        ? 0
        : mainGpas.keys.reduce((max, key) => key > max ? key : max);

    // ── 5. Determine max semesters (minimum 8, or K if more) ────────────────
    final int maxSemesters = K > 8 ? K : 8;

    // ── 6. Compute arrays dynamically ────────────────────────────────────────
    final List<double?> actualCgpas       = List.filled(maxSemesters, null);
    final List<double>  projectedCgpas    = List.filled(maxSemesters, 0.0);
    final List<double?> actualGpas        = List.filled(maxSemesters, null);
    final List<double>  projectedGpas     = List.filled(maxSemesters, 0.0);
    final List<double?> effectiveCgpas    = List.filled(maxSemesters, null);
    final List<double?> improvementGpas   = List.filled(maxSemesters, null);

    // On-the-fly effective CGPA accumulator (used as fallback when DB value not yet stored)
    double effectiveSum = 0.0;
    int effectiveCount  = 0;

    for (int s = 1; s <= maxSemesters; s++) {
      final impGpa = impGpas[s];
      improvementGpas[s - 1] = impGpa;

      if (mainGpas.containsKey(s)) {
        final gpa  = mainGpas[s]!;
        final cgpa = mainCgpas[s] != 0.0 ? mainCgpas[s]! : null;
        actualCgpas[s - 1]    = cgpa;
        projectedCgpas[s - 1] = cgpa ?? gpa;
        actualGpas[s - 1]     = gpa;
        projectedGpas[s - 1]  = gpa;

        final effectiveSemGpa = mainBySem[s]?.storedEffectiveGpa;
        if (effectiveSemGpa != null && effectiveSemGpa > gpa) {
           improvementGpas[s - 1] = effectiveSemGpa; // Plot Effective Semester GPA
        }

        // Prefer stored DB value; fall back to on-the-fly calculation
        if (storedEffectiveCgpas.containsKey(s)) {
          effectiveCgpas[s - 1] = storedEffectiveCgpas[s];
          // Keep accumulator in sync for subsequent fallback semesters
          final effectiveGpa = effectiveSemGpa ?? ((impGpa != null && impGpa > gpa) ? impGpa : gpa);
          effectiveSum  += effectiveGpa;
          effectiveCount++;
        } else if (hasImprovements) {
          // Fallback: compute on-the-fly
          final effectiveGpa = effectiveSemGpa ?? ((impGpa != null && impGpa > gpa) ? impGpa : gpa);
          effectiveSum  += effectiveGpa;
          effectiveCount++;
          effectiveCgpas[s - 1] = effectiveSum / effectiveCount;
        }
      } else {
        actualGpas[s - 1]    = null;
        projectedGpas[s - 1] = _targetFutureGpa;
        effectiveCgpas[s - 1] = null;

        if (s == 1) {
          projectedCgpas[s - 1] = _targetFutureGpa;
        } else if (s > K && K > 0) {
          projectedCgpas[s - 1] = (projectedCgpas[s - 2] * (s - 1) + _targetFutureGpa) / s;
        } else {
          projectedCgpas[s - 1] = projectedCgpas[s - 2];
        }
      }
    }

    // Current and effective CGPAs for display
    final currentCgpa        = K > 0 && actualCgpas[K - 1] != null ? actualCgpas[K - 1]! : 0.0;
    final predictedFinalCgpa = projectedCgpas[maxSemesters - 1];

    // Effective CGPA header value = last stored or computed value
    double? latestEffectiveCgpa;
    for (int i = maxSemesters - 1; i >= 0; i--) {
      if (effectiveCgpas[i] != null) {
        latestEffectiveCgpa = effectiveCgpas[i];
        break;
      }
    }
    // Show effective CGPA stat only when it differs meaningfully from official
    final bool showEffectiveStat = hasImprovements &&
        latestEffectiveCgpa != null &&
        (latestEffectiveCgpa - currentCgpa).abs() > 0.001;

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
            // ── Header stats ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    label: 'Official CGPA',
                    value: currentCgpa > 0 ? currentCgpa.toStringAsFixed(2) : 'N/A',
                    color: colors.primary,
                  ),
                ),
                if (showEffectiveStat) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      label: 'Effective CGPA',
                      value: latestEffectiveCgpa!.toStringAsFixed(2),
                      color: const Color(0xFFFF8F00), // amber
                      subtitle: '+${(latestEffectiveCgpa! - currentCgpa).toStringAsFixed(2)} improved',
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    label: widget.showPredictions ? 'Predicted Final' : 'Completed',
                    value: widget.showPredictions
                        ? predictedFinalCgpa.toStringAsFixed(2)
                        : '$K / $maxSemesters',
                    color: widget.showPredictions ? colors.secondary : colors.onSurface,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Chart ───────────────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 1.8,
              child: CustomPaint(
                painter: CgpaLineChartPainter(
                  actualCgpas: actualCgpas,
                  projectedCgpas: projectedCgpas,
                  actualGpas: actualGpas,
                  projectedGpas: projectedGpas,
                  effectiveCgpas: effectiveCgpas,
                  improvementGpas: improvementGpas,
                  lastActualIndex: K - 1,
                  themeColors: colors,
                  showPredictions: widget.showPredictions,
                  showMainCgpa: _showMainCgpa,
                  showMainGpa: _showMainGpa,
                  showEffectiveCgpa: _showEffectiveCgpa && hasImprovements,
                  showImprovementGpa: _showImprovementGpa && hasImprovements,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Legend with show/hide toggles ───────────────────────────────
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildToggleLegend(
                  color: colors.primary,
                  label: 'Official CGPA',
                  active: _showMainCgpa,
                  onTap: () => setState(() => _showMainCgpa = !_showMainCgpa),
                ),
                _buildToggleLegend(
                  color: colors.secondary,
                  label: 'Semester GPA',
                  active: _showMainGpa,
                  onTap: () => setState(() => _showMainGpa = !_showMainGpa),
                ),
                if (hasImprovements) ...[
                  _buildToggleLegend(
                    color: const Color(0xFFFF8F00),
                    label: 'Effective CGPA',
                    active: _showEffectiveCgpa,
                    onTap: () => setState(() => _showEffectiveCgpa = !_showEffectiveCgpa),
                  ),
                  _buildToggleLegend(
                    color: Colors.deepOrange,
                    label: 'Effective Semester GPA',
                    active: _showImprovementGpa,
                    onTap: () => setState(() => _showImprovementGpa = !_showImprovementGpa),
                    dashed: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Target Slider ────────────────────────────────────────────────
            if (widget.showPredictions) ...[
              if (K < maxSemesters) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expected Future GPA',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Set expected GPA for remaining ${maxSemesters - K} semesters',
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Congratulations! All $maxSemesters semesters completed.',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
    String? subtitle,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleLegend({
    required Color color,
    required String label,
    required bool active,
    required VoidCallback onTap,
    bool dashed = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: active ? 1.0 : 0.35,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dashed
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 3, color: color),
                    const SizedBox(width: 2),
                    Container(width: 5, height: 3, color: color),
                    const SizedBox(width: 2),
                    Container(width: 3, height: 3, color: color),
                  ])
                : Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart Painter
// ─────────────────────────────────────────────────────────────────────────────

class CgpaLineChartPainter extends CustomPainter {
  final List<double?> actualCgpas;
  final List<double>  projectedCgpas;
  final List<double?> actualGpas;
  final List<double>  projectedGpas;
  final List<double?> effectiveCgpas;
  final List<double?> improvementGpas;
  final int lastActualIndex;
  final ColorScheme themeColors;
  final bool showPredictions;
  final bool showMainCgpa;
  final bool showMainGpa;
  final bool showEffectiveCgpa;
  final bool showImprovementGpa;

  static const Color ambColor = Color(0xFFFF8F00);  // amber for effective CGPA
  static const Color impColor = Colors.deepOrange;    // deep orange for improvement GPA

  CgpaLineChartPainter({
    required this.actualCgpas,
    required this.projectedCgpas,
    required this.actualGpas,
    required this.projectedGpas,
    required this.effectiveCgpas,
    required this.improvementGpas,
    required this.lastActualIndex,
    required this.themeColors,
    required this.showPredictions,
    this.showMainCgpa = true,
    this.showMainGpa = true,
    this.showEffectiveCgpa = true,
    this.showImprovementGpa = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft   = 34.0;
    const double paddingRight  = 16.0;
    const double paddingTop    = 20.0;
    const double paddingBottom = 24.0;

    final double chartWidth  = size.width  - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop  - paddingBottom;

    final Paint gridPaint = Paint()
      ..color = themeColors.outline.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    // ── Y axis labels and grid ───────────────────────────────────────────────
    for (var yVal in [2.00, 2.50, 3.00, 3.50, 4.00]) {
      final double ny = (yVal - 2.0) / 2.0;
      final double yPos = size.height - paddingBottom - (ny * chartHeight);
      canvas.drawLine(Offset(paddingLeft, yPos), Offset(size.width - paddingRight, yPos), gridPaint);
      tp.text = TextSpan(
        text: yVal.toStringAsFixed(2),
        style: TextStyle(color: themeColors.onSurface.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 4, yPos - tp.height / 2));
    }

    final int totalSemesters = actualCgpas.length;
    if (totalSemesters < 2) return;

    // ── X axis labels ────────────────────────────────────────────────────────
    final double xStep = chartWidth / (totalSemesters - 1);
    for (int i = 0; i < totalSemesters; i++) {
      final double xPos = paddingLeft + (i * xStep);
      tp.text = TextSpan(
        text: 'S${i + 1}',
        style: TextStyle(color: themeColors.onSurface.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, Offset(xPos - tp.width / 2, size.height - paddingBottom + 6));
    }

    // ── Build point lists ─────────────────────────────────────────────────────
    double _y(double val) =>
        size.height - paddingBottom - ((val - 2.0) / 2.0).clamp(0.0, 1.0) * chartHeight;

    final List<Offset> actualCgpaPoints  = [];
    final List<Offset> projCgpaPoints    = [];
    final List<Offset> actualGpaPoints   = [];
    final List<Offset> projGpaPoints     = [];
    final List<Offset> effCgpaPoints     = [];
    final List<Offset> impGpaPoints      = [];

    for (int i = 0; i < totalSemesters; i++) {
      final double x = paddingLeft + (i * xStep);

      if (i <= lastActualIndex && actualCgpas[i] != null) {
        actualCgpaPoints.add(Offset(x, _y(actualCgpas[i]!)));
      }
      projCgpaPoints.add(Offset(x, _y(projectedCgpas[i])));

      if (i <= lastActualIndex && actualGpas[i] != null) {
        actualGpaPoints.add(Offset(x, _y(actualGpas[i]!)));
      }
      projGpaPoints.add(Offset(x, _y(projectedGpas[i])));

      if (effectiveCgpas[i] != null) {
        effCgpaPoints.add(Offset(x, _y(effectiveCgpas[i]!)));
      }
      if (improvementGpas[i] != null) {
        impGpaPoints.add(Offset(x, _y(improvementGpas[i]!)));
      }
    }

    // ── Draw lines ────────────────────────────────────────────────────────────
    // Projected GPA (dashed)
    if (showMainGpa && showPredictions && projGpaPoints.length > 1) {
      _drawLineFromPoints(canvas, projGpaPoints, themeColors.secondary.withValues(alpha: 0.35), 2.0, dashed: true);
    }
    // Projected CGPA (dashed)
    if (showMainCgpa && showPredictions && projCgpaPoints.length > 1) {
      _drawLineFromPoints(canvas, projCgpaPoints, themeColors.primary.withValues(alpha: 0.4), 3.0, dashed: true);
    }

    // Improvement GPA (dashed, deep orange)
    if (showImprovementGpa && impGpaPoints.length > 1) {
      _drawLineFromPoints(canvas, impGpaPoints, impColor.withValues(alpha: 0.8), 2.5, dashed: true);
    }

    // Actual GPA (solid)
    if (showMainGpa && actualGpaPoints.length > 1) {
      _drawLineFromPoints(canvas, actualGpaPoints, themeColors.secondary.withValues(alpha: 0.75), 2.5);
    }

    // Effective CGPA (solid amber)
    if (showEffectiveCgpa && effCgpaPoints.length > 1) {
      _drawLineFromPoints(canvas, effCgpaPoints, ambColor.withValues(alpha: 0.85), 3.0);
      // Area fill under effective CGPA
      _drawFillUnder(canvas, effCgpaPoints, ambColor.withValues(alpha: 0.08), size, paddingBottom);
    }

    // Actual CGPA (solid gradient blue)
    if (showMainCgpa && actualCgpaPoints.isNotEmpty) {
      final Paint actualPaint = Paint()
        ..shader = ui.Gradient.linear(
          actualCgpaPoints.first,
          actualCgpaPoints.last,
          [themeColors.primary, themeColors.primary.withRed(150)],
        )
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = _pathFromPoints(actualCgpaPoints);
      canvas.drawPath(path, actualPaint);
      // Area fill
      _drawFillUnder(canvas, actualCgpaPoints, themeColors.primary.withValues(alpha: 0.1), size, paddingBottom);
    }

    // ── Draw dots and value labels ────────────────────────────────────────────
    for (int i = 0; i < totalSemesters; i++) {
      if (!showPredictions && i > lastActualIndex) continue;
      final double x = paddingLeft + (i * xStep);
      final bool isActual = i <= lastActualIndex;

      // --- Official CGPA dot ---
      if (showMainCgpa) {
        final val = isActual ? (actualCgpas[i] ?? 0.0) : projectedCgpas[i];
        final pt = Offset(x, _y(projectedCgpas[i]));
        if (isActual && actualCgpas[i] != null) {
          _drawDot(canvas, pt, 5.5, themeColors.primary, themeColors.surface);
        } else {
          _drawDotOutline(canvas, pt, 4.5, themeColors.primary.withValues(alpha: 0.6), themeColors.surface);
        }
        if (val > 0) _drawLabel(canvas, tp, val, pt, themeColors.primary, isActual);
      }

      // --- Official GPA dot ---
      if (showMainGpa) {
        final val = isActual ? (actualGpas[i] ?? 0.0) : projectedGpas[i];
        final pt = Offset(x, _y(projectedGpas[i]));
        if (isActual && actualGpas[i] != null) {
          _drawDot(canvas, pt, 4.0, themeColors.secondary, themeColors.surface);
        } else {
          _drawDotOutline(canvas, pt, 3.0, themeColors.secondary.withValues(alpha: 0.6), themeColors.surface);
        }
        if (val > 0) _drawLabel(canvas, tp, val, pt, themeColors.secondary, isActual, below: true);
      }

      // --- Effective CGPA dot ---
      if (showEffectiveCgpa && effectiveCgpas[i] != null) {
        final pt = Offset(x, _y(effectiveCgpas[i]!));
        _drawDot(canvas, pt, 4.5, ambColor, themeColors.surface);
        _drawLabel(canvas, tp, effectiveCgpas[i]!, pt, ambColor, true, offset: const Offset(0, -16));
      }

      // --- Improvement GPA dot ---
      if (showImprovementGpa && improvementGpas[i] != null) {
        final pt = Offset(x, _y(improvementGpas[i]!));
        _drawDotOutline(canvas, pt, 3.5, impColor, themeColors.surface);
        _drawLabel(canvas, tp, improvementGpas[i]!, pt, impColor, true, below: true);
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Path _pathFromPoints(List<Offset> pts) {
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    return path;
  }

  void _drawLineFromPoints(Canvas canvas, List<Offset> pts, Color color, double width, {bool dashed = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = _pathFromPoints(pts);
    if (dashed) {
      _drawDashedPath(canvas, path, paint, [6, 5]);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawFillUnder(Canvas canvas, List<Offset> pts, Color color, Size size, double paddingBottom) {
    if (pts.length < 2) return;
    final fill = Path()
      ..moveTo(pts[0].dx, size.height - paddingBottom)
      ..lineTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) fill.lineTo(pts[i].dx, pts[i].dy);
    fill.lineTo(pts.last.dx, size.height - paddingBottom);
    fill.close();
    canvas.drawPath(fill, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawDot(Canvas canvas, Offset center, double radius, Color fill, Color border) {
    canvas.drawCircle(center, radius, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius, Paint()..color = border..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  void _drawDotOutline(Canvas canvas, Offset center, double radius, Color color, Color bg) {
    canvas.drawCircle(center, radius, Paint()..color = bg..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius, Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawLabel(Canvas canvas, TextPainter tp, double val, Offset pt, Color color, bool isActual,
      {bool below = false, Offset offset = Offset.zero}) {
    if (val <= 0) return;
    tp.text = TextSpan(
      text: val.toStringAsFixed(2),
      style: TextStyle(
        color: isActual ? color : color.withValues(alpha: 0.6),
        fontSize: 8.0,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.layout();
    final dy = below ? pt.dy + 6 : pt.dy - 16;
    tp.paint(canvas, Offset(pt.dx - tp.width / 2 + offset.dx, dy + offset.dy));
  }

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
  bool shouldRepaint(covariant CgpaLineChartPainter oldDelegate) => true;
}
