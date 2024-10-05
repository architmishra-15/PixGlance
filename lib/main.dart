import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

final List<String> supportedImageExtensions = [
  'jpg',
  'jpeg',
  'png',
  'tif',
  'tiff',
  'gif',
  'bmp',
  'heic',
  'heif',
  'webp',
  'svg',
  'ico'
];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  ThemeMode _themeMode = ThemeMode.system;
  String? selectedFilePath;
  bool isFullScreen = false;
  img.Image?
      displayedImage; // Stores the current image with correct orientation
  int rotationAngle = 0; // Initial rotation angle in degrees
  bool isSvg = false;
  double opacityLevel = 1.0; // Controls AppBar and BottomAppBar visibility
  late TransformationController controller;
  late AnimationController animationController;
  Animation<Matrix4>? animation;
  Uint8List? imageBytes; // The current image bytes
  TapDownDetails? tapDownDetails;
  int currentIndex = 0;
  late List<FileSystemEntity> _imageFiles = [];
  final Map<String, img.Image> _imageCache = {};
  bool isCachingEnabled = false;
  List<String> _cachedImages = [];
  bool isImageOpened = false; // To track if an image is opened

  @override
  void initState() {
    super.initState();
    requestStoragePermission(context);
    _loadThemePreference();
    _loadCachePreference();
    controller = TransformationController();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        controller.value = animation!.value;
      });
  }

  @override
  void dispose() {
    controller.dispose();
    animationController.dispose();
    super.dispose();
  }

  // Function to open the image file
  void _openImageFile(String filePath) {
    print("Opening image from: $filePath");
    // Here you can call your selectImage method or directly handle the image
    selectImage(filePath); // Assuming selectImage opens the image
  }

  // Load cache preference
  Future<void> _loadCachePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isCachingEnabled = prefs.getBool('isCachingEnabled') ?? false;
      _cachedImages = prefs.getStringList('cachedImages') ?? [];
    });
  }

  // Save cache preference
  Future<void> _saveCachePreference(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isCachingEnabled', enabled);
  }

  // Cache image function
  Future<void> _cacheImage(String filePath) async {
    if (isCachingEnabled) {
      if (_cachedImages.contains(filePath)) return; // Already cached

      setState(() {
        _cachedImages.add(filePath);
        if (_cachedImages.length > 15) {
          _cachedImages.removeAt(0); // Maintain last 15 images
        }
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList('cachedImages', _cachedImages);
    }
  }

  Future<void> _openFeedback() async {
    final url = Uri.parse("https://pixglance.github.io/pixglance/");

    if (!await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error Opening!!"),
              content: const Text("Feedback form cannot be opened!\n\nPlease contact the creator of the app"),
              backgroundColor: Theme.of(context)
                  .dialogBackgroundColor, // Match theme background
            );
          });
    }
  }

  img.Image? _decodeImage(String filePath) {
    final bytes = File(filePath)
        .readAsBytesSync(); // Sync since it's in a separate isolate
    final img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
    if (image != null) {
      final img.Image fixedImage = img.bakeOrientation(image);
      return fixedImage;
    }
    return null;
  }

  img.Image resizeImage(img.Image image, double maxWidth, double maxHeight) {
    int width = image.width;
    int height = image.height;

    if (width > maxWidth || height > maxHeight) {
      final scale = min(maxWidth / width, maxHeight / height);
      width = (width * scale).toInt();
      height = (height * scale).toInt();
    }

    return img.copyResize(image, width: width, height: height);
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('theme');

    setState(() {
      if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (theme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode
            .system; // Default to system theme if no preference is found
      }
    });
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme',
      mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system', // Save system theme as 'system'
    );
  }

  Future<void> requestStoragePermission(BuildContext context) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (!result.isGranted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Permission needed'),
            content: const Text(
                'This app needs storage permission to function properly. Please grant the permission.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void loadImagesFromDirectory(String filePath) {
    // Get the directory where the image is located
    Directory imageDir = File(filePath).parent;

    // List all image files in the directory
    List<FileSystemEntity> files = imageDir.listSync().where((file) {
      // Check for common image extensions including SVGs
      return supportedImageExtensions
          .contains(file.path.split('.').last.toLowerCase());
    }).toList();

    // Update image paths list
    setState(() {
      _imageFiles = files;
      currentIndex = _imageFiles.indexOf(filePath as FileSystemEntity);
    });
  }

  void showNextImage() {
    if (currentIndex < _imageFiles.length - 1) {
      setState(() {
        currentIndex++; // Move to next image
        selectedFilePath = _imageFiles[currentIndex].path;
      });
    } else {
      const AlertDialog(
        content: Text("No more image!"),
      );
    }
  }

  void showPreviousImage() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--; // Move to previous image
        selectedFilePath = _imageFiles[currentIndex].path;
      });
    } else {
      const AlertDialog(
        content: Text("No previous image"),
      );
    }
  }

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
      opacityLevel = isFullScreen ? 0.0 : 1.0;
    });
  }

  // Function to rotate the image by 90 degrees
  void rotateImage() {
    setState(() {
      rotationAngle = (rotationAngle + 90) % 360; // Rotate by 90 degrees
    });
  }

  Future<img.Image?> openImage(String filePath) async {
    if (_imageCache.containsKey(filePath)) {
      return _imageCache[filePath];
    }
    final img.Image? image = await compute(_decodeImage, filePath);
    if (image != null) {
      final img.Image resizedImage = resizeImage(
          image,
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height);
      _imageCache[filePath] = resizedImage;
      return resizedImage;
    }
    setState(() {
      selectedFilePath = filePath;
      isImageOpened = true; // Set to true when an image is opened
    });
    return null;
  }

  void closeImage() {
    setState(() {
      selectedFilePath = null;
      isImageOpened = false; // Set to false when no image is opened
    });
  }

  Future<void> selectImage([String? filePath]) async {
    try {
      if (filePath == null) {
        final result = await FilePicker.platform.pickFiles(
          allowedExtensions: [
            'jpg',
            'jpeg',
            'png',
            'tif',
            'tiff',
            'gif',
            'bmp',
            'heic',
            'heif',
            'webp',
            'svg',
            'ico'
          ],
          type: FileType.custom,
          allowMultiple: false,
        );

        if (result != null) {
          filePath = result.files.single.path!;
        } else {
          return; // No file selected
        }
      }

      String extension = filePath.split('.').last.toLowerCase();
      setState(() {
        selectedFilePath = filePath;
        _imageFiles.clear(); // Clear previous images
        // loadImagesFromDirectory(filePath);
      });

      if (extension == 'svg') {
        setState(() {
          isSvg = true;
          selectedFilePath = filePath;
        });
      } else {
        img.Image? fixedImage = await openImage(filePath);
        setState(() {
          displayedImage = fixedImage;
          isSvg = false;
          selectedFilePath = filePath;
        });
      }
      Navigator.pop(context);
      loadImagesFromDirectory(filePath);
    } catch (e) {
      const Text("Image could not be loaded");
    }
  }

  // Widget to display an image (SVG or Raster)
  Widget viewImage() {
    return GestureDetector(
        onDoubleTap: onDoubleTap, // Attach double-tap handler
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(0),
          transformationController: controller,
          panEnabled: true, // Enable panning
          scaleEnabled: true,
          // boundaryMargin: EdgeInsets.zero, // Remove boundaries
          minScale: 1.0,
          maxScale: 50.0, // Set maximum zoom scale
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: selectedFilePath!.endsWith('.svg')
                ? SvgPicture.file(File(selectedFilePath!))
                : Image.file(
                    File(selectedFilePath!),
                    fit: BoxFit.scaleDown,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text("Error loading image");
                    },
                  ),
          ),
        ));
  }

  void onDoubleTap() {
    double currentScale = controller.value.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      controller.value = Matrix4.identity();
    } else {
      final position = tapDownDetails!.localPosition;
      const double scale = 3;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      final zoomed = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);

      final end = controller.value.isIdentity() ? zoomed : Matrix4.identity();

      animation = Matrix4Tween(
        begin: controller.value,
        end: end,
      ).animate(CurveTween(curve: Curves.easeOut).animate(animationController));
      animationController.forward(from: 0);
    }
  }

  PreferredSizeWidget buildAppBar() {
      return AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: const Text("Pix Glance"),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      );
  }

  // Normal Bottom AppBar with image editing options
  Widget buildBottomBar() {
    double backOpacity;
    Color widColor;

    if (_themeMode == ThemeMode.dark) {
       backOpacity = 0.5;
    } else {
      backOpacity = 0.8;
    }

    if (backOpacity == 0.5) {
      widColor = Colors.white;
    } else{
      widColor = Colors.white70;
    }

    return BottomAppBar(
      color: Colors.black.withOpacity(backOpacity),
      height: 65,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.rotate_left),
              color: widColor,
              onPressed: rotateImage,
            ),
            IconButton(
              color: widColor,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.info),
              onPressed: showImageInfo,
            ),
            IconButton(
              color: widColor,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit),
              onPressed: renameImage,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.delete),
              onPressed: deleteImage,
                color: widColor,
            ),
          ],
        ),
    );
  }

  Future<void> accessStorage() async {
    if (await Permission.storage.isGranted) {
      selectImage();
    } else {
      await requestStoragePermission(context);
    }
  }

  void selectTheme(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  title: const Text('Light Theme'),
                  onTap: () {
                    setState(() {
                      _themeMode = ThemeMode.light;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Dark Theme'),
                  onTap: () {
                    setState(() {
                      _themeMode = ThemeMode.dark;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('System Default'),
                  onTap: () {
                    setState(() {
                      _themeMode = ThemeMode.system;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Delete image logic
  void deleteImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_imageFiles.isNotEmpty) {
                  File currentImageFile = _imageFiles[currentIndex] as File;

                  if (currentImageFile.existsSync()) {
                    currentImageFile.deleteSync();

                    setState(() {
                      _imageFiles.removeAt(currentIndex); // Remove from list

                      // Handle cases where no images remain
                      if (_imageFiles.isEmpty) {
                        selectedFilePath = null;
                      } else {
                        // Move to the next image, or adjust for boundaries
                        if (currentIndex >= _imageFiles.length) {
                          currentIndex = _imageFiles.length - 1;
                        }
                        selectedFilePath = _imageFiles[currentIndex].path;
                      }
                    });
                  }
                }

                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Show image info logic
  void showImageInfo() {
    if (selectedFilePath != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Image Information'),
            content: Text('File Path: $selectedFilePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Rename image logic
  void renameImage() async {
    if (selectedFilePath != null) {
      TextEditingController controller = TextEditingController();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Rename'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "New Name"),
            ),
            actions: [
              TextButton(
                child: const Text('Rename'),
                onPressed: () {
                  String newPath = selectedFilePath!.replaceFirst(
                    RegExp(r'[^/]+$'),
                    controller.text,
                  );
                  File(selectedFilePath!).renameSync(newPath);
                  setState(() {
                    selectedFilePath = newPath;
                  });
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Open Image'),
                onTap: selectImage,
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Select Theme'),
                onTap: () {
                  selectTheme(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cached),
                title: const Text('Enable Caching'),
                trailing: CacheToggleSwitch(
                  // Use your custom caching widget here
                  isCachingEnabled: isCachingEnabled,
                  onToggle: (value) async {
                    setState(() {
                      isCachingEnabled = value;
                    });

                    await _saveCachePreference(isCachingEnabled);
                    if (isCachingEnabled) {
                      _cachedImages;
                    } else {
                      // Handle disabling caching if necessary
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text("Feedback"),
                onTap: () async {
                  try {
                    await _openFeedback();
                  } catch (error) {
                    if (kDebugMode) {
                      print("Cannot open");
                    }
                  }
                },
              )
            ],
          ),
        ),
        body: Stack(
          children: [
            Center(
              child: selectedFilePath != null
                  ? GestureDetector(
                      onDoubleTapDown: (details) => tapDownDetails = details,
                      onHorizontalDragUpdate: (details) {
                        // Update the current index based on the swipe direction
                        if (details.delta.dx > 5) {
                          // Swipe Right

                          if (kDebugMode) {
                            print("previous img");
                          }
                          showPreviousImage();
                          if (kDebugMode) {
                            print(_imageFiles);
                          }
                          if (kDebugMode) {
                            print(selectedFilePath);
                          }

                          if (currentIndex > 0) {
                            selectedFilePath = _imageFiles[currentIndex].path;
                          }
                        } else if (details.delta.dx < -5) {
                          // Swipe Left
                          if (kDebugMode) {
                            print("Next image");
                          }
                          showNextImage();
                          if (kDebugMode) {
                            print(_imageFiles);
                          }
                          if (kDebugMode) {
                            print(selectedFilePath);
                          }

                          if (currentIndex < _imageFiles.length - 1) {
                            if (kDebugMode) {
                              print("Swipe left");
                            }
                            setState(() {
                              currentIndex++;
                              selectedFilePath = _imageFiles[currentIndex].path;
                            });
                          }
                        }
                      },
                      onTap: toggleFullScreen,
                      child: RotatedBox(
                        quarterTurns: rotationAngle ~/ 90,
                        child: isSvg
                            ? SvgPicture.file(File(selectedFilePath!))
                            : viewImage(), // Dynamically show the correct widget
                      ),
                    )
                  : const Text('No image selected'),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacityLevel,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildAppBar(), // Conditionally show app bar
                  isImageOpened ? Container() : buildBottomBar(), // Conditionally show bottom bar
                ],
              ),
            ),
            Positioned(
              bottom: 90,
              right: 25.0,
              child: Opacity(
                  opacity: opacityLevel,
                  child: FloatingActionButton(
                    onPressed: selectImage,
                    backgroundColor: Colors.purple,
                    tooltip: "Open Image",
                    child: const Icon(Icons.add),
                  )),
            )
          ],
        ),
      ),
    );
  }
}

class CacheToggleSwitch extends StatelessWidget {
  final bool isCachingEnabled;
  final ValueChanged<bool> onToggle;

  const CacheToggleSwitch(
      {required this.isCachingEnabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedToggleSwitch<bool>.dual(
      current: isCachingEnabled,
      first: false,
      second: true,
      onChanged: onToggle,
      styleBuilder: (value) => ToggleStyle(
        borderRadius: BorderRadius.circular(99),
        indicatorColor: value
            ? Colors.green
            : Colors.red, // Set the indicator color based on the state
      ),
      indicatorSize:
          const Size(42.0, 35.0), // Size of the indicator //make this 25, 25
      iconBuilder: (value) => value
          ? const Icon(Icons.check, color: Colors.white) // Icon for 'on'
          : const Icon(Icons.close, color: Colors.white), // Icon for 'off'

      height: 40, //make this 30
      fittingMode: FittingMode.preventHorizontalOverlapping,
    );
  }
}
