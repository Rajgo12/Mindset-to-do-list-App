import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../api/api_connection.dart';
import 'signup_page.dart';
import 'home_page.dart'; 
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController(); // username or email
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _error = null;
    });

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _error = "Please fill in all fields");
      return;
    }

    // No email regex check because identifier can be username or email

    setState(() => _isLoading = true);

    try {
      // Assuming your LoginUser model has been updated accordingly
      Map<String, String> loginData = {
        'identifier': identifier,
        'password': password,
      };

      final res = await http.post(
        Uri.parse(ApiConnection.hostConnectAuth + "/login.php"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(loginData),
      );

      if (res.statusCode == 200) {
      final resBody = jsonDecode(res.body);

      if (resBody['success'] == true && mounted) {
        final userData = resBody['user'];
        final userId = userData['id'];
        final username = userData['username'];
        final userEmail = userData['email'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavPage(
              userId: userId,
              email: userEmail,
              username: username,
            ),
          ),
        );
      } else {
        setState(() => _error = resBody['message'] ?? "Login failed");
      }
    } else {
      setState(() => _error = "Server error: ${res.statusCode}");
    }
    } catch (e) {
      setState(() => _error = "Network error: ${e.toString()}");
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF256BFF),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 0),
                const Text(
                  'Welcome Back!',
                    style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                    shadows: [
                      Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Image.asset(
                  'assets/login.png',
                  height: 250,
                  width: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _identifierController,
                  decoration: kTextFieldDecoration.copyWith(labelText: 'Username/Email'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: kTextFieldDecoration.copyWith(labelText: 'Password'),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isLoading ? null : _login(),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)
                        : const Text('Login'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 255, 230, 0), // Change text color here
                  ),
                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
