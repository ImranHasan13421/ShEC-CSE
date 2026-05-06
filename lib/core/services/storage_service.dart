import 'dart:io';
import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static S3? _s3Instance;

  static S3 get _s3 {
    if (_s3Instance == null) {
      final endpoint = dotenv.env['R2_ENDPOINT'];
      final accessKey = dotenv.env['R2_ACCESS_KEY'];
      final secretKey = dotenv.env['R2_SECRET_KEY'];

      if (endpoint == null || accessKey == null || secretKey == null) {
        throw Exception('Cloudflare R2 credentials missing in .env');
      }

      _s3Instance = S3(
        region: 'auto',
        endpointUrl: endpoint,
        credentials: AwsClientCredentials(
          accessKey: accessKey,
          secretKey: secretKey,
        ),
      );
    }
    return _s3Instance!;
  }

  static String get _bucket => dotenv.env['R2_BUCKET_NAME'] ?? '';
  static String get _publicUrl => dotenv.env['R2_PUBLIC_URL'] ?? '';

  /// Uploads a file, trying Cloudflare R2 first.
  /// If it fails, falls back seamlessly to Supabase Storage!
  static Future<String?> uploadFile(File file, String folder) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(RegExp(r'[/\\]')).last}';
    final key = '$folder/$fileName';

    // 1. Try Cloudflare R2 Upload
    try {
      debugPrint('Attempting R2 upload for $key...');
      await _s3.putObject(
        bucket: _bucket,
        key: key,
        body: await file.readAsBytes(),
        contentType: _getContentType(file.path),
      );
      
      final r2Url = '$_publicUrl/$key';
      debugPrint('R2 upload successful: $r2Url');
      return r2Url;
    } catch (e) {
      debugPrint('R2 Upload failed/refused ($e). Falling back to Supabase Storage...');
      
      // 2. Fallback to Supabase Storage
      try {
        final supabase = Supabase.instance.client;
        final fileBytes = await file.readAsBytes();
        
        debugPrint('Uploading to Supabase Storage bucket "$folder" with path "$fileName"...');
        await supabase.storage.from(folder).uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: null, // will auto-detect or we can pass our MIME type
            upsert: true,
          ),
        );
        
        final supabaseUrl = supabase.storage.from(folder).getPublicUrl(fileName);
        debugPrint('Supabase Storage fallback upload successful: $supabaseUrl');
        return supabaseUrl;
      } catch (supabaseError) {
        debugPrint('Supabase Storage upload fallback also failed: $supabaseError');
        return null;
      }
    }
  }

  /// Deletes a file, checking if it is an R2 URL or Supabase Storage URL.
  static Future<void> deleteFile(String url) async {
    try {
      if (url.startsWith(_publicUrl)) {
        // R2 deletion
        final key = url.replaceFirst('$_publicUrl/', '');
        debugPrint('Deleting from R2: $key');
        await _s3.deleteObject(bucket: _bucket, key: key);
      } else if (url.contains('.supabase.co/storage/')) {
        // Supabase Storage deletion
        debugPrint('Deleting from Supabase Storage: $url');
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        // Supabase URL format: https://[project].supabase.co/storage/v1/object/public/[bucket]/[filename]
        final bucketIndex = pathSegments.indexOf('public') + 1;
        if (bucketIndex > 0 && bucketIndex < pathSegments.length - 1) {
          final bucket = pathSegments[bucketIndex];
          final filename = pathSegments.sublist(bucketIndex + 1).join('/');
          final supabase = Supabase.instance.client;
          await supabase.storage.from(bucket).remove([filename]);
          debugPrint('Successfully deleted from Supabase bucket "$bucket": $filename');
        }
      }
    } catch (e) {
      debugPrint('Deletion Error for URL ($url): $e');
    }
  }

  /// Lists all files in Cloudflare R2 folder and falls back to Supabase Storage bucket.
  static Future<List<String>> listFiles(String folder) async {
    // Try R2 listing first
    try {
      final response = await _s3.listObjectsV2(
        bucket: _bucket,
        prefix: '$folder/',
      );
      return response.contents?.map((c) => c.key!).toList() ?? [];
    } catch (e) {
      debugPrint('R2 List Error: $e. Listing from Supabase Storage...');
      try {
        final supabase = Supabase.instance.client;
        final list = await supabase.storage.from(folder).list();
        return list.map((item) => '$folder/${item.name}').toList();
      } catch (supabaseError) {
        debugPrint('Supabase List Error: $supabaseError');
        return [];
      }
    }
  }

  /// Deletes multiple files, sorting between R2 keys and Supabase Storage paths.
  static Future<void> deleteFiles(List<String> keys) async {
    final List<String> r2Keys = [];
    final Map<String, List<String>> supabaseBucketToFiles = {};

    for (final key in keys) {
      // Keys from listFiles could be 'bucket/filename' if listed from Supabase, or 'folder/filename' from R2
      if (key.startsWith('http')) {
        await deleteFile(key);
      } else {
        // Assume key is format: 'folder/filename' or 'bucket/filename'
        final parts = key.split('/');
        if (parts.length >= 2) {
          final folderOrBucket = parts.first;
          final filename = parts.sublist(1).join('/');
          
          // Let's check if the bucket matches one of our Supabase Storage buckets
          final knownBuckets = {'profile_pictures', 'notice_images', 'gallery_images', 'teacher_images', 'alumni_images'};
          if (knownBuckets.contains(folderOrBucket)) {
            supabaseBucketToFiles.putIfAbsent(folderOrBucket, () => []).add(filename);
          } else {
            r2Keys.add(key);
          }
        } else {
          r2Keys.add(key);
        }
      }
    }

    // Delete from R2
    if (r2Keys.isNotEmpty) {
      try {
        debugPrint('Bulk deleting from R2: $r2Keys');
        await _s3.deleteObjects(
          bucket: _bucket,
          delete: Delete(
            objects: r2Keys.map((key) => ObjectIdentifier(key: key)).toList(),
          ),
        );
      } catch (e) {
        debugPrint('R2 Bulk Delete Error: $e');
      }
    }

    // Delete from Supabase Storage
    if (supabaseBucketToFiles.isNotEmpty) {
      final supabase = Supabase.instance.client;
      for (final entry in supabaseBucketToFiles.entries) {
        try {
          debugPrint('Bulk deleting from Supabase storage bucket "${entry.key}": ${entry.value}');
          await supabase.storage.from(entry.key).remove(entry.value);
        } catch (e) {
          debugPrint('Supabase Bulk Delete Error: $e');
        }
      }
    }
  }

  static String _getContentType(String path) {
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
