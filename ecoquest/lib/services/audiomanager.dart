import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioPlayer backgroundPlayer = AudioPlayer();
  static final AudioPlayer clickPlayer = AudioPlayer();

  /// ✅ Play Background Music (Loop)
  static Future<void> playBackgroundMusic() async {
    try {
      await backgroundPlayer.setLoopMode(LoopMode.one); // ✅ Loop music
      await backgroundPlayer.setVolume(1.0);
      await backgroundPlayer.setAsset('assets/sounds/background.mp3');
      await backgroundPlayer.play();
    } catch (e) {
      print("Error playing background music: $e");
    }
  }

  /// ✅ Play Click Sound (No Override)
  static Future<void> playClickSound() async {
    try {
      await clickPlayer.setVolume(1.0);
      await clickPlayer.setAsset('assets/sounds/click.mp3');
      await clickPlayer.play();
    } catch (e) {
      print("Error playing click sound: $e");
    }
  }

  /// ✅ Pause & Resume Background Music
  static void pauseBackgroundMusic() => backgroundPlayer.pause();
  static void stopBackgroundMusic() => backgroundPlayer.stop();
  static void resumeBackgroundMusic() => backgroundPlayer.play();

  /// ✅ Stop & Dispose Audio Players
  static void dispose() {
    backgroundPlayer.dispose();
    clickPlayer.dispose();
  }
}
