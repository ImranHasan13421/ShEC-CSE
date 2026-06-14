import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class CertificatePdfGenerator {
  /// Generates PDF bytes for the certificate in landscape orientation
  static Future<Uint8List> generate({
    required String memberName,
    required String memberDesignation,
    required String memberSession,
    required String memberBatch,
    required String serialNumber,
    required DateTime issueDate,
  }) async {
    final pdf = pw.Document();

    // Load the logo from assets
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/branding/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Fallback if logo loading fails
      logoImage = null;
    }

    final formattedDate = DateFormat('dd MMM, yyyy').format(issueDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.all(12),
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 3),
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.indigo900, width: 1),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and College Header
                  pw.Column(
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Image(logoImage, width: 60, height: 60),
                        ),
                      pw.Text(
                        'Shyamoli Engineering College (ShEC)',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'COMPUTER PROGRAMMING CLUB (CPC)',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        width: 250,
                        height: 1,
                        color: PdfColors.indigo200,
                      ),
                    ],
                  ),

                  // Certificate Body
                  pw.Column(
                    children: [
                      pw.Text(
                        'CERTIFICATE OF APPRECIATION',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber800,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'This certificate is proudly presented to',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        memberName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                        child: pw.Text(
                          'in recognition of their dedicated service and outstanding contribution as "$memberDesignation" of ShEC Computer Programming Club, Department of Computer Science & Engineering, Shyamoli Engineering College, during the academic session $memberSession (Batch: $memberBatch).',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(
                            fontSize: 11,
                            lineSpacing: 4.5,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Section: Date, Serial, and Signatures
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // President Signature (Left)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 150,
                            margin: const pw.EdgeInsets.only(bottom: 5),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.8),
                              ),
                            ),
                          ),
                          pw.Text(
                            'Club President',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo900,
                            ),
                          ),
                          pw.Text(
                            'ShEC CPC',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),

                      // Issued Date & Serial Number (Middle/Info)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Serial No: $serialNumber',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo,
                            ),
                          ),
                          pw.Text(
                            'Date of Issue: $formattedDate',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                        ],
                      ),

                      // Head of Dept Signature (Right)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 150,
                            margin: const pw.EdgeInsets.only(bottom: 5),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.8),
                              ),
                            ),
                          ),
                          pw.Text(
                            'Head of Department',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo900,
                            ),
                          ),
                          pw.Text(
                            'Dept. of CSE, ShEC',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
