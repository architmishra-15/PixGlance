class AppConstants {
  static const String appName = "PixGlance";
  static const String appVersion = "2.0.0";
  static const String appDescription = "SVG Viewer for Andriod Phones";

  // Cache constants
  static const int maxCacheSize = 100;
  static const String cacheKey = 'image_cache';
  static const String themeKey = 'theme_mode';
  static const String cacheEnabledKey = 'cache_enabled';

  // Supported Image Types
  static const List<String> supportedExtensions = [
    'svg',
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'tiff',
    'tif',
    'bmp',
    'heic',
    'heif',
    'ico',
  ];

  // MIME Type
  static const Map<String, String> mimeType = {
    'svg': 'image/svg+xml',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'tiff': 'image/tiff',
    'tif': 'image/tiff',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'ico': 'image/x-icon',
  };

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double appBarHeight = 56.0;
  static const double fabSize = 56.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}