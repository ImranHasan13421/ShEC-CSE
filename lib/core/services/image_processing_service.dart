import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageProcessingService {
  /// Crop the image using image_cropper
  static Future<File?> cropImage(BuildContext context, File imageFile, {CropAspectRatio? aspectRatio}) async {
    final colors = Theme.of(context).colorScheme;
    
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: aspectRatio,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Image',
          toolbarColor: colors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: colors.secondary,
        ),
        IOSUiSettings(
          title: 'Edit Image',
        ),
      ],
    );
    
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  /// Compress image and convert to WebP
  static Future<File?> processAndConvert(File file, {int quality = 80}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "${DateTime.now().millisecondsSinceEpoch}.webp");

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.webp,
        quality: quality,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
    return file;
  }

  /// Specialized method for migrating existing network images to WebP
  static Future<File?> downloadAndConvertToWebP(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, "temp_mig_${DateTime.now().millisecondsSinceEpoch}.jpg"));
      await tempFile.writeAsBytes(response.bodyBytes);

      final targetPath = p.join(tempDir.path, "migrated_${DateTime.now().millisecondsSinceEpoch}.webp");
      
      final result = await FlutterImageCompress.compressAndGetFile(
        tempFile.path,
        targetPath,
        format: CompressFormat.webp,
        quality: 80,
      );

      if (result != null) return File(result.path);
    } catch (e) {
      debugPrint('Migration error for $url: $e');
    }
    return null;
  }
}
