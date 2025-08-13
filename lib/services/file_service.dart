import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mime/mime.dart';
import '../utils/constants.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  static FileService get instance => _instance;

  FileService._internal();

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version for different permission handling
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ uses granular permissions
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        return photos == PermissionStatus.granted || videos == PermissionStatus.granted;
      } else if (androidInfo.version.sdkInt >= 30) {
        // Android 11-12 uses manage external storage
        final manageStorage = await Permission.manageExternalStorage.request();
        if (manageStorage == PermissionStatus.granted) return true;

        final storage = await Permission.storage.request();
        return storage == PermissionStatus.granted;
      } else {
        // Android 10 and below
        final storage = await Permission.storage.request();
        return storage == PermissionStatus.granted;
      }
    }
    return true;
  }

  Future<String?> pickImageFile() async {
    try {
      // First check and request permissions
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        debugPrint('Storage permission denied');
        return null;
      }

      debugPrint('Attempting to open file picker...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
        allowMultiple: false,
        allowCompression: false,
        withData: false, // We only need the path
        withReadStream: false,
      );

      debugPrint('File picker result: $result');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        debugPrint('Selected file: ${file.path}');

        if (file.path != null && await File(file.path!).exists()) {
          return file.path!;
        } else {
          debugPrint('Selected file does not exist or path is null');
        }
      } else {
        debugPrint('No file selected');
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }

    return null;
  }

  Future<List<String>> pickMultipleImageFiles() async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        debugPrint('Storage permission denied');
        return [];
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }

    return [];
  }

  bool isImageFile(String filePath) {
    final extension = getFileExtension(filePath);
    return AppConstants.supportedExtensions.contains(extension);
  }

  bool isSvgFile(String filePath) {
    final extension = getFileExtension(filePath);
    return extension == 'svg';
  }

  String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return 0;
  }

  Future<DateTime?> getFileModificationDate(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
    } catch (e) {
      debugPrint('Error getting file modification date: $e');
    }
    return null;
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }
}