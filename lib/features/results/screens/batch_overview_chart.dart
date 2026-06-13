import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/batch_member_result.dart';

// ============================================================
//  Helper: CGPA bracket descriptor
// ============================================================

class _CgpaBracket {
  final String label;
  final double min;
  final double max;
  final Color color;

  const _CgpaBracket(this.label, this.min, this.max, this.color);
}

// ============================================================
//  Shared semester parser (avoids duplication across widgets)
// ============================================================

int parseSemesterFromExamName(String examName) {
  final n = examName.toLowerCase();
  if (n.contains('1st year 1st') || n.contains('1st sem') || n.contains('1-1') || (n.contains('1st year') && n.contains('1st'))) return 1;
  if (n.contains('1st year 2nd') || n.contains('2nd sem') || n.contains('1-2') || (n.contains('1st year') && n.contains('2nd'))) return 2;
  if (n.contains('2nd year 1st') || n.contains('3rd sem') || n.contains('2-1') || (n.contains('2nd year') && n.contains('1st'))) return 3;
  if (n.contains('2nd year 2nd') || n.contains('4th sem') || n.contains('2-2') || (n.contains('2nd year') && n.contains('2nd'))) return 4;
  if (n.contains('3rd year 1st') || n.contains('5th sem') || n.contains('3-1') || (n.contains('3rd year') && n.contains('1st'))) return 5;
  if (n.contains('3rd year 2nd') || n.contains('6th sem') || n.contains('3-2') || (n.contains('3rd year') && n.contains('2nd'))) return 6;
  if (n.contains('4th year 1st') || n.contains('7th sem') || n.contains('4-1') || (n.contains('4th year') && n.contains('1st'))) return 7;
  if (n.contains('4th year 2nd') || n.contains('8th sem') || n.contains('4-2') || (n.contains('4th year') && n.contains('2nd'))) return 8;
  if (n.contains('1st')) return 1;
  if (n.contains('2nd')) return 2;
  if (n.contains('3rd')) return 3;
  if (n.contains('4th')) return 4;
  if (n.contains('5th')) return 5;
  if (n.contains('6th')) return 6;
  if (n.contains('7th')) return 7;
  if (n.contains('8th')) return 8;
  return 1;
}

/// Returns the latest CGPA for a given student from a list of BatchMemberResults.
double getLatestCgpaFromResults(String studentId, List<BatchMemberResult> results) {
  double latestCgpa = 0.0;
  int maxSem = 0;
  for (var r in results) {
    if (r.profile.id == studentId) {
      final sem = r.result.semester ?? parseSemesterFromExamName(r.result.examName);
      if (sem > maxSem) {
        maxSem = sem;
        final val = double.tryParse(r.result.cgpa) ?? 0.0;
        if (val > 0.0) latestCgpa = val;
      }
    }
  }
  // Fallback: average GPAs if CGPA field is missing
  if (latestCgpa == 0.0) {
    double sum = 0;
    int cnt = 0;
    for (var r in results) {
      if (r.profile.id == studentId) {
        final g = double.tryParse(r.result.gpa) ?? 0.0;
        if (g > 0.0) {
          sum += g;
          cnt++;
        }
      }
    }
    if (cnt > 0) latestCgpa = sum / cnt;
  }
  return latestCgpa;
}

// ============================================================
//  BatchCgpaDistributionChart
//  Horizontal bar chart grouping students by latest CGPA range.
// ============================================================

class BatchCgpaDistributionChart extends StatelessWidget {
  final List<BatchMemberResult> results;

