import 'dart:convert'; // for jsonEncode and jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // http package
import '../theme.dart';
import '../api/api_connection.dart';  // ensure ApiConnection.validateEmail & ApiConnection.signUp are defined here
import '../api/registration_user.dart'; // ensures this has toJson() method
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _signUp() async {
    setState(() {
      _error = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = "Please fill in all fields");
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = "Please enter a valid email");
      return;
    }

    if (password != confirm) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    // Debug print
    print("Validating user email for: $email");
    await validateUserEmail(email, username, password);

    setState(() => _isLoading = false);
  }

  Future<void> validateUserEmail(String email, String username, String password) async {
    try {
      var res = await http.post(
        Uri.parse(ApiConnection.validateEmail),
        body: {
          'email': email,
        },
      );

      if (res.statusCode == 200) {
        var resBody = jsonDecode(res.body);
        if (resBody['emailFound'] == true) {
          setState(() => _error = "Email already exists");
        } else {
          await registerAndSaveUserRecord(username, email, password);
        }
      } else {
        setState(() => _error = "Server error: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Network error: ${e.toString()}");
    }
  }

Future<void> registerAndSaveUserRecord(String username, String email, String password) async {
  try {
    RegistrationUser userModel = RegistrationUser(
      username: username,
      email: email,
      password: password,
    );

    final jsonPayload = jsonEncode(userModel.toJson());
    print("Sending registration JSON: $jsonPayload");
    print("URL: ${ApiConnection.signUp}");

    var res = await http.post(
      Uri.parse(ApiConnection.signUp),
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonPayload,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      var resBody = jsonDecode(res.body);
      if (resBody['success'] == true || resBody['Success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        setState(() => _error = resBody['message'] ?? "Registration failed");
      }
    } else {
      setState(() => _error = "Server error: ${res.statusCode}");
    }
  } catch (e) {
    setState(() => _error = "Network error: ${e.toString()}");
  }
}

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF256BFF),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Welcome to MindSet!',
                style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Montserrat', // Change to your preferred font or a font you have added
                shadows: [
                  Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black45,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Let’s make your tasks easier, one step at a time.',
                style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: 'inter', // Change to your preferred font or a font you have added
                shadows: [
                  Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black45,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/signup.png',
              height: 250,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: kTextFieldDecoration.copyWith(labelText: 'Username'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: kTextFieldDecoration.copyWith(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: kTextFieldDecoration.copyWith(labelText: 'Password'),
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: kTextFieldDecoration.copyWith(labelText: 'Confirm Password'),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isLoading ? null : _signUp(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign Up'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Already have an account? Sign in'),
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 251, 255, 0),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
