import 'package:flutter/material.dart';
import 'package:ecoquest/services/auth.dart';
import 'package:ecoquest/model/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthService _authService = AuthService();
  String userName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Fetch user data
  Future<void> _loadUserData() async {
    MyUser? user = await _authService.getUserData();
    if (user != null) {
      setState(() {
        userName = user.name;
      });
    } else {
      setState(() {
        userName = "User Not Found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text(
          'Welcome, $userName!', // ✅ Display user's name
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
