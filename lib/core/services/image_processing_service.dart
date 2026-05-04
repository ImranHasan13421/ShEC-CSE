import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

      // We use compressAndGetFile to convert to WebP
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
    return file; // Fallback to original if compression fails
  }
}
