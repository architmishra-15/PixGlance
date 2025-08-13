import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import '../widgets/image_viewer.dart';
import '../widgets/theme_toggle_button.dart';
import '../services/file_service.dart';
import '../utils/constants.dart';

class ImageViewScreen extends StatefulWidget {
  final String imagePath;
  final String imageName;

  const ImageViewScreen({
    super.key,
    required this.imagePath,
    required this.imageName,
  });

  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  bool _showAppBar = true;
  PhotoViewController? _photoViewController;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _photoViewController?.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  void _showImageInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildImageInfoSheet(),
    );
  }

  Widget _buildImageInfoSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Image Information',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildInfoTile('Name', widget.imageName),
                    _buildInfoTile('Path', widget.imagePath),
                    _buildInfoTile('Format', FileService.instance.getFileExtension(widget.imagePath).toUpperCase()),
                    _buildInfoTile('Type', FileService.instance.isSvgFile(widget.imagePath) ? 'Vector (SVG)' : 'Raster Image'),

                    FutureBuilder<int>(
                      future: FileService.instance.getFileSize(widget.imagePath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return _buildInfoTile('Size', FileService.instance.formatFileSize(snapshot.data!));
                        }
                        return _buildInfoTile('Size', 'Loading...');
                      },
                    ),

                    FutureBuilder<DateTime?>(
                      future: FileService.instance.getFileModificationDate(widget.imagePath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final date = snapshot.data!;
                          final formatted = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                          return _buildInfoTile('Modified', formatted);
                        }
                        return _buildInfoTile('Modified', 'Unknown');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(
          widget.imageName,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showImageInfo,
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: () {
              // Toggle theme but keep the icon white for visibility
            },
          ),
          const SizedBox(width: 8),
        ],
      )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: Container(
          color: Colors.black,
          child: FileService.instance.isSvgFile(widget.imagePath)
              ? PhotoView.customChild(
            controller: _photoViewController,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
            child: Hero(
              tag: 'image_${widget.imagePath.hashCode}',
              child: ImageViewer(
                imagePath: widget.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          )
              : PhotoView(
            controller: _photoViewController,
            imageProvider: FileImage(
              File(widget.imagePath),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'image_${widget.imagePath.hashCode}',
            ),
          ),
        ),
      ),
    );
  }
}