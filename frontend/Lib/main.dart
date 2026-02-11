import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
            title: const Text('Fake News Detector'),
            centerTitle: true,
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  const Spacer(),
                  FakeNewsDetector(
                    showPlus: _showPlus,
                    onShowPlusChanged: (value) {
                      setState(() => _showPlus = value);
                    },
                  ),
                ],
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

  String? _capturedImagePath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        children: [
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
                  child: widget.showPlus
                      ? Material(
                          color: Colors.black87,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              widget.onShowPlusChanged(false);
                            },
                          ),
                        )
                      : const SizedBox(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: _textFieldHeight,

                    child: TextField(
                      controller: _controller,
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

          // ICON STACK
          if (!widget.showPlus)
            Positioned(
              bottom: (_textFieldHeight / 2) - (_iconButtonSize / 2),
              left: 0,
              child: AbsorbPointer(
                absorbing: false, //  allow taps here
                child: Material(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(40),
                  elevation: 4,
                  child: SizedBox(
                    width: 50,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              final imagePath = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CameraScreen(),
                                ),
                              );

                              if (imagePath != null) {
                                setState(() {
                                  _capturedImagePath = imagePath;
                                });
                                widget.onShowPlusChanged(true);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              widget.onShowPlusChanged(true);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // CAPTURED IMAGE PREVIEW
          // IMAGE PREVIEW WITH CONFIRM / CANCEL
          if (_capturedImagePath != null)
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
                      // IMAGE PREVIEW
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_capturedImagePath!),
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ACTION BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // CANCEL
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _capturedImagePath = null; // discard image
                              });
                            },
                          ),

                          // CONFIRM
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              // ✅ image accepted
                              // NEXT: send to fake news detector / OCR
                              debugPrint(
                                'Image confirmed: $_capturedImagePath',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
      appBar: AppBar(title: const Text('Take a photo')),
      body: FutureBuilder(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
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
