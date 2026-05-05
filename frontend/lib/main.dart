import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const String _baseUrl =
    'https://quizzes-beside-distribute-viruses.trycloudflare.com';

// ---------------------------------------------------------------------------
// Shared-preference helpers
// ---------------------------------------------------------------------------

Future<void> saveLogin() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
}

Future<bool> checkLogin() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    cameras = [];
  }
  runApp(const MyApp());
}

// ---------------------------------------------------------------------------
// APP ROOT
// ---------------------------------------------------------------------------

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showRegister = false;
  bool _isLoggedIn = false;

  void _login() => setState(() => _isLoggedIn = true);
  void _logout() => setState(() => _isLoggedIn = false);
  void _showLoginPage() => setState(() => _showRegister = false);
  void _showRegisterPage() => setState(() => _showRegister = true);

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          color: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => const [
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
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 60),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FakeNewsDetector(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REGISTER PAGE
// ---------------------------------------------------------------------------

class RegisterPage extends StatefulWidget {
  final VoidCallback onRegister;

  const RegisterPage({super.key, required this.onRegister});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create_user/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onRegister();
      } else {
        setState(
          () => _errorMessage = 'Registration failed. Please try again.',
        );
      }
    } catch (_) {
      setState(() => _errorMessage = 'Network error. Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onRegister();
        return false;
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black87,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onRegister,
                      ),
                    ),
                    const Icon(Icons.security, size: 40, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Fake News Detector',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Name',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter name' : null,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (v.length < 6 || v.length > 64) {
                          return 'Email must be between 6 and 64 characters';
                        }
                        if (!v.endsWith('@gmail.com')) {
                          return 'Email must end with @gmail.com';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 8) return 'Minimum 8 characters';
                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                          return 'At least 1 uppercase letter required';
                        }
                        if (!RegExp(r'[a-z]').hasMatch(v)) {
                          return 'At least 1 lowercase letter required';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return 'At least 1 number required';
                        }
                        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
                          return 'Must contain at least 1 special character';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm password';
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Register'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: Colors.white,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      validator: validator,
    );
  }
}

// ---------------------------------------------------------------------------
// LOGIN PAGE
// ---------------------------------------------------------------------------

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _loginError = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginError = '';
    });

    try {
      // Login uses form-encoded body (OAuth2 standard)
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('token', data['access_token'] as String);
        widget.onLogin();
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        setState(() => _loginError = 'User not found or wrong password');
      } else {
        setState(() => _loginError = 'Server error. Try again later.');
      }
    } catch (e) {
      setState(() => _loginError = 'Network error. Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black87,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 40, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Fake News Detector',
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
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    cursorColor: Colors.white,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter password' : null,
                  ),
                  if (_loginError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _loginError,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _submit,
                            child: const Text(
                              'LOGIN',
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
                        'New User? Register here',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        decorationThickness: 1,
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

// ---------------------------------------------------------------------------
// FORGOT PASSWORD PAGE
// ---------------------------------------------------------------------------

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 1;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );
      if (response.statusCode == 200) {
        setState(() => _step = 2);
      } else {
        setState(() => _error = 'Failed to send OTP. Check the email address.');
      }
    } catch (_) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() => _error = 'Please enter the OTP');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _step = 3);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        setState(() => _error = 'Invalid verification code. Try again.');
      } else {
        setState(() => _error = 'Server error. Try again.');
      }
    } catch (_) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty) {
      setState(() => _error = 'Please enter a new password');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'new_password': _newPasswordController.text.trim(),
          'confirm_password': _confirmPasswordController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successful')),
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = 'Failed to reset password. Try again.');
      }
    } catch (_) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black87,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_reset, size: 40, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                if (_step == 1) ...[
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Enter Email',
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton('Send OTP', _sendOtp),
                ],
                if (_step == 2) ...[
                  _buildTextField(
                    controller: _otpController,
                    hint: 'Enter OTP',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton('Verify OTP', _verifyOtp),
                ],
                if (_step == 3) ...[
                  _buildTextField(
                    controller: _newPasswordController,
                    hint: 'New Password',
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    obscure: true,
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton('Reset Password', _resetPassword),
                ],
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return _isLoading
        ? const CircularProgressIndicator(color: Colors.white)
        : ElevatedButton(
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(color: Colors.black)),
          );
  }
}

// ---------------------------------------------------------------------------
// FAKE NEWS DETECTOR  (main chat-like widget)
// ---------------------------------------------------------------------------

class FakeNewsDetector extends StatefulWidget {
  const FakeNewsDetector({super.key});

  @override
  State<FakeNewsDetector> createState() => _FakeNewsDetectorState();
}

class _FakeNewsDetectorState extends State<FakeNewsDetector> {
  final TextEditingController _controller = TextEditingController();

