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
import 'package:ShEC_CSE/features/alumni/models/alumni_state.dart';

class CertificateService {
  static final SupabaseClient _client = Supabase.instance.client;

  static const List<String> certificateTypes = [
    'Appreciation',
    'Participation',
    'Excellence',
    'Leadership',
    'Special Recognition',
  ];

  /// Looks up the existing lifetime serial number for a member from `profiles`.
  /// Returns null if none exists yet.
  static Future<String?> getExistingMemberSerial(String userId) async {
    final result = await _client
        .from('profiles')
        .select('serial_number')
        .eq('id', userId)
        .maybeSingle();
    return result?['serial_number'] as String?;
  }

  /// Looks up the existing lifetime serial number for an alumni from `alumni`.
  /// Returns null if none exists yet.
  static Future<String?> getExistingAlumniSerial(String alumniId) async {
    final result = await _client
        .from('alumni')
        .select('serial_number')
        .eq('id', alumniId)
        .maybeSingle();
    return result?['serial_number'] as String?;
  }

  /// Generates, uploads to R2, and registers a certificate in the database.
  /// Supports both active members and alumni.
  /// Enforces one lifetime serial number per member/alumni.
  static Future<CertificateModel> generateCertificate({
    required BuildContext context,
    required ProfileData issuer,
    // For active members:
    ProfileData? member,
    // For alumni:
    AlumniItem? alumni,
    // Certificate details
    required String certificateType,
    required DateTime issuedDate,
    String? notes,
    String? overrideDesignation,
    String? overrideBatch,
    String? overrideSession,
  }) async {
    assert(member != null || alumni != null,
        'Either member or alumni must be provided');

    try {
      final bool isAlumni = alumni != null;
      final String memberName = isAlumni ? alumni.name : member!.name;
      final String memberId = isAlumni ? '' : member!.id; // alumni has no user_id
      final String alumniId = isAlumni ? alumni.id : '';
      final String designation = overrideDesignation ??
          (isAlumni ? alumni.currentPosition : member!.designation);
      final String batch =
          overrideBatch ?? (isAlumni ? alumni.batch : member!.batch);
      final String session =
          overrideSession ?? (isAlumni ? alumni.session : member!.session);

      // 1. Extract session start year for serial number prefix
      String sessionStartYear = 'YYYY';
      if (session.isNotEmpty) {
        final parts = session.split('-');
        if (parts.isNotEmpty) {
          sessionStartYear = parts[0].trim();
        }
      }

      // 2. Check for existing lifetime serial number
      String? existingSerial;
      if (isAlumni) {
        existingSerial = await getExistingAlumniSerial(alumniId);
      } else {
        existingSerial = await getExistingMemberSerial(memberId);
      }

      String serialNumber;
      int serialIndex;

      if (existingSerial != null) {
        // Reuse the lifetime serial number
        serialNumber = existingSerial;
        // Find the existing index for DB record consistency
        final indexResult = await _client
            .from('certificates')
            .select('serial_index')
            .eq('serial_number', existingSerial)
            .order('serial_index', ascending: false)
            .limit(1)
            .maybeSingle();
        serialIndex = (indexResult?['serial_index'] as int?) ?? 0;
      } else {
        // 3. Fetch max serial index to determine the next one globally
        final response = await _client
            .from('certificates')
            .select('serial_index')
            .order('serial_index', ascending: false)
            .limit(1)
            .maybeSingle();
        final int nextIndex =
            (response != null ? (response['serial_index'] as int) : 0) + 1;
        serialIndex = nextIndex;

        // 4. Build unique serial number
        serialNumber =
            'ShEC-CPC-$sessionStartYear-${nextIndex.toString().padLeft(4, '0')}';

        // 5. Persist the serial to the member/alumni record (lifetime assignment)
        if (isAlumni) {
          await _client
              .from('alumni')
              .update({'serial_number': serialNumber}).eq('id', alumniId);
        } else {
          await _client
              .from('profiles')
              .update({'serial_number': serialNumber}).eq('id', memberId);
        }
      }

      // 6. Generate the PDF bytes with modern design
      final Uint8List pdfBytes = await CertificatePdfGenerator.generate(
        memberName: memberName,
        memberDesignation: designation,
        memberSession: session,
        memberBatch: batch,
        serialNumber: serialNumber,
        issuedDate: issuedDate,
        certificateType: certificateType,
        notes: notes,
        isAlumni: isAlumni,
      );

      // 7. Write bytes to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$serialNumber-${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      // 8. Upload file to Cloudflare R2 (falls back to Supabase) under 'certificates'
      final String? uploadedUrl =
          await StorageService.uploadFile(tempFile, 'certificates');

      // Clean up temp file immediately
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (uploadedUrl == null) {
        throw Exception('Failed to upload certificate to Cloudflare storage.');
      }

      // 9. Insert metadata record in PostgreSQL certificates table
      final record = {
        'serial_number': serialNumber,
        'serial_index': serialIndex,
        'user_id': isAlumni ? null : memberId,
        'issued_by': issuer.id,
        'member_name': memberName,
        'member_batch': batch,
        'member_session': session,
        'member_designation': designation,
        'storage_path': uploadedUrl,
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'issued_date': issuedDate.toUtc().toIso8601String().substring(0, 10),
        'certificate_type': certificateType,
        'notes': notes,
        'is_alumni': isAlumni,
        'alumni_id': isAlumni ? alumniId : null,
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

  /// Fetches all active generated certificates (for admins/President/VP)
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
  static Future<List<CertificateModel>> fetchCertificatesForUser(
      String userId) async {
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

  /// Deletes a certificate record from the database (admin only)
  static Future<void> deleteCertificate(String certificateId) async {
    try {
      await _client.from('certificates').delete().eq('id', certificateId);
    } catch (e) {
      debugPrint('Error deleting certificate: $e');
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
          throw Exception(
              'Failed to download from Cloudflare R2: Status ${response.statusCode}');
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
