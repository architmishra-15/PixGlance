import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cached_image.dart';
import '../utils/constants.dart';

class CacheService extends ChangeNotifier {
  static final CacheService _instance = CacheService._internal();
  static CacheService get instance => _instance;

  CacheService._internal();

  late SharedPreferences _prefs;
  late Directory _cacheDir;
  bool _cacheEnabled = true;
  List<CachedImage> _cachedImages = [];

  bool get cacheEnabled => _cacheEnabled;
  List<CachedImage> get cachedImages => List.unmodifiable(_cachedImages);
  int get cacheSize => _cachedImages.length;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheDir = await getApplicationCacheDirectory();

    _cacheEnabled = _prefs.getBool(AppConstants.cacheEnabledKey) ?? true;
    await _loadCacheIndex();
  }

  Future<void> _loadCacheIndex() async {
    final cacheData = _prefs.getString(AppConstants.cacheKey);
    if (cacheData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cacheData);
        _cachedImages = decoded
            .map((item) => CachedImage.fromJson(item))
            .where((image) => File(image.cachePath).existsSync())
            .toList();
      } catch (e) {
        debugPrint('Error loading cache index: $e');
        _cachedImages = [];
      }
    }
  }

  Future<void> _saveCacheIndex() async {
    try {
      final encoded = jsonEncode(_cachedImages.map((e) => e.toJson()).toList());
      await _prefs.setString(AppConstants.cacheKey, encoded);
    } catch (e) {
      debugPrint('Error saving cache index: $e');
    }
  }

  Future<void> setCacheEnabled(bool enabled) async {
    _cacheEnabled = enabled;
    await _prefs.setBool(AppConstants.cacheEnabledKey, enabled);
    notifyListeners();

    if (!enabled) {
      await clearCache();
    }
  }

  Future<CachedImage?> getCachedImage(String filePath) async {
    if (!_cacheEnabled) return null;

    return _cachedImages.firstWhere(
          (image) => image.originalPath == filePath,
      orElse: () => throw StateError('Not found'),
    );
  }

  Future<void> addToCache(String filePath) async {
    if (!_cacheEnabled) return;

    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      // Check if already cached
      final existingIndex = _cachedImages.indexWhere(
            (image) => image.originalPath == filePath,
      );

      if (existingIndex != -1) {
        // Update access time and move to front
        _cachedImages[existingIndex] = _cachedImages[existingIndex].copyWith(
          lastAccessed: DateTime.now(),
        );
        final item = _cachedImages.removeAt(existingIndex);
        _cachedImages.insert(0, item);
      } else {
        // Add new cached image
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
        final cachePath = '${_cacheDir.path}/$fileName';

        await file.copy(cachePath);

        final cachedImage = CachedImage(
          originalPath: filePath,
          cachePath: cachePath,
          fileName: file.uri.pathSegments.last,
          fileSize: await file.length(),
          lastAccessed: DateTime.now(),
        );

        _cachedImages.insert(0, cachedImage);

        // Maintain cache size limit
        if (_cachedImages.length > AppConstants.maxCacheSize) {
          final toRemove = _cachedImages.sublist(AppConstants.maxCacheSize);
          _cachedImages = _cachedImages.sublist(0, AppConstants.maxCacheSize);

          // Delete excess cached files
          for (final image in toRemove) {
            try {
              await File(image.cachePath).delete();
            } catch (e) {
              debugPrint('Error deleting cached file: $e');
            }
          }
        }
      }

      await _saveCacheIndex();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cache: $e');
    }
  }

  Future<void> removeFromCache(String filePath) async {
    final index = _cachedImages.indexWhere(
          (image) => image.originalPath == filePath,
    );

    if (index != -1) {
      final cachedImage = _cachedImages.removeAt(index);
      try {
        await File(cachedImage.cachePath).delete();
      } catch (e) {
        debugPrint('Error deleting cached file: $e');
      }

      await _saveCacheIndex();
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    for (final image in _cachedImages) {
      try {
        await File(image.cachePath).delete();
      } catch (e) {
        debugPrint('Error deleting cached file: $e');
      }
    }

    _cachedImages.clear();
    await _prefs.remove(AppConstants.cacheKey);
    notifyListeners();
  }

  String getCacheSizeString() {
    double totalSize = 0;
    for (final image in _cachedImages) {
      totalSize += image.fileSize;
    }

    if (totalSize < 1024) {
      return '${totalSize.toStringAsFixed(1)} B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}