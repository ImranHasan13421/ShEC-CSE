import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class CertificatePdfGenerator {
  // ── Design Tokens ──────────────────────────────────────────────────────────
  static const PdfColor _navy = PdfColor.fromInt(0xFF0D1B3E);
  static const PdfColor _navyMid = PdfColor.fromInt(0xFF1A3260);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC9A84C);
  static const PdfColor _goldLight = PdfColor.fromInt(0xFFE8CB7A);
  static const PdfColor _cream = PdfColor.fromInt(0xFFFDFAF2);
  static const PdfColor _greyText = PdfColor.fromInt(0xFF4A4A4A);
  static const PdfColor _lightGold = PdfColor.fromInt(0xFFF5E6B8);

  /// Generates PDF bytes for the certificate in landscape orientation
  static Future<Uint8List> generate({
    required String memberName,
    required String memberDesignation,
    required String memberSession,
    required String memberBatch,
    required String serialNumber,
    required DateTime issuedDate,
    String certificateType = 'Appreciation',
    String? notes,
    bool isAlumni = false,
  }) async {
    final pdf = pw.Document();

    // Load logo from assets
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/branding/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final formattedDate = DateFormat('dd MMMM, yyyy').format(issuedDate);
    final memberTypeLabel = isAlumni ? 'Alumni' : 'Member';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // ── Layer 1: Dark navy background ──────────────────────────
              pw.Container(
                width: double.infinity,
                height: double.infinity,
                color: _navy,
              ),

              // ── Layer 2: Gold left stripe ──────────────────────────────
              pw.Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: pw.Container(width: 14, color: _gold),
              ),

              // ── Layer 3: Inner cream content panel ─────────────────────
              pw.Padding(
                padding: const pw.EdgeInsets.only(
                    left: 28, top: 14, right: 14, bottom: 14),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: _cream,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _gold, width: 1.5),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(32, 18, 32, 18),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // ── Header ──────────────────────────────────────
                        _buildHeader(logoImage),

                        // ── Gold divider ─────────────────────────────────
                        _buildGoldDivider(),

                        // ── Certificate body ─────────────────────────────
                        _buildBody(
                          memberName: memberName,
                          memberDesignation: memberDesignation,
                          memberSession: memberSession,
                          memberBatch: memberBatch,
                          certificateType: certificateType,
                          notes: notes,
                          memberTypeLabel: memberTypeLabel,
                        ),

                        // ── Gold divider ─────────────────────────────────
                        _buildGoldDivider(),

                        // ── Footer ───────────────────────────────────────
                        _buildFooter(
                          formattedDate: formattedDate,
                          serialNumber: serialNumber,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Layer 4: Corner ornaments ──────────────────────────────
              // Top-left corner (after stripe)
              pw.Positioned(
                top: 22,
                left: 36,
                child: _buildCorner(),
              ),
              // Top-right corner
              pw.Positioned(
                top: 22,
                right: 22,
                child: _buildCorner(flipH: true),
              ),
              // Bottom-left corner
              pw.Positioned(
                bottom: 22,
                left: 36,
                child: _buildCorner(flipV: true),
              ),
              // Bottom-right corner
              pw.Positioned(
                bottom: 22,
                right: 22,
                child: _buildCorner(flipH: true, flipV: true),
              ),

              // ── Layer 5: Watermark logo (very faint) ───────────────────
              if (logoImage != null)
                pw.Center(
                  child: pw.Container(
                    width: 220,
                    height: 220,
                    // Use a light gold background tint as the "watermark"
                    // The pdf package doesn't support opacity directly,
                    // so we use a very pale tinted container approach
                    child: pw.CustomPaint(
                      size: const PdfPoint(220, 220),
                      painter: (canvas, size) {
                        // No-op — simple watermark via image below
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ─── Sub-builders ──────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(pw.MemoryImage? logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (logoImage != null)
          pw.Container(
            margin: const pw.EdgeInsets.only(right: 14),
            width: 50,
            height: 50,
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Shyamoli Engineering College (ShEC)',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.4,
                color: _greyText,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              'Computer Programming Club (CPC)',
              style: pw.TextStyle(
                fontSize: 8,
                color: _gold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildGoldDivider() {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Container(height: 1, color: _gold)),
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 8),
          width: 6,
          height: 6,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: _gold,
          ),
        ),
        pw.Expanded(child: pw.Container(height: 1, color: _gold)),
      ],
    );
  }

  static pw.Widget _buildBody({
    required String memberName,
    required String memberDesignation,
    required String memberSession,
    required String memberBatch,
    required String certificateType,
    required String memberTypeLabel,
    String? notes,
  }) {
    final String recognitionLine = (notes != null && notes.trim().isNotEmpty)
        ? notes.trim()
        : 'in recognition of their dedicated service and outstanding contribution'
            ' as "$memberDesignation" of ShEC Computer Programming Club, Department'
            ' of Computer Science & Engineering, Shyamoli Engineering College,'
            ' during the academic session $memberSession (Batch: $memberBatch).';

    return pw.Column(
      children: [
        // Certificate type in gold caps
        pw.Text(
          'CERTIFICATE OF ${certificateType.toUpperCase()}',
          style: pw.TextStyle(
            fontSize: 21,
            fontWeight: pw.FontWeight.bold,
            color: _gold,
            letterSpacing: 2.5,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),

        pw.Text(
          'This certificate is proudly presented to',
          style: pw.TextStyle(
            fontSize: 11,
            fontStyle: pw.FontStyle.italic,
            color: _greyText,
          ),
        ),
        pw.SizedBox(height: 6),

        // Member name
        pw.Text(
          memberName,
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            color: _navy,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 3),

        // Gold underline bar below name
        pw.Container(
          width: 160,
          height: 2,
          color: _gold,
        ),
        pw.SizedBox(height: 8),

        // Designation badge
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: pw.BoxDecoration(
            color: _lightGold,
            border: pw.Border.all(color: _gold, width: 0.8),
            borderRadius: pw.BorderRadius.circular(20),
          ),
          child: pw.Text(
            '$memberDesignation  ·  $memberTypeLabel',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _navyMid,
              letterSpacing: 0.5,
            ),
          ),
        ),
        pw.SizedBox(height: 10),

        // Recognition text
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Text(
            recognitionLine,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 10,
              lineSpacing: 4.5,
              color: _greyText,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required String formattedDate,
    required String serialNumber,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildSignatureBlock('Club President', 'ShEC CPC'),

        // Centre info block
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Navy serial chip
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                serialNumber,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _goldLight,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date of Issue: $formattedDate',
              style: const pw.TextStyle(fontSize: 8, color: _greyText),
            ),
          ],
        ),

        _buildSignatureBlock('Head of Department', 'Dept. of CSE, ShEC'),
      ],
    );
  }

  static pw.Widget _buildSignatureBlock(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 130,
          margin: const pw.EdgeInsets.only(bottom: 5),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _navy, width: 0.8),
            ),
          ),
        ),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _navy,
          ),
        ),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(fontSize: 8, color: _greyText),
        ),
      ],
    );
  }

  /// Draws an L-bracket corner ornament using CustomPaint.
  static pw.Widget _buildCorner({bool flipH = false, bool flipV = false}) {
    return pw.CustomPaint(
      size: const PdfPoint(18, 18),
      painter: (canvas, size) {
        canvas.setStrokeColor(_gold);
        canvas.setLineWidth(1.5);
        final double w = size.x;
        final double h = size.y;
        final double arm = 14;

        final double x0 = flipH ? w : 0;
        final double y0 = flipV ? h : 0;
        final double xEnd = flipH ? w - arm : arm;
        final double yEnd = flipV ? h - arm : arm;

        // Horizontal arm
        canvas.drawLine(x0, y0, xEnd, y0);
        // Vertical arm
        canvas.drawLine(x0, y0, x0, yEnd);
        canvas.strokePath();

        // Corner dot
        canvas.setFillColor(_gold);
        canvas.drawEllipse(x0, y0, 2.5, 2.5);
        canvas.fillPath();
      },
    );
  }
}
