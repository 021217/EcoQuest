import 'package:ecoquest/custom/myAnimation.dart';
import 'package:ecoquest/screens/authentication/signIn.dart';
import 'package:flutter/material.dart';
import 'package:ecoquest/screens/home/home.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ Initialize Firebase
  runApp(const MyApp());
}

final player = AudioPlayer(playerId: 'background'); // ✅ Background music player
final click = AudioPlayer(playerId: 'click'); // ✅ Click sound player

Future<void> playBackgroundMusic() async {
  try {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setPlayerMode(
      PlayerMode.mediaPlayer,
    ); // ✅ Media mode for background music
    await player.setVolume(1.0);
    await player.play(AssetSource('sounds/background.mp3'));
  } catch (e) {
    print("Error playing audio: $e");
  }
}

Future<void> playClickSound() async {
  try {
    await click.setReleaseMode(ReleaseMode.stop);
    await click.setPlayerMode(
      PlayerMode.lowLatency,
    ); // ✅ Low latency for effects
    await click.setVolume(1.0);
    await click.play(AssetSource('sounds/click.mp3'));
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
    playBackgroundMusic(); // ✅ Start playing background music
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.dispose(); // ✅ Properly dispose of player
    click.dispose(); // ✅ Properly dispose of click sound player
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      player.pause(); // ✅ Pause music when app is minimized
    } else if (state == AppLifecycleState.resumed) {
      player.resume(); // ✅ Resume music when app is reopened
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        textTheme: GoogleFonts.quicksandTextTheme(),
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
        Navigator.of(
          context,
        ).push(fadeRoute(SignIn())); // ✅ Use fade transition
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.webp'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EcoQuest',
                  style: GoogleFonts.quicksand(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
                SizedBox(height: 120),
                MyAnimation(
                  text: 'Tap to Start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // ✅ Blinking effect added here
          ),
        ),
      ),
    );
  }
}
