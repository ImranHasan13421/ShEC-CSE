import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/results/models/result_state.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';

class ResultsPdfGenerator {
  static int _parseSemesterNumber(String examName) {
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

  static String _getYearName(int year) {
    switch (year) {
      case 1: return '1st Year';
      case 2: return '2nd Year';
      case 3: return '3rd Year';
      case 4: return '4th Year';
      default: return 'Academic Results';
    }
  }

  /// Generates a PDF for a single semester result
  static Future<void> generateAndShareSemesterPdf(
    BuildContext context, 
    ProfileData profile, 
    ExamResult result,
  ) async {
    final pdf = pw.Document();
    final semNum = result.semester ?? _parseSemesterNumber(result.examName);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Shyamoli Engineering College (ShEC)',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Department of Computer Science & Engineering',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Academic Transcript / Semester Result', 
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Student Name: ${profile.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Registration No: ${profile.duRegNo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Exam Name: ${result.examName}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Session: ${profile.session}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GPA: ${result.gpa}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('CGPA: ${result.cgpa}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2), // Code
                    1: const pw.FlexColumnWidth(5), // Title
                    2: const pw.FlexColumnWidth(1.5), // Credits
                    3: const pw.FlexColumnWidth(1.5), // Grade
                    4: const pw.FlexColumnWidth(1.5), // Point
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Course Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Course Title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Credits', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Grade', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Point', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center),
                        ),
                      ],
                    ),
                    ...result.subjects.map((s) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(s.code, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(s.name, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(s.credits.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(s.grade, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(s.point, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                        ),
                      ],
                    )),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Generated on: ${DateTime.now().toLocal().toString().split(".")[0]}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('ShEC CPC - 2026', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final String cleanFilename = 'result_${profile.duRegNo}_semester_$semNum.pdf';
    if (context.mounted) {
      await savePdfFile(context: context, pdfBytes: bytes, filename: cleanFilename);
    }
  }

  /// Generates a consolidated PDF grouping results by year on separate pages
  static Future<void> generateAndShareConsolidatedPdf(
    BuildContext context, 
    ProfileData profile, 
    List<ExamResult> results,
  ) async {
    final pdf = pw.Document();

    final sortedResults = List<ExamResult>.from(results)
      ..sort((a, b) {
        final semA = a.semester ?? _parseSemesterNumber(a.examName);
        final semB = b.semester ?? _parseSemesterNumber(b.examName);
        return semA.compareTo(semB);
      });

    // Group sorted results by Year (1 to 4)
    final Map<int, List<ExamResult>> resultsByYear = {};
    for (var r in sortedResults) {
      final sem = r.semester ?? _parseSemesterNumber(r.examName);
      final year = ((sem - 1) ~/ 2) + 1; // 1 for sem 1-2, 2 for sem 3-4, etc.
      if (year >= 1 && year <= 4) {
        resultsByYear.putIfAbsent(year, () => []).add(r);
      }
    }

    // Add a separate page for each year
    for (int year = 1; year <= 4; year++) {
      final yearResults = resultsByYear[year];
      if (yearResults == null || yearResults.isEmpty) continue;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // College and Dept Header
                  pw.Center(
                    child: pw.Text(
                      'Shyamoli Engineering College (ShEC)',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'Department of Computer Science & Engineering',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Center(
                    child: pw.Text(
                      'CONSOLIDATED ACADEMIC REPORT - ${_getYearName(year).toUpperCase()}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                    ),
                  ),
                  pw.SizedBox(height: 15),

                  // Student Details Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Student Name: ${profile.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('Registration No: ${profile.duRegNo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Session: ${profile.session}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Batch: ${profile.batch}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),

                  // Tables for the semesters of this year
                  ...yearResults.expand((result) => [
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Semester ${result.semester ?? _parseSemesterNumber(result.examName)} (${result.examName})',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'GPA: ${result.gpa}    CGPA: ${result.cgpa}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2),
                        1: const pw.FlexColumnWidth(5),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(1.5),
                        4: const pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Course Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Course Title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Credits', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Grade', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('Point', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
                            ),
                          ],
                        ),
                        ...result.subjects.map((s) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(s.code, style: const pw.TextStyle(fontSize: 7.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(s.name, style: const pw.TextStyle(fontSize: 7.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(s.credits.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(s.grade, style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(s.point, style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ]),

                  pw.Spacer(),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Generated on: ${DateTime.now().toLocal().toString().split(".")[0]}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text('ShEC CSE Academic Portal', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final bytes = await pdf.save();
    final String cleanFilename = 'academic_report_${profile.duRegNo}.pdf';
    if (context.mounted) {
      await savePdfFile(context: context, pdfBytes: bytes, filename: cleanFilename);
    }
  }

  /// Reusable save method that handles direct download folder write or shares on iOS
  static Future<void> savePdfFile({
    required BuildContext context,
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    try {
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download/ShEC CSE');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        if (context.mounted) {
          SnackBarUtils.showSuccess(
            context,
            'Successfully saved to Download folder "ShEC CSE"!',
          );
        }
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      }
    } catch (e) {
      debugPrint('Error saving PDF to public folder, falling back to share: $e');
      try {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      } catch (shareError) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Failed to save or share PDF: $shareError');
        }
      }
    }
  }
}
