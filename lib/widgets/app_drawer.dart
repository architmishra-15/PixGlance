import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cache_service.dart';
import '../services/file_service.dart';
import '../utils/constants.dart';
import '../screens/cached_images_screen.dart';
import '../screens/about_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _openImage(BuildContext context) async {
    final imagePath = await FileService.instance.pickImageFile();
    if (imagePath != null && context.mounted) {
      Navigator.of(context).pop(); // Close drawer
      // Navigate to home with the selected image
      // This would typically be handled by the parent widget
    }
  }

  void _navigateToCachedImages(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CachedImagesScreen(),
      ),
    );
  }

  void _navigateToAbout(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _reportProblem() async {
    const url = 'https://pixglance.architmishra.co.in';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: Text(
            'This will remove all cached images (${CacheService.instance.cacheSize} items, ${CacheService.instance.getCacheSizeString()}).\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await CacheService.instance.clearCache();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully'),
                    ),
                  );
                }
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.image,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Open Image'),
            onTap: () => _openImage(context),
          ),

          const Divider(),

          AnimatedBuilder(
            animation: CacheService.instance,
            builder: (context, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.cached),
                title: const Text('Enable Cache'),
                subtitle: Text(
                  CacheService.instance.cacheEnabled
                      ? '${CacheService.instance.cacheSize} items cached (${CacheService.instance.getCacheSizeString()})'
                      : 'Cache disabled',
                ),
                value: CacheService.instance.cacheEnabled,
                onChanged: (bool value) {
                  CacheService.instance.setCacheEnabled(value);
                },
              );
            },
          ),

          AnimatedBuilder(
            animation: CacheService.instance,
            builder: (context, child) {
              return ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Cached Images'),
                subtitle: Text('${CacheService.instance.cacheSize} images'),
                trailing: CacheService.instance.cacheSize > 0
                    ? IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => _showCacheDialog(context),
                  tooltip: 'Clear cache',
                )
                    : null,
                onTap: CacheService.instance.cacheSize > 0
                    ? () => _navigateToCachedImages(context)
                    : null,
                enabled: CacheService.instance.cacheSize > 0,
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () => _navigateToAbout(context),
          ),

          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report Problem'),
            onTap: _reportProblem,
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              'Supported formats: ${AppConstants.supportedExtensions.map((e) => e.toUpperCase()).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}