  const BatchCgpaDistributionChart({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final studentIds = results.map((r) => r.profile.id).toSet().toList();

    final brackets = [
      _CgpaBracket('< 2.0',    0.001, 2.0,  Colors.red),
      _CgpaBracket('2.0–2.5',  2.0,   2.5,  Colors.orange),
      _CgpaBracket('2.5–3.0',  2.5,   3.0,  Colors.amber),
      _CgpaBracket('3.0–3.5',  3.0,   3.5,  const Color(0xFF00897B)), // teal
      _CgpaBracket('3.5–4.0',  3.5,   4.01, Colors.green),
    ];

    final counts = List<int>.filled(brackets.length, 0);
    int total = 0;

    for (var id in studentIds) {
      final cgpa = getLatestCgpaFromResults(id, results);
      if (cgpa > 0) {
        total++;
        for (int i = 0; i < brackets.length; i++) {
          if (cgpa >= brackets[i].min && cgpa < brackets[i].max) {
            counts[i]++;
            break;
          }
        }
      }
    }

    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'No CGPA data available yet',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.45), fontSize: 12),
          ),
        ),
      );
    }

    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart_rounded, size: 14, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              'CGPA Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.onSurface.withValues(alpha: 0.8)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$total students',
                style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(brackets.length, (i) {
          final b = brackets[i];
          final count = counts[i];
          final fraction = maxCount > 0 ? count / maxCount : 0.0;
          final pct = total > 0 ? '${(count / total * 100).round()}%' : '0%';

          return Padding(
            padding: const EdgeInsets.only(bottom: 7.0),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  child: Text(
                    b.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.02, 1.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [b.color.withValues(alpha: 0.9), b.color.withValues(alpha: 0.55)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerRight,
                          child: count > 0
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 34,
                  child: Text(
                    pct,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================
//  BatchGpaTrendChart
//  Line chart showing batch-average GPA per semester (1–8).
// ============================================================

class BatchGpaTrendChart extends StatelessWidget {
  final List<BatchMemberResult> results;

  const BatchGpaTrendChart({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Compute per-semester average GPA across all students
    final Map<int, List<double>> gpasBySem = {};
    for (var r in results) {
      final sem = r.result.semester ?? parseSemesterFromExamName(r.result.examName);
      final gpa = double.tryParse(r.result.gpa) ?? 0.0;
      if (gpa > 0.0) gpasBySem.putIfAbsent(sem, () => []).add(gpa);
    }

    final List<double?> avgGpas = List.filled(8, null);
    for (int s = 1; s <= 8; s++) {
      final list = gpasBySem[s];
      if (list != null && list.isNotEmpty) {
        avgGpas[s - 1] = list.reduce((a, b) => a + b) / list.length;
      }
    }

    if (!avgGpas.any((g) => g != null)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'No GPA trend data available yet',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.45), fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart_rounded, size: 14, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              'Semester-Wise Avg GPA Trend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.onSurface.withValues(alpha: 0.8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomPaint(
            painter: _GpaTrendPainter(avgGpas: avgGpas, colors: colors),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 4),
        // X-axis labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(8, (i) => Expanded(
            child: Text(
              'S${i + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: colors.onSurface.withValues(alpha: 0.45)),
            ),
          )),
        ),
      ],
    );
  }
}

class _GpaTrendPainter extends CustomPainter {
  final List<double?> avgGpas;
  final ColorScheme colors;

  _GpaTrendPainter({required this.avgGpas, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const double pL = 32.0, pR = 8.0, pT = 16.0, pB = 4.0;
    final double w = size.width - pL - pR;
    final double h = size.height - pT - pB;
    const double minV = 0.0, maxV = 4.0;

    // --- Grid lines & Y labels ---
    final gridPaint = Paint()
      ..color = colors.outline.withValues(alpha: 0.12)
      ..strokeWidth = 0.8;

    for (final v in [1.0, 2.0, 3.0, 4.0]) {
      final y = pT + h * (1.0 - (v - minV) / (maxV - minV));
      canvas.drawLine(Offset(pL, y), Offset(pL + w, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: v.toStringAsFixed(1),
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.35),
            fontSize: 8.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // --- Collect data points ---
    final List<Offset> points = [];
    for (int i = 0; i < 8; i++) {
      if (avgGpas[i] != null) {
        final x = pL + (i / 7.0) * w;
        final y = pT + h * (1.0 - (avgGpas[i]! - minV) / (maxV - minV));
        points.add(Offset(x, y));
      }
    }

    if (points.isEmpty) return;

    // --- Fill area under line ---
    if (points.length >= 2) {
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height - pB)
        ..lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final cpX = (points[i - 1].dx + points[i].dx) / 2;
        fillPath.cubicTo(cpX, points[i - 1].dy, cpX, points[i].dy, points[i].dx, points[i].dy);
      }

      fillPath
        ..lineTo(points.last.dx, size.height - pB)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, pT),
            Offset(0, size.height - pB),
            [colors.primary.withValues(alpha: 0.22), colors.primary.withValues(alpha: 0.0)],
          )
          ..style = PaintingStyle.fill,
      );

      // --- Smooth line ---
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final cpX = (points[i - 1].dx + points[i].dx) / 2;
        linePath.cubicTo(cpX, points[i - 1].dy, cpX, points[i].dy, points[i].dx, points[i].dy);
      }

      canvas.drawPath(
        linePath,
        Paint()
          ..color = colors.primary
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (points.length == 1) {
      canvas.drawCircle(points.first, 4, Paint()..color = colors.primary);
    }

    // --- Dots & value labels ---
    int ptIdx = 0;
    for (int i = 0; i < 8; i++) {
      if (avgGpas[i] == null) continue;
      final pt = points[ptIdx++];
      final val = avgGpas[i]!;

      // Outer dot
      canvas.drawCircle(pt, 4.0, Paint()..color = colors.primary..style = PaintingStyle.fill);
      // Inner ring (white)
      canvas.drawCircle(pt, 4.0, Paint()..color = colors.surface..strokeWidth = 1.5..style = PaintingStyle.stroke);

      // Value label above dot
      final tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(2),
          style: TextStyle(
            color: colors.primary,
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height - 4));
    }
  }

  @override
  bool shouldRepaint(_GpaTrendPainter old) =>
      old.avgGpas != avgGpas || old.colors != colors;
}
