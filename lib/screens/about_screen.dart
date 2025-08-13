import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _launchUrl(String url) async {

    final mailUri = Uri(
        scheme: 'mailto',
        path: 'architmishra015@gmail.com',
        queryParameters: {'subject': 'SVG Viewer - Bug Report'}
    );
    await launchUrl(mailUri, mode: LaunchMode.externalApplication);
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    try {
      // if (await canLaunchUrl(uri)) {
      //   await launchUrl(uri, mode: LaunchMode.externalApplication);
      // } else {
      //   debugPrint('Could not launch $url');
      // }
      if (!launched) {
        // meaningful error for debugging
        debugPrint('Could not launch $uri');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // App icon and name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.image,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              AppConstants.appDescription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Features card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureItem(
                      context,
                      Icons.image,
                      'Multi-format Support',
                      'View SVG, PNG, JPG, GIF, WebP, TIFF, BMP, HEIC, and ICO files',
                    ),

                    _buildFeatureItem(
                      context,
                      Icons.cached,
                      'Smart Caching',
                      'Cache up to 100 images for faster loading',
                    ),

                    _buildFeatureItem(
                      context,
                      Icons.zoom_in,
                      'Zoom & Pan',
                      'Pinch to zoom and pan around images',
                    ),

                    _buildFeatureItem(
                      context,
                      Icons.dark_mode,
                      'Dark/Light Theme',
                      'Switch between themes or use system preference',
                    ),

                    _buildFeatureItem(
                      context,
                      Icons.open_with,
                      'File Association',
                      'Open images directly from file manager',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Supported formats card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supported Formats',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.supportedExtensions.map((ext) {
                        return Chip(
                          label: Text(ext.toUpperCase()),
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Contact section
            Text(
              'Contact & Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactButton(
                  context,
                  Icons.email,
                  'Email',
                      () => _launchUrl('mailto:architmishra015@gmail.com'),
                ),

                _buildContactButton(
                  context,
                  Icons.code,
                  'GitHub',
                      () => _launchUrl('https://github.com/architmishra-15'),
                ),

                _buildContactButton(
                  context,
                  Icons.bug_report,
                  'Report Bug',
                      () => _launchUrl('pixglance.architmishra.co.in'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Copyright
            Text(
              '© 205 PixGlance. All rights reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'Made with ❤️ using Flutter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context,
      IconData icon,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onPressed,
      ) {
    return Column(
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}