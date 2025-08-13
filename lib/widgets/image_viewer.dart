import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/file_service.dart';

class ImageViewer extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ImageViewer({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (FileService.instance.isSvgFile(imagePath)) {
      return _buildSvgImage();
    } else {
      return _buildRasterImage();
    }
  }

  Widget _buildSvgImage() {
    return SvgPicture.file(
      File(imagePath),
      fit: fit,
      width: width,
      height: height,
      placeholderBuilder: (context) => _buildPlaceholder(),
    );
  }

  Widget _buildRasterImage() {
    return Image.file(
      File(imagePath),
      fit: fit,
      width: width,
      height: height,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.withOpacity(0.7),
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading image',
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}