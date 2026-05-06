import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ShEC_CSE/core/services/storage_service.dart';

void main() {
  test('Test StorageService Upload Fallback', () async {
    HttpOverrides.global = null;
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock the SharedPreferences MethodChannel
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      },
    );
    
    print('Loading .env...');
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      print('❌ Supabase credentials missing in .env');
      return;
    }

    print('Initializing Supabase client...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );

    print('Creating temporary dummy file...');
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/test_upload.txt');
    await tempFile.writeAsString('Fallback test content generated on ${DateTime.now()}');

    print('Uploading dummy file via StorageService...');
    // We will upload to 'profile_pictures' bucket as it allows public uploads in policies
    final uploadedUrl = await StorageService.uploadFile(tempFile, 'profile_pictures');

    print('Uploaded URL result: $uploadedUrl');

    if (uploadedUrl != null) {
      print('✅ StorageService upload returned a URL!');
      expect(uploadedUrl.startsWith('http'), isTrue);

      if (uploadedUrl.contains('.supabase.co')) {
        print('ℹ️ Uploaded successfully via Supabase fallback!');
      } else {
        print('ℹ️ Uploaded successfully via Cloudflare R2!');
      }

      print('Deleting uploaded file to keep storage clean...');
      await StorageService.deleteFile(uploadedUrl);
      print('✅ Deletion finished!');
    } else {
      print('❌ StorageService upload failed completely!');
      fail('StorageService returned null for upload');
    }

    // Clean up temporary local file
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  });
}
