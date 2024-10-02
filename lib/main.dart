import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin{
  ThemeMode _themeMode = ThemeMode.system;
  String? selectedFilePath;
  bool isFullScreen = false;
  img.Image?
      displayedImage; // Stores the current image with correct orientation
  int rotationAngle = 0; // Initial rotation angle in degrees
  bool isSvg = false;
  bool hideBarsOnZoom = false; // Track hiding bars during zoom
  double opacityLevel = 1.0; // Controls AppBar and BottomAppBar visibility
  bool inCropMode = false; // Track whether user is in crop mode
  late TransformationController controller;
  TapDownDetails? tapDownDetails;
  late AnimationController animationController;
  Animation<Matrix4>? animation;
  File? _imageFile;  // The current image file
  Uint8List? imageBytes; // The current image bytes

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    _loadThemePreference();
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

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('theme');
    setState(() {
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> requestStoragePermission() async {
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

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
      opacityLevel = isFullScreen ? 0.0 : 1.0;
    });
  }

  // Future<img.Image?> fixImageOrientation(String filePath) async {
  //   final bytes = await File(filePath).readAsBytes();
  //   final img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
  //
  //   if (image != null) {
  //     // Correct the orientation using EXIF data
  //     final img.Image fixedImage = img.bakeOrientation(image);
  //     return fixedImage;
  //   }
  //   return null;
  // }

  // Function to rotate the image by 90 degrees
  void rotateImage() {
    setState(() {
      rotationAngle = (rotationAngle + 90) % 360; // Rotate by 90 degrees
    });
  }

  // Function to view SVG files using flutter_svg
  // Function to open and fix orientation of raster images
  // Image selection logic
  Future<img.Image?> openImage(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final img.Image? image = img.decodeImage(Uint8List.fromList(bytes));

    if (image != null) {
      final img.Image fixedImage = img.bakeOrientation(image);
      return fixedImage;
    }
    return null;
  }

  Future<void> selectImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        String extension = filePath.split('.').last.toLowerCase();

        if (extension == 'svg') {
          setState(() {
            selectedFilePath = filePath;
            isSvg = true;
          });
        } else {
          img.Image? fixedImage = await openImage(filePath);
          setState(() {
            selectedFilePath = filePath;
            displayedImage = fixedImage;
            isSvg = false;
          });
        }
      }
    } catch (e) {
      print('Error selecting image: $e');
    }
  }

  // Widget to display an image (SVG or Raster)
  Widget viewImage() {
    return InteractiveViewer(
        panEnabled: false,
        scaleEnabled: false,
        minScale: 1.0,
        maxScale: 4.0, // Set maximum zoom scale
        child: Image.file(
          File(selectedFilePath!), // Make sure you pass the correct file here
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text("Error loading image");
          },
        ));
  }

  // custom AppBar
  // AppBar for normal view
  PreferredSizeWidget buildAppBar() {
    if (inCropMode) {
      return buildCropAppBar();
    }

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
      actions: [
        IconButton(
          icon: const Icon(Icons.crop),
          onPressed: () {
            setState(() {
              inCropMode = true;
            });
          },
        ),
      ],
    );
  }

  // Function to crop the image
  void cropImage() async {
    if (_imageFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: _imageFile!.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
          )
    ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
          inCropMode = false;  // Exit crop mode after cropping
        });
      }
    }
  }

  // Function to save the current image
  Future<void> saveImage() async {
    if (_imageFile != null) {
      // Logic to overwrite the current file
      final newPath = _imageFile!.path;
      // You can add logic here to write the image bytes to the file
      // Currently, it overwrites the image
      print("Image saved at: $newPath");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved successfully!')),
      );
    }
  }

  // Function to save the image as a copy
  Future<void> saveImageAsCopy() async {
    if (_imageFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/copy_${DateTime.now().millisecondsSinceEpoch}.png';
      File newImage = await _imageFile!.copy(newPath);
      print("Image saved as a copy at: ${newImage.path}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved as a copy!')),
      );
    }
  }

  // AppBar for crop mode
  PreferredSizeWidget buildCropAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.5),
      title: const Text("Crop Image"),
      leading: IconButton(
        icon: const Icon(Icons.cancel),
        onPressed: () {
          setState(() {
            inCropMode = false;
          });
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: saveImage,
        ),
        IconButton(
          icon: const Icon(Icons.save_alt),
          onPressed: saveImageAsCopy,
        ),
      ],
    );
  }

  // Normal Bottom AppBar with image editing options
  Widget buildBottomBar() {
    if (inCropMode) {
      return buildCropBottomBar();
    }

    return BottomAppBar(
      color: Colors.black.withOpacity(0.5),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_left),
              onPressed: rotateImage,
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: showImageInfo,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: renameImage,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteImage,
            ),
          ],
        ),
      ),
    );
  }

  // Crop Bottom AppBar with crop and rotate options
  Widget buildCropBottomBar() {
    return BottomAppBar(
      color: Colors.black.withOpacity(0.5),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.crop),
              onPressed: cropImage,
            ),
            IconButton(
              icon: const Icon(Icons.rotate_left),
              onPressed: () {
                // Rotate left during crop mode
              },
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right),
              onPressed: () {
                // Rotate right during crop mode
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> accessStorage() async {
    if (await Permission.storage.isGranted) {
      selectImage();
    } else {
      await requestStoragePermission();
    }
  }

  void selectTheme(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('System'),
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.system;
                  });
                  _saveThemePreference(_themeMode);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Dark'),
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.dark;
                  });
                  _saveThemePreference(_themeMode);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Light'),
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.light;
                  });
                  _saveThemePreference(_themeMode);
                  Navigator.pop(context);
                },
              ),
            ],
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
              onPressed: () {
                File(selectedFilePath!).deleteSync();
                setState(() {
                  selectedFilePath = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Rename image logic
  void renameImage() async {
    if (selectedFilePath != null) {
      TextEditingController controller = TextEditingController();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Rename Image'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Enter new name"),
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
            ],
          );
        },
      );
    }
  }

  // Info logic
  void showImageInfo() {
    if (selectedFilePath != null) {
      final file = File(selectedFilePath!);
      final fileSize = file.lengthSync();
      final lastModified = file.lastModifiedSync();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Image Info'),
            content: Text(
              'File: $selectedFilePath\n'
              '\nSize: ${fileSize / 1024} KB\n'
              '\nLast Modified: $lastModified',
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness:
              _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: isFullScreen
            ? null
            : buildAppBar(), // No need for AnimatedOpacity here,
        drawer: isFullScreen
            ? null
            : Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: Text('Choose your action'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo),
                      title: const Text('Select Image'),
                      onTap: () {
                        selectImage();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.brightness_4),
                      title: const Text('Select Theme'),
                      onTap: () {
                        selectTheme(context);
                      },
                    ),
                  ],
                ),
              ),
        body: GestureDetector(
          onDoubleTapDown: (details) => tapDownDetails = details,
          onTap: toggleFullScreen,
          onDoubleTap: () {

            final position = tapDownDetails!.localPosition;
            const double scale = 3;
            final x = -position.dx * (scale-1);
            final y = -position.dy * (scale-1);
            final zoomed = Matrix4.identity()
              ..translate(x, y)
              ..scale(scale);

            final end = controller.value.isIdentity() ? zoomed : Matrix4.identity();

            animation = Matrix4Tween(
              begin: controller.value,
              end: end,
            ).animate(CurveTween(curve: Curves.easeOut).animate(animationController)
            );
            animationController.forward(from:0);
          },
          child: Center(
            child: selectedFilePath != null
                ? viewImage()
                : const Text("No image selected"),
          ),
        ),
        bottomNavigationBar: isFullScreen
            ? null
            : AnimatedOpacity(
                opacity: opacityLevel,
                duration: const Duration(
                    milliseconds: 50), // Reduced duration for smooth effect
                child: buildBottomBar(),
              ),
        floatingActionButton: isFullScreen
            ? null
            : FloatingActionButton(
                onPressed: selectImage,
                child: const Icon(Icons.add_circle_sharp),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
