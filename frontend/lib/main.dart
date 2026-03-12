import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _showRegister = false;
  bool _isLoggedIn = false;
  bool _showPlus = true;

  void _login() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  void _showLoginPage() {
    setState(() {
      _showRegister = false;
    });
  }

  void _showRegisterPage() {
    setState(() {
      _showRegister = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isLoggedIn
          ? _buildHome()
          : _showRegister
          ? RegisterPage(onRegister: _showLoginPage)
          : LoginPage(onLogin: _login, onShowRegister: _showRegisterPage),
    );
  }

  Widget _buildHome() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() => _showPlus = true);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: PopupMenuButton<String>(
            color: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings', style: TextStyle(color: Colors.white)),
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

          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.person),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
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
    );
  }
}

class RegisterPage extends StatefulWidget {
  final VoidCallback onRegister;

  const RegisterPage({super.key, required this.onRegister});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _submit() async {
    widget.onRegister();
    if (_formKey.currentState!.validate()) {
      await http.post(
        Uri.parse("http://192.168.0.104:8000/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black87),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 40, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "Fake News Detector",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _nameController,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Name",
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter name";
                      }

                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter email";
                      }
                      if (value.length < 16 || value.length > 64) {
                        return "Range must be between 6 and 64";
                      }

                      if (!value.endsWith("@gmail.com")) {
                        return "Email must end with @gmail.com";
                      }

                      return null;
                    },
                  ),

                  TextFormField(
                    controller: _passwordController,
                    cursorColor: Colors.white,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter password";
                      }
                      if (value.length < 8) {
                        return "Minimum 8 characters";
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return "At least 1 uppercase letter required";
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return "At least 1 lowercase letter required";
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return "At least 1 number required";
                      }
                      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return "Must contain at least 1 special character";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _confirmPasswordController,
                    cursorColor: Colors.white,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: " Confirm Password",
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Confirm your password";
                      }
                      if (value != _passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      _submit();
                    },
                    child: const Text("Register"),
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

/* LOGIN PAGE */

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onShowRegister;

  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onShowRegister,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse("http://192.168.0.104:8000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        widget.onLogin(); // go to home page
      } else {
        print("Invalid login");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black87),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 40, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "Fake News Detector",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 50),

                  TextFormField(
                    controller: _emailController,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter email";
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    cursorColor: Colors.white,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter password";
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onShowRegister,
                      child: const Text(
                        "New User ? Register here",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
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
                      cursorColor: Colors.black,
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
