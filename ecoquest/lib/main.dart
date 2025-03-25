import 'package:flutter/material.dart';
import 'package:ecoquest/screens/home/home.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

final player = AudioPlayer();

Future<void> playBackgroundMusic() async {
  try {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(1.0);
    await player.play(AssetSource('sounds/background.mp3'));
  } catch (e) {
    print("Error playing audio: $e");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    playBackgroundMusic(); // Start playing music when app launches
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      player.pause(); // Pause music when app is minimized
    } else if (state == AppLifecycleState.resumed) {
      player.resume(); // Resume music when app is reopened
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PressToEnterScreen(),
    );
  }
}

class PressToEnterScreen extends StatelessWidget {
  const PressToEnterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      },
      child: Scaffold(
        body: Center(
          child: Text(
            'Press anywhere to Enter',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
