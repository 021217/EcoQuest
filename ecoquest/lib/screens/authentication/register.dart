import 'package:ecoquest/screens/authentication/signIn.dart';
import 'package:ecoquest/screens/home/home.dart';
import 'package:ecoquest/services/sharedpreferences.dart'; // ✅ Import shared preferences
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>(); // ✅ Form key for validation
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? errorMessage;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final response = await http.post(
          Uri.parse(
            'https://ecoquest.ruputech.com/register.php',
          ), // ✅ Replace with your IP or domain
          body: {'name': name, 'email': email, 'password': password},
        );

        final data = jsonDecode(response.body);
        final user = data['user'] ?? null; // ✅ Check if user data exists
        print(user); // ✅ Debugging line
        String userId = user['uid']?.toString() ?? '';
        String userName = user['name']?.toString() ?? '';
        if (data['success']) {
          // ✅ Save logged-in status
          await PreferencesHelper.setUserSignedIn(true);
          await PreferencesHelper.setUserID(userId); // ✅ Save user ID
          await PreferencesHelper.setUserName(userName); // ✅ Save user name

          // ✅ Go to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Registration failed.';
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ Extends background behind AppBar
      appBar: AppBar(
        title: Text(
          'Register',
          style: TextStyle(color: Colors.white), // ✅ White title
        ),
        backgroundColor: Colors.transparent, // ✅ Transparent AppBar
        elevation: 0, // ✅ Removes shadow
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignIn()),
              );
            },
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // ✅ Full-Screen Background Image
          Positioned.fill(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background.webp'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  color: Colors.black.withOpacity(0.5), // ✅ Dark overlay
                ),
              ],
            ),
          ),

          // ✅ Form Contents
          Padding(
            padding: const EdgeInsets.all(50.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person, color: Colors.brown),
                      filled: true,
                      fillColor: Colors.white.withAlpha(230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter your name';
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email, color: Colors.brown),
                      filled: true,
                      fillColor: Colors.white.withAlpha(230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter your email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return 'Enter a valid email';
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock, color: Colors.brown),
                      filled: true,
                      fillColor: Colors.white.withAlpha(230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter your password';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.brown),
                      filled: true,
                      fillColor: Colors.white.withAlpha(230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Re-enter your password';
                      if (value != _passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // ✅ Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
