import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

/* APP ROOT */

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showPlus = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() => _showPlus = true); //  ANY TAP closes stack
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            // 👤 User menu
            leading: // ⋮ More options menu
            PopupMenuButton<String>(
              color: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    debugPrint('Settings tapped');
                    break;
                  case 'help':
                    debugPrint('Help tapped');
                    break;
                  case 'about':
                    debugPrint('About tapped');
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'settings',
                  child: Text(
                    'Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                PopupMenuItem(
                  value: 'help',
                  child: Text('Help', style: TextStyle(color: Colors.white)),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Text('About', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            title: const Text('Fake News Detector'),
            centerTitle: true,
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                icon: const Icon(Icons.person),
                onSelected: (value) {
                  if (value == 'history') {
                    debugPrint('History tapped');
                  } else if (value == 'profile') {
                    debugPrint('Profile tapped');
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'history',
                    child: Text(
                      'History',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'profile',
                    child: Text(
                      'Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),

          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FakeNewsDetector(
                  showPlus: _showPlus,
                  onShowPlusChanged: (value) {
                    setState(() => _showPlus = value);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*  FAKE NEWS DETECTOR  */

class FakeNewsDetector extends StatefulWidget {
  final bool showPlus;
  final ValueChanged<bool> onShowPlusChanged;

  const FakeNewsDetector({
    super.key,
    required this.showPlus,
    required this.onShowPlusChanged,
  });

  @override
  State<FakeNewsDetector> createState() => _FakeNewsDetectorState();
}

class _FakeNewsDetectorState extends State<FakeNewsDetector> {
  final TextEditingController _controller = TextEditingController();

  static const double _textFieldHeight = 50;
  static const double _iconButtonSize = 48;
  String _resultText = "";

  String? _confirmedImagePath; // final accepted preview image

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await showFullScreenPreview(image.path);
    }
  }

  Future<void> showFullScreenPreview(String imagePath) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(child: Image.file(File(imagePath), fit: BoxFit.contain)),

                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: "cancelBtn",
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context, false); // rejected
                        },
                      ),
                      FloatingActionButton(
                        heroTag: "confirmBtn",
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.check, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context, true); // accepted
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      setState(() {
        _confirmedImagePath = imagePath;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).orientation == Orientation.landscape
          ? 160
          : 620,
      child: Stack(
        children: [
          if (_confirmedImagePath != null)
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),

                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_confirmedImagePath!),
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),

                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _confirmedImagePath = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_resultText.isNotEmpty)
            Positioned(
              bottom: _textFieldHeight + 420,
              right: 0,
              left: 70,
              top: 0,
              child: Material(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(
                    maxHeight: 150, // keeps it scrollable
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Text(
                    "Input: $_resultText",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          if (_resultText.isNotEmpty)
            Positioned(
              bottom: _textFieldHeight + 40,
              left: 0,
              top: 170,
              right: 70,
              child: Material(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(
                    maxHeight: 400, // keeps it scrollable
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Text(
                    "Result: $_resultText",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // TEXTFIELD ROW
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                SizedBox(
                  width: _iconButtonSize,
                  height: _iconButtonSize,
                  child: Material(
                    color: Colors.black87,
                    shape: const CircleBorder(),
                    child: PopupMenuButton<String>(
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        maxWidth: 48,
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),

                      offset: const Offset(0, -110),
                      color: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      onSelected: (value) async {
                        if (value == "camera") {
                          final imagePath = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CameraScreen(),
                            ),
                          );

                          if (imagePath != null) {
                            await showFullScreenPreview(imagePath);
                          }
                        } else if (value == "gallery") {
                          debugPrint("Gallery pressed");
                        } else if (value == "close") {
                          widget.onShowPlusChanged(true);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "camera",
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt, color: Colors.white),
                              SizedBox(width: 0),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "gallery",
                          child: Row(
                            children: [
                              Icon(Icons.image, color: Colors.white),
                              SizedBox(width: 0),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "close",
                          child: Row(
                            children: [
                              Icon(Icons.close, color: Colors.white),
                              SizedBox(width: 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: _textFieldHeight,

                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        setState(() {
                          _resultText = value;
                          _controller.clear(); // show result only after Enter
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter the content or title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black87),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black87,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* CAMERA SCREEN  */

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text(
          "Take a photo",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  // ✅ Landscape: center only
                  return Center(child: CameraPreview(_controller));
                }

                // ✅ Portrait: normal preview
                return CameraPreview(_controller);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera),
        onPressed: () async {
          final image = await _controller.takePicture();
          Navigator.pop(context, image.path);
        },
      ),
    );
  }
}
