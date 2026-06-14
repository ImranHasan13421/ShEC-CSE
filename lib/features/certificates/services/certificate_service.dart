import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';
import 'package:ShEC_CSE/features/certificates/models/certificate_model.dart';
import 'package:ShEC_CSE/features/certificates/utils/certificate_pdf_generator.dart';
import 'package:ShEC_CSE/features/results/utils/results_pdf_generator.dart';
import 'package:ShEC_CSE/core/services/storage_service.dart';
import 'package:ShEC_CSE/core/utils/snackbar_utils.dart';

class CertificateService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Generates, uploads to R2, and registers a certificate in the database
  static Future<CertificateModel> generateCertificate({
    required BuildContext context,
    required ProfileData issuer,
    required ProfileData member,
  }) async {
    try {
      // 1. Extract session start year
      String sessionStartYear = 'YYYY';
      if (member.session.isNotEmpty) {
        final parts = member.session.split('-');
        if (parts.isNotEmpty) {
          sessionStartYear = parts[0].trim();
        }
      }

      // 2. Fetch max serial index to determine the next one
      final response = await _client
          .from('certificates')
          .select('serial_index')
          .order('serial_index', ascending: false)
          .limit(1)
          .maybeSingle();

      final int nextIndex = (response != null ? (response['serial_index'] as int) : 0) + 1;

      // 3. Build unique serial number
      final String serialNumber = 'ShEC-CPC-$sessionStartYear-${nextIndex.toString().padLeft(4, '0')}';

      // 4. Generate the PDF bytes
      final DateTime issueDate = DateTime.now();
      final Uint8List pdfBytes = await CertificatePdfGenerator.generate(
        memberName: member.name,
        memberDesignation: member.designation,
        memberSession: member.session,
        memberBatch: member.batch,
        serialNumber: serialNumber,
        issueDate: issueDate,
      );

      // 5. Write bytes to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$serialNumber.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      // 6. Upload file to Cloudflare R2 (falls back to Supabase) under folder/bucket 'certificates'
      final String? uploadedUrl = await StorageService.uploadFile(tempFile, 'certificates');

      // Clean up the local temp file immediately
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (uploadedUrl == null) {
        throw Exception('Failed to upload certificate to Cloudflare storage.');
      }

      // 7. Insert metadata record in PostgreSQL certificates table
      final record = {
        'serial_number': serialNumber,
        'serial_index': nextIndex,
        'user_id': member.id,
        'issued_by': issuer.id,
        'member_name': member.name,
        'member_batch': member.batch,
        'member_session': member.session,
        'member_designation': member.designation,
        'storage_path': uploadedUrl,
        'generated_at': issueDate.toUtc().toIso8601String(),
      };

      final insertedData = await _client
          .from('certificates')
          .insert(record)
          .select()
          .single();

      return CertificateModel.fromJson(insertedData);
    } catch (e) {
      debugPrint('Error generating certificate: $e');
      rethrow;
    }
  }

  /// Fetches all active generated certificates (usually for admins/President/VP)
  static Future<List<CertificateModel>> fetchAllCertificates() async {
    try {
      final List<dynamic> response = await _client
          .from('certificates')
          .select()
          .order('generated_at', ascending: false);

      return response.map((json) => CertificateModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all certificates: $e');
      rethrow;
    }
  }

  /// Fetches certificates for a specific user
  static Future<List<CertificateModel>> fetchCertificatesForUser(String userId) async {
    try {
      final List<dynamic> response = await _client
          .from('certificates')
          .select()
          .eq('user_id', userId)
          .order('generated_at', ascending: false);

      return response.map((json) => CertificateModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching certificates for user: $e');
      rethrow;
    }
  }

  /// Downloads the certificate PDF bytes (from R2 or Supabase Storage) and saves/shares it
  static Future<void> downloadCertificate(
    BuildContext context,
    CertificateModel certificate,
  ) async {
    try {
      Uint8List pdfBytes;
      if (certificate.storagePath.startsWith('http')) {
        // Download from Cloudflare R2 public URL
        final response = await http.get(Uri.parse(certificate.storagePath));
        if (response.statusCode == 200) {
          pdfBytes = response.bodyBytes;
        } else {
          throw Exception('Failed to download from Cloudflare R2: Status ${response.statusCode}');
        }
      } else {
        // Fallback: download from Supabase Storage
        pdfBytes = await _client.storage
            .from('certificates')
            .download(certificate.storagePath);
      }

      // Save or share using the results generator's helper
      final String filename = 'certificate_${certificate.serialNumber}.pdf';
      if (context.mounted) {
        await ResultsPdfGenerator.savePdfFile(
          context: context,
          pdfBytes: pdfBytes,
          filename: filename,
        );
      }
    } catch (e) {
      debugPrint('Error downloading certificate: $e');
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Failed to download certificate: $e');
      }
    }
  }
}
