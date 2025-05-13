import 'package:ecoquest/custom/myAnimation.dart';
import 'package:ecoquest/screens/authentication/authchecker.dart';
import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ecoquest/services/audiomanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

bool isAudioEnabled = true; // ✅ Global variable for audio preference

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAudioPreference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioManager.dispose(); // ✅ Properly dispose audio players
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AudioManager.pauseBackgroundMusic(); // ✅ Pause when app is minimized
    } else if (state == AppLifecycleState.resumed) {
      _checkAudioPreference();
      if (isAudioEnabled) {
        AudioManager.resumeBackgroundMusic(); // ✅ Resume when app is reopened
      }
    }
  }

  void _checkAudioPreference() async {
    bool savedAudioState =
        await PreferencesHelper.getAudioEnabled(); // ✅ Get stored preference

    setState(() {
      // ✅ Triggers UI rebuild after getting the stored value
      isAudioEnabled = savedAudioState;
    });
    print(isAudioEnabled); // ✅ Debugging line
    if (savedAudioState) {
      AudioManager.playBackgroundMusic(); // ✅ Play only if enabled
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await AudioManager.playClickSound(); // ✅ Plays sound on every tap globally
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EcoQuest',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          textTheme: GoogleFonts.quicksandTextTheme(),
        ),
        home: const PressToEnterScreen(),
      ),
    );
  }
}

class PressToEnterScreen extends StatefulWidget {
  const PressToEnterScreen({super.key});

  @override
  State<PressToEnterScreen> createState() => _PressToEnterScreenState();
}

class _PressToEnterScreenState extends State<PressToEnterScreen> {
  bool isAudioEnabled = true; // ✅ Move state variable inside widget

  @override
  void initState() {
    super.initState();
    _checkAudioPreference(); // ✅ Check audio state on screen load
  }

  void _checkAudioPreference() async {
    bool savedAudioState = await PreferencesHelper.getAudioEnabled();
    setState(() {
      isAudioEnabled = savedAudioState; // ✅ Update UI with stored value
    });
    print("Loaded Audio Preference: $isAudioEnabled");
  }

  void _toggleAudio() async {
    bool newAudioState = !isAudioEnabled;
    await PreferencesHelper.setAudioEnabled(newAudioState);

    if (newAudioState) {
      AudioManager.playBackgroundMusic();
    } else {
      AudioManager.stopBackgroundMusic();
    }

    setState(() {
      isAudioEnabled = newAudioState; // ✅ Update UI when toggling
    });

    print("Audio toggled: ${newAudioState ? 'ON' : 'OFF'}");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioManager.playClickSound();
        Navigator.of(context).push(fadeRoute(AuthChecker()));
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ✅ Background Image
            Container(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Bottom Right Audio Toggle Icon
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: _toggleAudio,
                child: Icon(
                  isAudioEnabled
                      ? Icons.music_note_sharp
                      : Icons.music_off_sharp,
                  size: 40,
                  color: Colors.brown[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
