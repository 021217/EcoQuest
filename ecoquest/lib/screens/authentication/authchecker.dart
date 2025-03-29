import 'package:ecoquest/screens/authentication/signIn.dart';
import 'package:ecoquest/screens/home/home.dart';
import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:flutter/material.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    bool isSignedIn =
        await PreferencesHelper.getUserSignedIn(); // ✅ Retrieve auth status

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isSignedIn ? HomeScreen() : SignIn(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // ✅ Shows loading while checking auth status
      ),
    );
  }
}
