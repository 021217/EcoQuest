import 'package:ecoquest/screens/marketplace/marketplacescreen.dart';
import 'package:ecoquest/screens/profile/profilesettingsscreen.dart';
import 'package:ecoquest/screens/social/friendlistscreen.dart';
import 'package:ecoquest/screens/tips/ecotipsscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const HomeScreen());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'EcoQuest'),
    );
  }
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
                Icon(Icons.egg, size: 20, color: Colors.green), // Seed
                Icon(Icons.grass, size: 20, color: Colors.green), // Sprout
                Icon(Icons.eco, size: 20, color: Colors.green), // Sapling
                Icon(Icons.nature, size: 20, color: Colors.green), // Tree
                Icon(Icons.park, size: 20, color: Colors.green), // Mature
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  double _progress = 0.0;
  int waterNum = 200000;
  final TextEditingController _treeNameController = TextEditingController(
    text: "My Tree",
  );
  late AnimationController _progressController;
  late AnimationController _dropController;
  late Animation<double> _progressAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _dropOffset;

  bool showDrop = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _dropOffset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 2),
    ).animate(CurvedAnimation(parent: _dropController, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dropController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _dropController.dispose();
    _treeNameController.dispose();
    super.dispose();
  }

  void _onWaterPressed() {
    if (waterNum >= 250 && _progress < 1.0) {
      setState(() {
        waterNum -= 250;
      });

      double targetProgress = (_progress + 0.05).clamp(0.0, 1.0);

      _progressAnimation = Tween<double>(
        begin: _progress,
        end: targetProgress,
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
      )..addListener(() {
        setState(() {
          _progress = _progressAnimation.value;
        });
      });

      _progressController.forward(from: 0.0);

      _dropController.forward(from: 0.0).whenComplete(() {
        setState(() {
          showDrop = false;
        });
      });
      setState(() {
        showDrop = true;
      });
    }
  }

  Widget _buildDropAnimation() {
    if (!showDrop) return Container();

    return SlideTransition(
      position: _dropOffset,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Image.asset(
          'assets/images/waterDrop.png',
          width: 50,
          height: 50,
        ),
      ),
    );
  }

  //get time
  bool isDayTime() {
    DateTime now = DateTime.now().toUtc().add(
      const Duration(hours: 8),
    ); //Malaysia time
    int hour = now.hour;

    //int hour = 20; //handle time manually, for debug and testing purpose

    // Debug log to check time
    debugPrint(
      "Current Malaysia Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)} (Hour: $hour)",
    );

    return hour >= 6 && hour < 18; //daytime between 6am to 6pm
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // index of the profile/settings item
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FriendListScreen()),
      );
    } else if (index == 1) {
      // index of the profile/settings item
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
      );
    } else if (index == 3) {
      // index of the profile/settings item
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EcoTipsScreen()),
      );
    } else if (index == 4) {
      // index of the profile/settings item
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
      );
    }
  }

  void _updateProgress(double newProgress) {
    setState(() {
      _progress = newProgress;
    });
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    String bgImage =
        isDayTime() ? 'assets/images/DayBg.webp' : 'assets/images/NightBg.webp';
    Color progressBarTextColor = isDayTime() ? Colors.black : Colors.white;
    String virtualTree = getImageForProgress();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // background image
            Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.fill)),

            // ground image
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/Ground.webp',
                fit: BoxFit.cover,
                height: screenHeight * 0.5,
              ),
            ),

            // virtual tree image
            Positioned(
              left: screenWidth * -0.1,
              top: screenHeight * 0.25,
              child: Container(
                width: screenWidth * 1.2,
                height: screenHeight * 0.5,
                color: Colors.transparent,
                child: Center(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(virtualTree),
                  ),
                ),
              ),
            ),

            Positioned(
              left: screenWidth * 0.3,
              top: screenHeight * 0.75,
              child: Container(
                width: screenWidth * 0.4,
                height: screenHeight * 0.04,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: TextField(
                    controller: _treeNameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter Tree Name',
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: screenHeight * 0.090,
              right: screenWidth * 0.025,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    iconSize: 30,
                    icon: Image.asset(
                      'assets/images/wateringCan.png',
                      width: 64,
                      height: 64,
                    ),
                    onPressed: _onWaterPressed,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [const Text('Water'), Text('$waterNum ml')],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: screenHeight * 0.090,
              right: screenWidth * 0.745,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    iconSize: 30,
                    icon: Image.asset(
                      'assets/images/achievement.png',
                      width: 64,
                      height: 64,
                    ),
                    onPressed: _onWaterPressed, //change afterward
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(children: [const Text('Achievement')]),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: screenHeight * 0.5,
              right: screenWidth * 0.815,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    iconSize: 30,
                    icon: Image.asset(
                      'assets/images/task.png',
                      width: 64,
                      height: 64,
                    ),
                    onPressed: _onWaterPressed, //change afterward
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(children: [const Text('Task')]),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: screenHeight * 0.5,
              right: screenWidth * 0.025,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    iconSize: 30,
                    icon: Image.asset(
                      'assets/images/leaderboard.png',
                      width: 64,
                      height: 64,
                    ),
                    onPressed: _onWaterPressed, //change afterward
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(children: [const Text('Leaderboard')]),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 300,
              left: 0,
              right: 0,
              child: Center(child: _buildDropAnimation()),
            ),

            // grown progress bar
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Grown Progress',
                      style: TextStyle(
                        color: progressBarTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    ProgressBarWidget(progress: _progress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // StepBar + BottomNav
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.015,
              horizontal: screenWidth * 0.05,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF8B4513),
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Step",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: screenWidth * 0.1),
                StepProgressBarWidget(progress: 0.50),
              ],
            ),
          ),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF8B4513),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.black,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.group, size: 40),
                label: 'Friends',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store, size: 40),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 40),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book, size: 40),
                label: 'Eco Tips',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 40),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
