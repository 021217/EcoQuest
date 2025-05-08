import 'dart:async';
import 'dart:convert';
import 'package:ecoquest/screens/marketplace/marketplacescreen.dart';
import 'package:ecoquest/screens/profile/profilesettingsscreen.dart';
import 'package:ecoquest/screens/social/friendlistscreen.dart';
import 'package:ecoquest/screens/pedometer/stepConversion.dart';
import 'package:ecoquest/screens/tips/ecotipsscreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final barWidth = screenWidth * 0.6;
    final barHeight = screenHeight * 0.017;

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
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Progress Indicator
              Positioned(
                left: 0,
                child: Container(
                  width: barWidth * progress, // Dynamic width based on progress
                  height: barHeight,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final barWidth = screenWidth * 0.6;
    final barHeight = screenHeight * 0.017;

    return Column(
      children: [
        // Icons Above Progress Bar
        SizedBox(
          width: barWidth,
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
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress Indicator
            Positioned(
              left: 0,
              child: Container(
                width: barWidth * progress, // Dynamic width based on progress
                height: barHeight,
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
  int waterNum = 0;
  String userId = ''; // Example user ID, replace with actual user ID

  late AnimationController _progressController;
  late AnimationController _dropController;
  late Animation<double> _progressAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _dropOffset;

  bool isFirstTimeLogin = true;
  bool hasTree = false;
  String treeName = '';
  String treeId = '';

  bool showDrop = false;

  bool isLoading = false;
  bool hasJustPlanted = false; // To prevent duplicate popups

  int _steps = 0;
  int _points = 0;
  int _bonusPoints = 0;
  bool todayFirstLogin = false;
  int _baseSteps = 0;
  int _yesterdaySteps = 0;
  String status = "Checking sensor...";
  late Stream<StepCount> _stepCountStream;

  late StreamController<int> _waterStreamController;
  Timer? _waterPollingTimer;
  int _lastFetchedWater = 0;

  @override
  void initState() {
    super.initState();
    checkUserTreeStatus(); // Check user tree status on load
    loadUserId(); // Load user ID from shared preferences
    _waterStreamController = StreamController<int>.broadcast();
    startWaterPolling();

    _initPedometerState();
    _scheduleMidnightReset(); // Schedule midnight reset for steps
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
    _waterPollingTimer?.cancel();
    _waterStreamController.close();
    _stepCountStream.drain(); // Close the stream to prevent memory leaks
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initPedometerState(); // Reattach pedometer listener
    }
  }

  void startWaterPolling() {
    _waterPollingTimer?.cancel(); // prevent multiple timers
    _waterPollingTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final response = await http.post(
        Uri.parse("https://ecoquest.ruputech.com/get_water_balance.php"),
        body: {"uid": userId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"]) {
          final newWater = data["water"];
          if (newWater != _lastFetchedWater) {
            _lastFetchedWater = newWater;
            _waterStreamController.add(newWater);
          }
        }
      }
    });
  }

  void showDailyTaskDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: screenHeight * 0.8,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromRGBO(232, 209, 183, 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF8B4513), width: 3),
            ),
            child: Column(
              children: [
                // Header
                Stack(
                  children: [
                    Center(
                      child: Text(
                        "Tasks",
                        style: TextStyle(
                          color: Colors.brown[800],
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 25,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        buildTaskItem("🌱 Water a tree", true),
                        buildTaskItem("👣 Reach 5,000 steps", false),
                        buildTaskItem("👥 Visit 3 friends", false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchAchievements(String uid) async {
    final res = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_user_achievements.php"),
      body: {"uid": uid},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["success"]) {
        return List<Map<String, dynamic>>.from(data["achievements"]);
      }
    }
    return [];
  }

  void handleAchievementClaim(String achievementId, int reward) async {
    final res = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/claim_achievement_reward.php"),
      body: {"uid": userId, "achievement_id": achievementId},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["success"]) {
        // refresh water balance
        await fetchWaterBalance();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"])));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Already claimed.")),
        );
      }
    }
  }

  void showAchievementsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: screenHeight * 0.8,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromRGBO(232, 209, 183, 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF8B4513), width: 3),
            ),
            child: Column(
              children: [
                // Header
                Stack(
                  children: [
                    Center(
                      child: Text(
                        "Achievements",
                        style: TextStyle(
                          color: Colors.brown[800],
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 25,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAchievements(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const CircularProgressIndicator();

                        final achievements = snapshot.data!;
                        return GridView.builder(
                          itemCount: achievements.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemBuilder: (context, index) {
                            final a = achievements[index];
                            final completed = a['status'] == 'Completed';

                            return GestureDetector(
                              onTap: () {
                                if (completed)
                                  handleAchievementClaim(
                                    a['id'].toString(),
                                    a['reward'],
                                  );
                              },
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.green[100],
                                        backgroundImage:
                                            a['img'] != null
                                                ? NetworkImage(a['img'])
                                                : null,
                                        child:
                                            a['img'] == null
                                                ? const Icon(Icons.emoji_events)
                                                : null,
                                      ),
                                      if (!completed)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a['title'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          completed
                                              ? Colors.black
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildAchievement(String title, String emoji) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green[100],
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget buildTaskItem(String title, bool canClaim) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Progress & Claim Row
          Row(
            children: [
              // Progress bar
              Expanded(
                child: LinearProgressIndicator(
                  value: canClaim ? 1.0 : 0.4,
                  backgroundColor: Colors.grey[300],
                  color: canClaim ? Colors.brown : Colors.grey,
                  minHeight: 10,
                ),
              ),

              const SizedBox(width: 12),

              // Claim button
              ElevatedButton(
                onPressed: canClaim ? () => print('Claimed $title') : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canClaim ? const Color(0xFF8B4513) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Claim"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 8),
    ); // Malaysia time
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    Timer(durationUntilMidnight, () async {
      final prefs = await SharedPreferences.getInstance();
      todayFirstLogin = true; // Reset flag

      prefs.setInt('yesterdaySteps', _steps);
      prefs.remove(
        'lastLoginDate',
      ); // Remove so it reinitializes on next step event

      _initPedometerState(); // Re-run setup to capture new base steps
      _scheduleMidnightReset(); // Schedule again for next day
    });
  }

  void _initPedometerState() async {
    final prefs = await SharedPreferences.getInstance();
    _yesterdaySteps = prefs.getInt('yesterdaySteps') ?? 0;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? lastLoginDate = prefs.getString('lastLoginDate');
    int savedBaseSteps = prefs.getInt('baseSteps') ?? 0;

    if (lastLoginDate != today) {
      todayFirstLogin = true;
      prefs.setString('lastLoginDate', today);
    } else {
      todayFirstLogin = false;
      _baseSteps = savedBaseSteps;
    }

    var permissionStatus = await Permission.activityRecognition.status;
    if (!permissionStatus.isGranted) {
      await Permission.activityRecognition.request();
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(
      (event) {
        _onStepCount(event);
        setState(() {
          status = "Sensor working! Steps: ${event.steps}";
        });
      },
      onError: (error) {
        _onStepCountError(error);
        setState(() {
          status = "Sensor not available: $error";
        });
      },
      cancelOnError: true,
    );
  }

  void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
  }

  Future<void> loadUserId() async {
    String? userId = await PreferencesHelper.getUserID();
    if (userId != null && userId.isNotEmpty) {
      setState(() {
        this.userId = userId;
      });

      // These must run AFTER state is set
      await fetchActiveTreeId();
      await fetchTreeGrowth();
      await fetchWaterBalance();
    }
  }

  Future<void> fetchWaterBalance() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_water_balance.php"),
      body: {"uid": userId ?? ""},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          waterNum = data["water"];
        });
      } else {
        print("Water fetch failed: ${data['message']}");
      }
    }
    setState(() {
      isLoading = false;
    }); // Hide loading after fetching
  }

  Future<void> fetchActiveTreeId() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_active_tree.php"),
      body: {"uid": userId},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          treeId = data["tree_id"];
          treeName = data["name"];
        });
      } else {
        print("No active tree found.");
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchTreeGrowth() async {
    if (treeId == null) return;
    setState(() {
      isLoading = true;
    });
    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_tree_growth.php"),
      body: {"tree_id": treeId},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          _progress = double.tryParse(data["progress"].toString()) ?? 0.0;
        });
      } else {
        print("Growth fetch failed: ${data['message']}");
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _onStepCount(StepCount event) async {
    String? uid = await PreferencesHelper.getUserID();
    if (uid == null) return;

    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    // 1. Get yesterday's saved steps from server
    int yesterdaySteps = 0;
    try {
      final res = await http.post(
        Uri.parse("https://ecoquest.ruputech.com/get_yesterday_steps.php"),
        body: {"uid": uid, "date": yesterday},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"]) {
          yesterdaySteps = data["steps"] ?? 0;
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch yesterday steps: $e");
    }

    // 2. Calculate steps from device
    int todayRawSteps = event.steps;
    int todaySteps = todayRawSteps - yesterdaySteps;
    if (todaySteps < 0) todaySteps = 0;

    // 3. Update UI
    final points = StepConversion.convertSteps(todaySteps).points;
    setState(() {
      _steps = todaySteps;
      _points = points;
    });

    // 4. Send today’s raw steps (not the diff) to server
    try {
      await http.post(
        Uri.parse('https://ecoquest.ruputech.com/add_or_update_steps.php'),
        body: {'uid': uid, 'steps': todayRawSteps.toString(), 'date': today},
      );
    } catch (e) {
      debugPrint("🚫 Failed to send steps: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchFriendSteps() async {
    final userId = await PreferencesHelper.getUserID();

    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_friend_steps.php"),
      body: {"uid": userId},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        return List<Map<String, dynamic>>.from(data["friends"]);
      }
    }
    return []; // fallback if failed
  }

  void showLeaderboardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchFriendSteps(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Map<String, dynamic>> friendSteps = snapshot.data!;
              friendSteps.sort((a, b) {
                int aSteps = int.tryParse(a['steps'].toString()) ?? 0;
                int bSteps = int.tryParse(b['steps'].toString()) ?? 0;
                return bSteps.compareTo(aSteps);
              });

              return Container(
                width: screenWidth * 0.8,
                height: screenHeight * 0.7,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(232, 209, 183, 0.95),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF8B4513), width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Title and close button
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Center(
                            child: Text(
                              'Leaderboard',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 25,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Table header
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'No.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Friend',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Steps',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 15),
                        ],
                      ),
                    ),

                    // List of friends
                    Expanded(
                      child: ListView.builder(
                        itemCount: friendSteps.length,
                        itemBuilder: (context, i) {
                          var user = friendSteps[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 5,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${i + 1}.',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  backgroundImage:
                                      user['profile_pic'] != null &&
                                              user['profile_pic']
                                                  .toString()
                                                  .isNotEmpty
                                          ? NetworkImage(user['profile_pic'])
                                          : null,
                                  radius: 24,
                                  backgroundColor: Colors.grey[300],
                                  child:
                                      (user['profile_pic'] == null ||
                                              user['profile_pic']
                                                  .toString()
                                                  .isEmpty)
                                          ? const Icon(Icons.person)
                                          : null,
                                ),

                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    user['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      240,
                                      207,
                                      170,
                                      0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${user['steps']}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onWaterPressed() async {
    if (treeId == null || userId == null) return;

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
      setState(() {
        isLoading = true;
      });
      final res = await http.post(
        Uri.parse("https://ecoquest.ruputech.com/water_tree.php"),
        body: {
          "uid": userId,
          "amount": "250",
          "linked_id": treeId, // Optional if you track tree-wise
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"]) {
          print("Water added successfully: ${data['message']}");
          // ✅ Auto-refresh tree progress and water
          await fetchTreeGrowth();
          await fetchWaterBalance();
        } else {
          print("Water addition failed: ${data['message']}");
        }
      } else {
        print("Failed to add water: ${res.statusCode}");
      }

      setState(() {
        isLoading = false;
      });
    }

    if (_progress >= 0.99 && !hasJustPlanted) {
      Future.delayed(Duration.zero, () {
        checkTreeFullyGrown();
      });
      setState(() {
        hasJustPlanted = false;
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

  void firstTimeLogin() {
    String inputName = '';
    bool showError = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Plant a New Tree'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/seed.webp', width: 50),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.5,
                    ),
                    child: TextField(
                      onChanged: (value) => inputName = value,
                      decoration: InputDecoration(
                        hintText: 'Enter new tree name',
                        errorText:
                            showError ? 'Tree name cannot be empty!' : null,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (inputName.trim().isEmpty) {
                      setState(() => showError = true);
                      return;
                    }

                    String? userId = await PreferencesHelper.getUserID();
                    if (userId != null && userId.isNotEmpty) {
                      setState(
                        () => isLoading = true,
                      ); // show loading if you implemented
                      final res = await http.post(
                        Uri.parse("https://ecoquest.ruputech.com/add_tree.php"),
                        body: {"uid": userId, "tree_name": inputName.trim()},
                      );
                      final data = jsonDecode(res.body);
                      setState(() => isLoading = false); // hide loading

                      if (data["success"]) {
                        setState(() {
                          treeName = inputName.trim();
                          hasTree = true;
                          isFirstTimeLogin = false;
                          hasJustPlanted = true;
                          _progress = 0.0;
                        });

                        await fetchActiveTreeId(); // ✅ <-- Fetch the new tree ID
                        await fetchTreeGrowth(); // ✅ Safe now, new ID is available
                        await fetchWaterBalance();

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(data["message"])),
                        );
                      }
                    }
                  },

                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> checkUserTreeStatus() async {
    String? userId = await PreferencesHelper.getUserID();
    if (userId == null || userId.isEmpty) return;
    setState(() {
      isLoading = true;
    });
    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_user_status.php"),
      body: {"user_id": userId},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        bool isFirstTime = data["firstTimeLogin"] == 0;
        String tree = data["treeName"] ?? '';

        if (isFirstTime || tree.isEmpty) {
          Future.delayed(Duration.zero, () {
            firstTimeLogin();
          });
        } else {
          setState(() {
            treeName = tree;
            hasTree = true;
          });
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void checkTreeFullyGrown() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("🎉 Congratulations!"),
          content: const Text("Your tree is fully grown."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show next tree seed naming
                firstTimeLogin(); // 👈 reuse the same function
                setState(() {
                  _progress = 0.0;
                  hasTree = false;
                });
              },
              child: const Text("Next"),
            ),
          ],
        );
      },
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
            Stack(
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
                      child: Center(
                        child: Text(
                          treeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                        constraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
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
                          children: [
                            const Text('Water'),
                            StreamBuilder<int>(
                              stream: _waterStreamController.stream,
                              initialData: waterNum,
                              builder: (context, snapshot) {
                                final updatedWater = snapshot.data ?? waterNum;
                                return Text('$updatedWater ml');
                              },
                            ),
                          ],
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
                        constraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        iconSize: 30,
                        icon: Image.asset(
                          'assets/images/achievement.png',
                          width: 64,
                          height: 64,
                        ),
                        onPressed: showAchievementsDialog, //change afterward
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
                        constraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        iconSize: 30,
                        icon: Image.asset(
                          'assets/images/task.png',
                          width: 64,
                          height: 64,
                        ),
                        onPressed: showDailyTaskDialog, //change afterward
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
                        constraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        iconSize: 30,
                        icon: Image.asset(
                          'assets/images/leaderboard.png',
                          width: 64,
                          height: 64,
                        ),
                        onPressed: showLeaderboardDialog, //change afterward
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
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
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
                Text(
                  "Step",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: screenWidth * 0.1),
                StepProgressBarWidget(
                  progress: (_steps / 20000).clamp(0.0, 1.0),
                ),
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
