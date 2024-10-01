import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:heic_to_jpg/heic_to_jpg.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _currentFilePath;
  Uint8List? _imageBytes;
  bool _showAppBar = true;
  bool _isFullScreen = false;
  double _rotationAngle = 0.0;
  double _scaleFactor = 1.0;
  List<FileSystemEntity> _imageFiles = [];
  int _currentIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription? _intentDataStreamSubscription;
  // var receiveSharingIntent = ReceiveSharingIntent();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyPress);

    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      // Call the quitApplication function to handle quit logic
      return await quitApplication(context);
    });
    // For handling sharing when app is already running
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedImage(value.first.path);
      }
    }, onError: (err) {
      log("getMediaStream error: $err");
    });

    // For handling sharing when app is not running
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedImage(value.first.path);
      }
    });
  }

  void _handleSharedImage(String filePath) {
    setState(() {
      _currentFilePath = filePath;
      _loadImage(_currentFilePath);
    });
  }

  void setFullScreen(bool isFullScreen) {
    FullScreenWindow.setFullScreen(isFullScreen);

    if (isFullScreen == true) {
      _isFullScreen = true;
    } else {
      _isFullScreen = false;
    }
  }

  Future<bool> quitApplication(BuildContext context) async {
    // Return true if the user confirms the exit, false otherwise
    return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Do you really want to quit?'),
                actions: [
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(true), // Confirm exit
                      child: const Text('Yes')),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(false), // Stay in the app
                      child: const Text('No')),
                ],
              );
            }) ??
        false; // Default to false if dialog is dismissed
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadImage(String? filePath) async {
    if (filePath != null) {
      final extension = path.extension(filePath).toLowerCase();
      try {
        if (extension == '.svg') {
          setState(() {
            _currentFilePath = filePath;
            _imageBytes = null; // Handle SVG separately
          });
        } 
        // Handle ICO images
        else if (extension == '.ico') {
          final bytes = await File(filePath).readAsBytes();
          final decodedImage = img.decodeIco(bytes);
          if (decodedImage != null) {
            setState(() {
              _imageBytes = Uint8List.fromList(img.encodePng(decodedImage));
            });
          } else {
            log('Error decoding ICO image.');
          }
        } else if (extension == '.heic' || extension == '.heif') {
          // Handle HEIF images
          final jpgPath = await HeicToJpg.convert(filePath);
          if (jpgPath != null) {
            final bytes = await File(jpgPath).readAsBytes();
            setState(() {
              _imageBytes = bytes;
            });
          } else {
            log('Error converting HEIF image.');
          }
        } else if (extension == '.dng') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('DNG format is not supported.')),
          );
        } else {
          // Handle other image formats
          final bytes = await File(filePath).readAsBytes();
          setState(() {
            _imageBytes = bytes;
          });
        }
      } catch (e) {
        log('Error loading image: $e');
      }
    }
  }

  void _loadImagesInDirectory(String directoryPath) {
    final dir = Directory(directoryPath);
    final imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'tiff', 'tif', 'bmp', 'svg', 'ico', 'heif', 'heic', 'dng'];

    // Check if the directory exists
    if (!dir.existsSync()) {
      log("Directory does not exist: $directoryPath");
      return;
    }

    setState(() {
      // List only files with valid image extensions
      _imageFiles = dir
          .listSync()
          .where((file) =>
              file is File &&
              imageExtensions.contains(path
                  .extension(file.path)
                  .toLowerCase()
                  .replaceFirst('.', '')))
          .toList();

      // Find and set the index of the currently open file, if applicable
      _currentIndex =
          _imageFiles.indexWhere((file) => file.path == _currentFilePath);

      if (_currentIndex == -1 && _imageFiles.isNotEmpty) {
        // If no file is currently opened, default to the first image in the directory
        _currentFilePath = _imageFiles.first.path;
        _loadImage(_currentFilePath);
      }
    });
  }

  void _openFile(PlatformFile file) {
    setState(() {
      _currentFilePath = file.path; // Store the path of the current file
      _loadImagesInDirectory(File(_currentFilePath!)
          .parent
          .path); // Load all images in the directory
      _loadImage(_currentFilePath); // Load the image
    });
  }

  void _navigateToPreviousImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentFilePath = _imageFiles[_currentIndex].path;
        _loadImage(_currentFilePath);
      });
    }
  }

  void _navigateToNextImage() {
    if (_currentIndex < _imageFiles.length - 1) {
      setState(() {
        _currentIndex++;
        _currentFilePath = _imageFiles[_currentIndex].path;
        _loadImage(_currentFilePath);
      });
    }
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {

      if (event.logicalKey == LogicalKeyboardKey.add && HardwareKeyboard.instance.isControlPressed) {
        setState(() {
          _scaleFactor += 0.1; // Zoom in
        });
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.minus && HardwareKeyboard.instance.isControlPressed) {
        setState(() {
          _scaleFactor =
              _scaleFactor > 0.1 ? _scaleFactor - 0.1 : 0.1; // Zoom out
        });
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
        setFullScreen(true);
        _toggleAppBar();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setFullScreen(false); // Exit full screen with 'esc'
        _toggleAppBar();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _navigateToNextImage();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _navigateToPreviousImage();
        return true;
      }
      if (HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyQ) {
        // Call quitApplication for Ctrl+Q
        bool shouldQuit = quitApplication(context) as bool;
        if (shouldQuit) {
          SystemNavigator.pop(); // Exits the application
        }
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.altLeft &&
          event.logicalKey == LogicalKeyboardKey.f4) {
        // Call quitApplication for Alt+F4
        bool shouldQuit = quitApplication(context) as bool;
        if (shouldQuit) {
          SystemNavigator.pop(); // Exits the application
        }
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyO) {
        _filePicking(); // Open file with Ctrl+O
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
        _navigateToNextImage();
      } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
        _navigateToPreviousImage();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _rotateImage(-90);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _rotateImage(90);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
        _showImageInfo();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f2) {
        _rename(context);
        return true;
      }
    }
    return false;
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  void _rotateImage(double angle) {
    setState(() {
      _rotationAngle += angle;
    });
  }

  void _rename(BuildContext context) {
    TextEditingController controller = TextEditingController();

    void handleRename() async {
      String newName = controller.text.trim();
      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name cannot be empty")),
        );
        return;
      }
      if (_currentFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file is opened')),
        );
        return;
      }

      File currentFile = File(_currentFilePath!);
      String extension = currentFile.path.split('.').last;
      String newPath = '${currentFile.parent.path}/$newName.$extension';

      if (await File(newPath).exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File with this name already exists")),
        );
      } else {
        try {
          await currentFile.rename(newPath);
          log('File renamed to $newName');
          setState(() {
            _currentFilePath = newPath;
          });
          Navigator.of(context).pop();
        } catch (e) {
          log("Error in renaming the file: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error in renaming the file.")),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rename"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'New Name',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  controller.clear();
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: handleRename,
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('System Default'),
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.system;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Dark'),
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.dark;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Light'),
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.light;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageInfo() async {
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      final size = await file.length();
      final fileName = path.basename(_currentFilePath!);
      final fileSize = (size / 1024).toStringAsFixed(2); // Size in KB

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Image Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: $fileName'),
              Text('Size: $fileSize KB'),
              Row(
                children: [
                  Expanded(child: Text('Location: $_currentFilePath')),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      if (_currentFilePath != null) {
                        Clipboard.setData(
                            ClipboardData(text: _currentFilePath!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File path copied to clipboard'),
                            duration: Duration(
                                milliseconds:
                                    750), // Display for less than a second
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No file selected')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  void _filePicking() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'tiff',
        'tif',
        'bmp',
        'svg',
        'ico',
        'heif',
        'heic',
        'dng',
      ],
    );
    if (result != null) {
      final file = result.files.first;
      _openFile(file);
    } else {
      log("User Cancelled the operation");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showSemanticsDebugger: false,
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: _showAppBar
            ? AppBar(
                title: Text(
                  _currentFilePath != null
                      ? path.basename(_currentFilePath!)
                      : 'Image Viewer',
                ),
                leading: PopupMenuButton<String>(
                  onSelected: (String result) {
                    switch (result) {
                      case 'Open':
                        _filePicking();
                        break;
                      case 'Exit':
                        quitApplication(context);
                        break;
                      case 'Theme':
                        _showThemeDialog(
                            context); // This function will display the theme options dialog
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Open',
                      child: Text("Open (Ctrl+O)"),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Exit',
                      child: Text("Exit (Ctrl+Q)"),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Theme',
                      child: Text("Theme"),
                    ),
                  ],
                  icon: const Icon(Icons.menu),
                ),
                actions: <Widget>[
                  Tooltip(
                    message: 'Show Image Info (I)',
                    child: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: _currentFilePath != null
                          ? _showImageInfo // If an image is open, call the function
                          : null, // If no image, make the button unclickable
                      tooltip: _currentFilePath != null
                          ? 'Show Image Info (I)'
                          : 'Please open an image first',
                      color: _currentFilePath != null
                          ? Colors.blue // Enabled button color
                          : Colors.grey, // Disabled button color
                    ),
                  ),
                  // Rename Button
                  Tooltip(
                    message: "Rename (F2)",
                    child: IconButton(
                      icon: const Icon(Icons.drive_file_rename_outline),
                      onPressed: _currentFilePath != null
                          ? () => _rename(context)
                          : null,
                      tooltip: _currentFilePath != null
                          ? "Rename (F2)"
                          : "Please open an image first",
                      color:
                          _currentFilePath != null ? Colors.orange : Colors.grey,
                    ),
                  ),

// Rotate 90° Anti-clockwise Button
                  Tooltip(
                    message: "Rotate 90° anti-clockwise (L)",
                    child: IconButton(
                      icon: const Icon(Icons.rotate_left),
                      onPressed: _currentFilePath != null
                          ? () => _rotateImage(-90)
                          : null,
                      tooltip: _currentFilePath != null
                          ? "Rotate 90° anti-clockwise (L)"
                          : "Please open an image first",
                      color:
                          _currentFilePath != null ? Colors.purple : Colors.grey,
                    ),
                  ),

// Rotate 90° Clockwise Button
                  Tooltip(
                    message: "Rotate 90° clockwise (R)",
                    child: IconButton(
                      icon: const Icon(Icons.rotate_right),
                      onPressed: _currentFilePath != null
                          ? () => _rotateImage(90)
                          : null,
                      tooltip: _currentFilePath != null
                          ? "Rotate 90° clockwise (R)"
                          : "Please open an image first",
                      color:
                          _currentFilePath != null ? Colors.purple : Colors.grey,
                    ),
                  ),

// Full Screen Button
                  Tooltip(
                    message: "Full Screen (F to enter and esc to exit)",
                    child: IconButton(
                      icon: const Icon(Icons.open_in_full),
                      onPressed: _currentFilePath != null
                          ? () {
                              if (!_isFullScreen) {
                                _toggleAppBar();
                                setFullScreen(true);
                              } else {
                                setFullScreen(false);
                              }
                            }
                          : null,
                      tooltip: _currentFilePath != null
                          ? "Full Screen (F to enter and esc to exit)"
                          : "Please open an image first",
                      color:
                          _currentFilePath != null ? Colors.green : Colors.grey,
                    ),
                  ),

// Delete Button
                  Tooltip(
                    message: "Delete",
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _currentFilePath != null
                          ? () async {
                              // Show confirmation dialog before deleting the file
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Delete Image'),
                                    content: const Text(
                                        'Are you sure you want to delete this image?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop(
                                              false); // Cancel the delete operation
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Delete'),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(true); // Confirm delete
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed == true) {
                                try {
                                  // Delete the current image
                                  final file = File(_currentFilePath!);
                                  await file.delete();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Image deleted successfully.')),
                                  );

                                  // Update the image list and load the next image
                                  setState(() {
                                    _imageFiles.removeWhere((file) =>
                                        file.path == _currentFilePath);
                                    if (_imageFiles.isNotEmpty) {
                                      _currentFilePath = _imageFiles.first.path;
                                      _loadImage(_currentFilePath);
                                    } else {
                                      _currentFilePath = null;
                                      _imageBytes = null;
                                    }
                                  });
                                } catch (e) {
                                  log('Error deleting file: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Failed to delete the image.')),
                                  );
                                }
                              }
                            }
                          : null,
                      tooltip: _currentFilePath != null
                          ? "Delete"
                          : "Please open an image first",
                      color:
                          _currentFilePath != null ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              )
            : null,
        body: GestureDetector(
            onTap: _toggleAppBar,
            child: Stack(
              children: [
                // Left arrow for previous image
                Positioned(
                  left: 16,
                  top: MediaQuery.of(context).size.height / 2 - 24,
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex > 0) {
                        _loadImage(_imageFiles[_currentIndex - 1]
                            .path); // Load previous image
                      }
                    },
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 48),
                  ),
                ),
                // Right arrow for next image
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).size.height / 2 - 24,
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex < _imageFiles.length - 1) {
                        _loadImage(_imageFiles[_currentIndex + 1]
                            .path); // Load next image
                      }
                    },
                    child: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 48),
                  ),
                ),
                Center(
                  child: _imageBytes != null
                      ? Transform.rotate(
                          angle: _rotationAngle * 3.14159 / 180,
                          child: PhotoView(
                            imageProvider: MemoryImage(_imageBytes!),
                            enableRotation: true,
                            initialScale:
                                PhotoViewComputedScale.contained * _scaleFactor,
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2.0,
                            basePosition: Alignment.center,
                            backgroundDecoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                          ),
                        )
                      : _currentFilePath != null &&
                              path.extension(_currentFilePath!) == '.svg'
                          ? SvgPicture.file(File(_currentFilePath!))
                          : const Text('No image selected'),
                ),
              ],
            )),
      ),
    );
  }
}
