import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/theme_service.dart';
import 'services/cache_service.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await ThemeService.instance.init();
  await CacheService.instance.init();

  runApp(const SVGViewerApp());
}

class SVGViewerApp extends StatefulWidget {
  const SVGViewerApp({super.key});

  @override
  State<SVGViewerApp> createState() => _SVGViewerAppState();
}

class _SVGViewerAppState extends State<SVGViewerApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_themeChanged);
    _handleIntent();
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_themeChanged);
    super.dispose();
  }

  void _themeChanged() {
    setState(() {});
  }

  void _handleIntent() async {
    // Handle app launch with file intent
    try {
      const platform = MethodChannel('app.channel.shared.data');
      final String? sharedData = await platform.invokeMethod('getSharedData');
      if (sharedData != null) {
        // Handle the shared file path
        debugPrint('Received file: $sharedData');
      }
    } catch (e) {
      debugPrint('Error handling intent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeService.instance.lightTheme,
      darkTheme: ThemeService.instance.darkTheme,
      themeMode: ThemeService.instance.themeMode,
      home: const HomeScreen(),
    );
  }
}