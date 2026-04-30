import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../model/auth/login_request.dart';
import '../model/auth/register_request.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true; // Toggle between Login and Register
  bool _isLoading = false;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login Logic
        final request = LoginRequest(
          login: _usernameController.text,
          password: _passwordController.text,
        );
        final token = await AuthService().login(request);

        if (token != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Welcome back!")),
          );
          // Navigate to Home (or Debug for now)
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          throw Exception("Invalid credentials");
        }
      } else {
        // Registration Logic
        final request = RegisterRequest(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        final success = await AuthService().register(request);

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Please log in.")),
          );
          setState(() => _isLogin = true);
        } else {
          throw Exception("Registration failed");
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.public, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? "Welcome to Globetrottr" : "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter username" : null,
                ),
                const SizedBox(height: 16),

                // Email Field (Only for Register)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value!.contains('@') ? null : "Enter a valid email",
                  ),
                  const SizedBox(height: 16),
                ],

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.length < 4 ? "Password too short" : null,
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? "LOGIN" : "REGISTER"),
                ),

                // Toggle Link
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(_isLogin
                      ? "Don't have an account? Register here"
                      : "Already have an account? Login here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}