import 'dart:io';
import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../services/file_service.dart';
import '../widgets/image_viewer.dart';
import '../utils/constants.dart';
import './image_view_screen.dart';

class CachedImagesScreen extends StatefulWidget {
  const CachedImagesScreen({super.key});

  @override
  State<CachedImagesScreen> createState() => _CachedImagesScreenState();
}

class _CachedImagesScreenState extends State<CachedImagesScreen> {
  void _openCachedImage(String imagePath, String imageName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewScreen(
          imagePath: imagePath,
          imageName: imageName,
        ),
      ),
    );
  }

  void _removeCachedImage(String originalPath) async {
    await CacheService.instance.removeFromCache(originalPath);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed from cache'),
        ),
      );
    }
  }

  void _showRemoveDialog(String originalPath, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove from Cache'),
          content: Text('Remove "$fileName" from cache?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeCachedImage(originalPath);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Images'),
        actions: [
          AnimatedBuilder(
            animation: CacheService.instance,
            builder: (context, child) {
              if (CacheService.instance.cacheSize == 0) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: CacheService.instance,
        builder: (context, child) {
          final cachedImages = CacheService.instance.cachedImages;

          if (cachedImages.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Cache info header
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: Row(
                  children: [
                    Icon(
                      Icons.cached,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cachedImages.length} cached images (${CacheService.instance.getCacheSizeString()})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Images grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: cachedImages.length,
                  itemBuilder: (context, index) {
                    final cachedImage = cachedImages[index];
                    return _buildImageTile(cachedImage);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cached,
            size: 120,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No cached images',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Images you open will be cached here for faster loading',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(cachedImage) {
    final isOriginalAvailable = File(cachedImage.originalPath).existsSync();
    final displayPath = isOriginalAvailable ? cachedImage.originalPath : cachedImage.cachePath;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCachedImage(displayPath, cachedImage.fileName),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ImageViewer(
                  imagePath: displayPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Image info
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cachedImage.fileName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          FileService.instance.formatFileSize(cachedImage.fileSize),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'remove') {
                            _showRemoveDialog(cachedImage.originalPath, cachedImage.fileName);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 8),
                                Text('Remove'),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),

                  if (!isOriginalAvailable)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Original file not found',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Cache'),
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
                Navigator.of(context).pop();
                await CacheService.instance.clearCache();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully'),
                    ),
                  );
                }
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}