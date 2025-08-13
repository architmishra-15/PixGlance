import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'constants.dart';

class ImageUtils {
  static bool isValidImageFile(String filePath) {
    final extension = _getFileExtension(filePath);
    return AppConstants.supportedExtensions.contains(extension);
  }

  static bool isSvgFile(String filePath) {
    final extension = _getFileExtension(filePath);
    return extension == 'svg';
  }

  static bool isRasterImage(String filePath) {
    final extension = _getFileExtension(filePath);
    return AppConstants.supportedExtensions.contains(extension) && extension != 'svg';
  }

  static String _getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  static String getImageTypeDescription(String filePath) {
    final extension = _getFileExtension(filePath);

    switch (extension) {
      case 'svg':
        return 'Scalable Vector Graphics';
      case 'png':
        return 'Portable Network Graphics';
      case 'jpg':
      case 'jpeg':
        return 'JPEG Image';
      case 'gif':
        return 'Graphics Interchange Format';
      case 'webp':
        return 'WebP Image';
      case 'tiff':
      case 'tif':
        return 'Tagged Image File Format';
      case 'bmp':
        return 'Bitmap Image';
      case 'heic':
        return 'High Efficiency Image Container';
      case 'heif':
        return 'High Efficiency Image Format';
      case 'ico':
        return 'Icon File';
      default:
        return 'Unknown Image Format';
    }
  }

  static Color getImageTypeColor(String filePath) {
    final extension = _getFileExtension(filePath);

    switch (extension) {
      case 'svg':
        return Colors.orange;
      case 'png':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
        return Colors.green;
      case 'gif':
        return Colors.purple;
      case 'webp':
        return Colors.cyan;
      case 'tiff':
      case 'tif':
        return Colors.indigo;
      case 'bmp':
        return Colors.red;
      case 'heic':
      case 'heif':
        return Colors.teal;
      case 'ico':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  static Future<Size?> getImageDimensions(String filePath) async {
    try {
      if (isSvgFile(filePath)) {
        // SVG dimensions are harder to determine without parsing
        // For now, return null to indicate unknown dimensions
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) return null;

      // For raster images, we can get dimensions using dart:ui
      final bytes = await file.readAsBytes();
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      return Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return null;
    }
  }

  static String formatImageSize(Size size) {
    return '${size.width.toInt()} × ${size.height.toInt()}';
  }

  static Future<bool> isValidImageContent(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      if (isSvgFile(filePath)) {
        // Basic SVG validation - check if file contains SVG elements
        final content = await file.readAsString();
        return content.contains('<svg') || content.contains('<?xml');
      } else {
        // For raster images, try to decode a small portion
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return false;

        try {
          final codec = await instantiateImageCodec(Uint8List.fromList(bytes.take(1024).toList()));
          await codec.getNextFrame();
          return true;
        } catch (e) {
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error validating image content: $e');
      return false;
    }
  }

  static Future<Uint8List?> generateThumbnail(String filePath, {int maxWidth = 200}) async {
    try {
      if (isSvgFile(filePath)) {
        // SVG thumbnails require special handling
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final codec = await instantiateImageCodec(
        bytes,
        targetWidth: maxWidth,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ImageByteFormat.png);

      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
}