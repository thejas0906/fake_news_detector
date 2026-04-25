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

const String _baseUrl = 'https://communication-offering-erik-entries.trycloudflare.com';

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

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
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
              : LoginPage(
                  onLogin: _login,
                  onShowRegister: _showRegisterPage,
                ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
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
        setState(() => _errorMessage = 'Registration failed. Please try again.');
      }
    } catch (_) {
      setState(() => _errorMessage = 'Network error. Check your connection.');
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
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
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
                  const SizedBox(height: 20),

                  // Name
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Name',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter name' : null,
                  ),

                  // Email
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

                  // Password
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

                  // Confirm Password
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    obscure: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your password';
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
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14),
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
        enabledBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        focusedBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
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
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        body: {
          'username': _emailController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        await saveLogin();
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("token", data["access_token"]);
        widget.onLogin();
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        setState(() => _loginError = 'User not found or wrong password');
      } else {
        setState(() => _loginError = 'Server error. Try again later.');
      }
    } 
    finally {
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

                  // Email
                  TextFormField(
                    controller: _emailController,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
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

                  // Password
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
// FORGOT PASSWORD PAGE  (3-step: email → OTP → new password)
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
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Step 1 – send OTP to email
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
        headers: {
          "Content-Type": "application/json",
          },
          body: jsonEncode({
            "email": _emailController.text
            }),
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

  // Step 2 – verify OTP
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
      headers: {
        "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "otp": _otpController.text.trim(),
          }),);
      

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

  // Step 3 – reset password
  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty) {
      setState(() => _error = 'Please enter a new password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
    final response = await http.post(
      Uri.parse('$_baseUrl/reset-password'),
      headers: {
        "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "new_password": _newPasswordController.text.trim(),
          "confirm_password": _confirmPasswordController.text.trim(),
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

                // Step 1 – Email input
                if (_step == 1) ...[
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Enter Email',
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton('Send OTP', _sendOtp),
                ],

                // Step 2 – OTP input
                if (_step == 2) ...[
                  _buildTextField(
                    controller: _otpController,
                    hint: 'Enter OTP',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton('Verify OTP', _verifyOtp),
                ],

                // Step 3 – New password input
                if (_step == 3) ...[
                  _buildTextField(
                    controller: _newPasswordController,
                    hint: 'New Password',
                    obscure: true,
                  ),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    obscure: true,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_newPasswordController.text != _confirmPasswordController.text) {
                        setState(() {
                          _error = "Passwords do not match";
                          });
                          return;
                      }
                    _resetPassword(); 
                    },
                    child: const Text(
                      "Reset Password",
                      style: TextStyle(color: Colors.black),
                      ),
),
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
        enabledBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        focusedBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
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

  String _inputText = '';   // the submitted text shown in the "Input" box
  String _resultText = '';  // the API verdict shown in the "Result" box
  bool _isAnalyzing = false;

  String? _confirmedImagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // API call – send text (and optional image) to the backend
  // -------------------------------------------------------------------

  

  // -------------------------------------------------------------------
  // Image helpers
  // -------------------------------------------------------------------

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) await _showFullScreenPreview(image.path);
  }

  Future<void> _showFullScreenPreview(String imagePath) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Scaffold(
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
                      heroTag: 'cancelBtn',
                      backgroundColor: Colors.red,
                      onPressed: () => Navigator.pop(context , false),
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

    if (accepted == true) {
      setState(() => _confirmedImagePath = imagePath);
    }
  }

  void _removeImage() => setState(() => _confirmedImagePath = null);

  // -------------------------------------------------------------------
  // Submit handler
  // -------------------------------------------------------------------

  Future<void> _onSubmit(String input) async {
  if (input.isEmpty) return;

  setState(() {
    _isAnalyzing = true;
    _inputText = input;
  });

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token"); 

  try {
    final response = await http.post(
      Uri.parse("$_baseUrl/predict"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "news_input": input,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _resultText = data["prediction"];
      });
    } else {
      setState(() {
        _resultText = "Server error: ${response.statusCode}";
      });
    }
  } catch (e) {
    setState(() {
      print(e);
      _resultText = "Network error";
    });
  } finally {
    setState(() {
      _isAnalyzing = false;
    });
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
        children: [
          // ---- Attached image thumbnail ----
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
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _removeImage,
                        child: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ---- Input display box ----
          if (_inputText.isNotEmpty)
            Positioned(
              top: 0,
              left: 70,
              right: 0,
              child: _resultCard(
                label: 'Input',
                content: _inputText,
                maxHeight: 150,
              ),
            ),

          // ---- Result / analyzing box ----
          if (_inputText.isNotEmpty)
            Positioned(
              top: 170,
              left: 0,
              right: 70,
              child: _isAnalyzing
                  ? const Center(child: CircularProgressIndicator())
                  : _resultCard(
                      label: 'Result',
                      content: _resultText,
                      maxHeight: 400,
                    ),
            ),

          // ---- Input row (add button + text field + send button) ----
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                // ++ menu
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
                        if (value == 'camera') {
                          final imagePath = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CameraScreen(),
                            ),
                          );
                          if (imagePath != null) {
                            await _showFullScreenPreview(imagePath);
                          }
                        } else if (value == 'gallery') {
                          await _pickFromGallery();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'camera',
                          child: Icon(Icons.camera_alt, color: Colors.white),
                        ),
                        PopupMenuItem(
                          value: 'gallery',
                          child: Icon(Icons.image, color: Colors.white),
                        ),
                      ],
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
            '$label: $content',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                child: Text(
                  'Camera error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            return OrientationBuilder(
              builder: (_, orientation) => orientation == Orientation.landscape
                  ? Center(child: CameraPreview(_controller))
                  : CameraPreview(_controller),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final image = await _controller.takePicture();
            if (!mounted) return;
            Navigator.pop(context, image.path);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to take photo: $e')),
            );
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}