  static const double _textFieldHeight = 50;
  static const double _iconButtonSize = 48;

  String _inputText = '';
  String _resultText = '';
  bool _isAnalyzing = false;
  bool _imageUploaded = false;

  final ImagePicker _picker = ImagePicker();

  // -------------------------------------------------------------------
  // Show the bottom sheet menu for camera / gallery
  // -------------------------------------------------------------------
  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openCamera();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.image, color: Colors.white),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // API call – text prediction
  // -------------------------------------------------------------------
  Future<void> _onSubmit(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _inputText = trimmed;
      _imageUploaded = false;
      _resultText = '';
    });
    _controller.clear();

    final token = await getToken();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'news_input': trimmed}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _resultText = data['prediction'].toString());
      } else if (response.statusCode == 401) {
        setState(() => _resultText = 'Unauthorized. Please log in again.');
      } else {
        setState(() => _resultText = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _resultText = 'Network error: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // -------------------------------------------------------------------
  // API call – image prediction  (POST /predict-image)
  // Field name must match backend param: image_file
  // -------------------------------------------------------------------
  Future<void> _sendImage(String imagePath) async {
  final file = File(imagePath);

  print("Path: $imagePath");
  print("Exists: ${file.existsSync()}");
  print("Size: ${file.lengthSync()}");  

  setState(() {
    _isAnalyzing = true;
    _imageUploaded = true;
    _inputText = 'Image uploaded';
    _resultText = '';
  });

  final token = await getToken();

  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/predict-image'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image_file',
        imagePath,
        filename: imagePath.split('/').last, 
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _resultText = data['prediction'].toString());
      } else if (response.statusCode == 401) {
        setState(() => _resultText = 'Unauthorized. Please log in again.');
      } else if (response.statusCode == 404) {
        final data= jsonDecode(response.body);
        setState(() => _resultText = data['detail']??"Not found");
      } else {
        setState(() => _resultText = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _resultText = 'Network error: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // -------------------------------------------------------------------
  // Image helpers
  // -------------------------------------------------------------------

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        await _showFullScreenPreview(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _openCamera() async {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera available on this device')),
      );
      return;
    }
    try {
      final imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
      if (imagePath != null && mounted) {
        await _showFullScreenPreview(imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  // Full-screen preview — on ✓ sends to /predict-image
  Future<void> _showFullScreenPreview(String imagePath) async {
    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'cancelBtn',
                      backgroundColor: Colors.red,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                    FloatingActionButton(
                      heroTag: 'confirmBtn',
                      backgroundColor: Colors.green,
                      onPressed: () => Navigator.pop(context, true),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (accepted == true && mounted) {
      await _sendImage(imagePath);
    }
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SizedBox(
      width: double.infinity,
      height: isLandscape ? 160 : 620,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ---- Input display box ----
          if (_inputText.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _resultCard(
                label: _imageUploaded ? '' : 'Input',
                content: _inputText,
                maxHeight: 200,
              ),
            ),

          // ---- Result box ----
          if (_inputText.isNotEmpty)
            Positioned(
              top: 220,
              left: 0,
              right: 0,
              child: _isAnalyzing
                  ? const Center(child: CircularProgressIndicator())
                  : _resultCard(
                      label: 'Result',
                      content: _resultText,
                      maxHeight: 300,
                    ),
            ),

          // ---- Bottom input row ----
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Plus / attach button — opens bottom sheet
                SizedBox(
                  width: _iconButtonSize,
                  height: _iconButtonSize,
                  child: Material(
                    color: Colors.black87,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _showAttachMenu,
                      child: const SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: SizedBox(
                    height: _textFieldHeight,
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _onSubmit,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        hintText: _imageUploaded
                            ? 'Image uploaded'
                            : 'Enter the content or title',
                        prefixIcon: _imageUploaded
                            ? const Icon(
                                Icons.image,
                                color: Colors.black54,
                                size: 20,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.black87),
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

                const SizedBox(width: 8),

                // Send button
                SizedBox(
                  width: _iconButtonSize,
                  height: _iconButtonSize,
                  child: Material(
                    color: Colors.black87,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _onSubmit(_controller.text),
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

  Widget _resultCard({
    required String label,
    required String content,
    required double maxHeight,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black),
        ),
        child: SingleChildScrollView(
          child: Text(
            label.isEmpty ? content : '$label: $content',
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CAMERA SCREEN
// ---------------------------------------------------------------------------

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
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Take a photo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Camera error:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return OrientationBuilder(
              builder: (_, orientation) =>
                  orientation == Orientation.landscape
                      ? Center(child: CameraPreview(_controller))
                      : CameraPreview(_controller),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _takePicture,
        child: const Icon(Icons.camera, color: Colors.black),
      ),
    );
  }
}