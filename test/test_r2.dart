import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Helper to sign and send an S3-compatible PUT request to Cloudflare R2.
Future<bool> uploadToR2({
  required String endpoint,
  required String accessKey,
  required String secretKey,
  required String bucket,
  required String key,
  required List<int> fileBytes,
  required String contentType,
}) async {
  // 1. Prepare parameters
  final dateTime = DateTime.now().toUtc();
  final dateStr = dateTime.toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first + 'Z';
  final ymd = dateStr.substring(0, 8);
  final region = 'auto';
  final service = 's3';

  // Extract host from endpoint
  final uri = Uri.parse(endpoint);
  final host = uri.host;

  // S3 path-style URL: /bucket/key
  final canonicalUri = '/$bucket/$key';
  final requestUrl = '$endpoint/$bucket/$key';

  print('Request URL: $requestUrl');
  print('Host: $host');

  // Payload hash
  final payloadHash = sha256.convert(fileBytes).toString();

  // Headers for signing (Must be lowercase, sorted)
  final headers = {
    'content-type': contentType,
    'host': host,
    'x-amz-content-sha256': payloadHash,
    'x-amz-date': dateStr,
  };

  // 2. Canonical Request
  final canonicalHeadersStr = headers.entries
      .map((e) => '${e.key}:${e.value.trim()}\n')
      .join();
  final signedHeadersStr = headers.keys.join(';');

  final canonicalRequest = [
    'PUT',
    canonicalUri,
    '', // Canonical Query String (empty)
    canonicalHeadersStr,
    signedHeadersStr,
    payloadHash,
  ].join('\n');

  final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();

  // 3. String to Sign
  final credentialScope = '$ymd/$region/$service/aws4_request';
  final stringToSign = [
    'AWS4-HMAC-SHA256',
    dateStr,
    credentialScope,
    canonicalRequestHash,
  ].join('\n');

  // 4. Derive Signing Key
  List<int> hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }

  final kDate = hmacSha256(utf8.encode('AWS4$secretKey'), utf8.encode(ymd));
  final kRegion = hmacSha256(kDate, utf8.encode(region));
  final kService = hmacSha256(kRegion, utf8.encode(service));
  final kSigning = hmacSha256(kService, utf8.encode('aws4_request'));

  // 5. Calculate Signature
  final signature = Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

  // 6. Construct Authorization Header
  final authorization = 'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeadersStr, Signature=$signature';

  // 7. Make Request
  print('Sending HTTP PUT request...');
  try {
    final response = await http.put(
      Uri.parse(requestUrl),
      headers: {
        'Host': host,
        'x-amz-content-sha256': payloadHash,
        'x-amz-date': dateStr,
        'Authorization': authorization,
        'Content-Type': contentType,
      },
      body: fileBytes,
    );

    print('HTTP Status: ${response.statusCode}');
    print('HTTP Body: ${response.body}');
    return response.statusCode == 200;
  } catch (e) {
    print('HTTP Request Error: $e');
    return false;
  }
}

void main() async {
  print('Loading .env...');
  await dotenv.load(fileName: '.env');

  final endpoint = dotenv.env['R2_ENDPOINT'];
  final accessKey = dotenv.env['R2_ACCESS_KEY'];
  final secretKey = dotenv.env['R2_SECRET_KEY'];
  final bucket = dotenv.env['R2_BUCKET_NAME'];

  print('Endpoint: $endpoint');
  print('Access Key: $accessKey');
  print('Secret Key: $secretKey');
  print('Bucket: $bucket');

  if (endpoint == null || accessKey == null || secretKey == null || bucket == null) {
    print('❌ Credentials missing!');
    return;
  }

  print('Starting test upload using custom AWS SigV4 PUT...');
  final testBytes = utf8.encode('Hello pure Dart Cloudflare R2 Upload!');
  final success = await uploadToR2(
    endpoint: endpoint,
    accessKey: accessKey,
    secretKey: secretKey,
    bucket: bucket,
    key: 'test/pure_dart_dummy.txt',
    fileBytes: testBytes,
    contentType: 'text/plain',
  );

  if (success) {
    print('✅ Custom SigV4 PUT upload succeeded!');
  } else {
    print('❌ Custom SigV4 PUT upload failed!');
  }
}
