import 'package:ecoquest/screens/home/home.dart';
import 'package:ecoquest/screens/authentication/register.dart'; // Register screen import
import 'package:ecoquest/services/sharedpreferences.dart'; // ✅ Import shared preferences
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKey = GlobalKey<FormState>(); // ✅ Form key for validation
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false; // ✅ Loading state

  Future<void> _signIn() async {
    setState(() {
      isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final response = await http.post(
          Uri.parse(
            'https://ecoquest.ruputech.com/login.php',
          ), // 🔁 Replace with your backend URL
          body: {'email': email, 'password': password},
        );

        final data = jsonDecode(response.body);

        if (data['success'] && data['user'] != null) {
          final user = data['user'] ?? null; // ✅ Check if user data exists
          print(user); // ✅ Debugging line
          String userId = user['uid']?.toString() ?? '';
          String userName = user['name']?.toString() ?? '';
          // ✅ Save logged-in status
          await PreferencesHelper.setUserSignedIn(true);
          await PreferencesHelper.setUserID(userId); // ✅ Save user ID
          await PreferencesHelper.setUserName(userName); // ✅ Save user name

          // ✅ Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Login failed';
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Error: $e';
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ Extends background behind AppBar
      appBar: AppBar(
        title: Text(
          'Sign In',
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
                MaterialPageRoute(
                  builder: (context) => Register(),
                ), // ✅ Navigate to Register
              );
            },
            child: Text(
              'Register',
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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // ✅ Full-Screen Background Image
                  Positioned.fill(
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/images/background.webp',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.black.withOpacity(
                            0.5,
                          ), // ✅ Dark overlay
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
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.brown,
                              ),
                              filled: true,
                              fillColor: Colors.white.withAlpha(230),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Enter your email';
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value))
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

                          // ✅ Sign In Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 10),

                          // ✅ "Forget Password?" Text Button
                          TextButton(
                            onPressed: () {
                              print(
                                "Forget Password tapped!",
                              ); // TODO: Implement password reset navigation
                            },
                            child: Text(
                              'Forget Password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
