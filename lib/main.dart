import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String? selectedFilePath;
  bool isFullScreen = false;
  double rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    _loadThemePreference();
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
    });
    if (isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Widget viewImage(String filePath) {
    final fileExtension = filePath.split('.').last.toLowerCase();
    if (fileExtension == 'svg') {
      return GestureDetector(
        onTap: toggleFullScreen,
        child: SvgPicture.file(
          File(filePath),
          fit: BoxFit.contain,
        ),
      );
    }
    return GestureDetector(
      onTap: toggleFullScreen,
      child: Transform.rotate(
        angle: rotationAngle,
        child: PhotoView(
          imageProvider: FileImage(File(filePath)),
          enableRotation: true,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
        ),
      ),
    );
  }

  Future<void> selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
      });
    }
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

  // Rotate image logic
  void rotateImage() {
    setState(() {
      rotationAngle += 0.5; // Rotating by 45 degrees (pi/4 radians)
    });
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
  void renameImage() {
    TextEditingController renameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Image'),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(
              labelText: 'New Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String newName = renameController.text;
                if (newName.isNotEmpty) {
                  File oldFile = File(selectedFilePath!);
                  String newPath = '${oldFile.parent.path}/$newName${oldFile.path.split('.').last}';
                  oldFile.renameSync(newPath);
                  setState(() {
                    selectedFilePath = newPath;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
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

  // Info logic
  void showImageInfo() {
    if (selectedFilePath != null) {
      File file = File(selectedFilePath!);
      int fileSize = file.lengthSync();
      String fileName = file.path.split('/').last;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Image Info'),
            content: Text('File Name: $fileName\nFile Size: $fileSize bytes'),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: isFullScreen
            ? null
            : AppBar(
          title: const Text("Image Viewer"),
          leading: Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          }),
        ),
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
                child: Text('Sample Application'),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Select Image'),
                onTap: () {
                  accessStorage();
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
        body: Center(
          child: selectedFilePath != null
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: viewImage(selectedFilePath!)),
              if (!isFullScreen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.rotate_left),
                      onPressed: rotateImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
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
            ],
          )
              : const Text('No image selected'),
        ),
      ),
    );
  }
}
