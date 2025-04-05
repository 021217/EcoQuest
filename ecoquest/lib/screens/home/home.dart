import 'package:ecoquest/screens/profile/profilesettingsscreen.dart';
import 'package:flutter/material.dart';
import 'package:ecoquest/services/auth.dart';
import 'package:ecoquest/model/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class ProgressBarWidget extends StatelessWidget {
  final double progress;

  const ProgressBarWidget({super.key, required this.progress});

  double getProgress() {
    return progress;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // Ensures the entire widget is centered
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
        children: [
          // Progress Bar
          Stack(
            children: [
              // Progress Bar Background
              Container(
                width: 250,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Progress Indicator
              Positioned(
                left: 0,
                child: Container(
                  width: 250 * progress, // Dynamic width based on progress
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          // Spacing between progress bar and icons
          const SizedBox(height: 8),

          // Icons Below Progress Bar
          SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.circle, size: 20, color: Colors.green), // Seed
                Icon(Icons.grass, size: 20, color: Colors.green), // Sprout
                Icon(Icons.nature, size: 20, color: Colors.green), // Sapling
                Icon(Icons.eco, size: 20, color: Colors.green), // Tree
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StepProgressBarWidget extends StatelessWidget {
  final double progress;

  const StepProgressBarWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icons Above Progress Bar
        SizedBox(
          width: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.location_on, size: 25, color: Colors.white),
              Icon(Icons.location_on, size: 25, color: Colors.white),
              Icon(Icons.location_on, size: 25, color: Colors.white),
              Icon(Icons.location_on, size: 25, color: Colors.white),
            ],
          ),
        ),

        // Spacing between icons and progress bar
        const SizedBox(height: 1),

        // Progress Bar
        Stack(
          children: [
            // Progress Bar Background
            Container(
              width: 250,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress Indicator
            Positioned(
              left: 0,
              child: Container(
                width: 250 * progress, // Dynamic width based on progress
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.blue, // Step progress bar in blue
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  AuthService _authService = AuthService();
  String userName = "Loading...";
  int _selectedIndex = 2;
  double _progress = 0.75;

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

  //get time
  bool isDayTime() {
    DateTime now = DateTime.now().toUtc().add(
      const Duration(hours: 8),
    ); //Malaysia time
    int hour = now.hour;

    //int hour = 20; //handle time manually, for debug and testing purpose

    // Debug log to check time
    //debugPrint("Current Malaysia Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)} (Hour: $hour)");

    return hour >= 6 && hour < 18; //daytime between 6am to 6pm
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 4) {
      // index of the profile/settings item
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
      );
    }
  }

  // for futher development to update the progress
  // void _updateProgress(double newProgress) {
  //   setState(() {
  //     _progress = newProgress;
  //   });
  // }

  String getImageForProgress() {
    if (_progress < 0.25) {
      return 'assets/images/seed.webp';
    } else if (_progress < 0.50) {
      return 'assets/images/sprout.webp';
    } else if (_progress < 0.75) {
      return 'assets/images/sapling.webp';
    } else {
      return 'assets/images/tree.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    String bgImage =
        isDayTime()
            ? 'assets/images/DayBg.webp'
            : 'assets/images/NightBg.webp'; // Switch images
    Color progressBarTextColor = isDayTime() ? Colors.black : Colors.white;
    String virtualTree = getImageForProgress();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.fill)),

            // Ground Image at Bottom
            Positioned(
              bottom: 0, // Align to the bottom
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/Ground.webp',
                fit: BoxFit.cover, // Make sure it covers the width
                height: 500, // Adjust height as needed
              ),
            ),

            // Adjustable Positioned Container
            Positioned(
              left: -42,
              top: 145,
              child: Container(
                width: 500,
                height: 500,
                color: Colors.transparent,
                child: Center(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(virtualTree),
                  ),
                ),
              ),
            ),

            // Foreground Content
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 15),
                    Text(
                      'Grown Progress',
                      style: TextStyle(
                        color: progressBarTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    ProgressBarWidget(progress: _progress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Add a Column to stack ProgressBar & Bottom Navigation
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step Progress Container
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF8B4513), // Same as bottom nav bar
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // "Step" Label on the Left
                const Text(
                  "Step",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 40),
                StepProgressBarWidget(progress: 0.50),
              ],
            ),
          ),

          // Bottom Navigation Bar
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF8B4513),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.black,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Hero(tag: 'friends', child: Icon(Icons.group, size: 40)),
                label: 'Friends',
              ),
              BottomNavigationBarItem(
                icon: Hero(tag: 'market', child: Icon(Icons.store, size: 40)),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Hero(tag: 'home', child: Icon(Icons.home, size: 40)),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Hero(tag: 'eco-tips', child: Icon(Icons.book, size: 40)),
                label: 'Eco Tips',
              ),
              BottomNavigationBarItem(
                icon: Hero(tag: 'profile', child: Icon(Icons.person, size: 40)),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );

    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text('Home'),
    //     centerTitle: true,
    //     automaticallyImplyLeading: false,
    //   ),
    //   body: Center(
    //     child: Text(
    //       'Welcome, $userName!', // ✅ Display user's name
    //       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    //     ),
    //   ),
    // );
  }
}
