import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:ecoquest/services/audiomanager.dart';
import 'package:ecoquest/main.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final ImagePicker _picker = ImagePicker();

  String name = "";
  String profilePic = "";
  bool audioEnabled = true;
  bool notificationEnabled = true;
  String userId = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
    _checkAudioPreference();
  }

  Future<void> loadUserData() async {
    final uid = await PreferencesHelper.getUserID();
    print("User ID: $uid");
    setState(() {
      userId = uid ?? "";
    });
    if (userId.isEmpty) return;

    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_user.php?" + "uid=$userId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          name = data['user']['name'] ?? "";
          profilePic = data['user']['profile_pic'] ?? "";
        });
      }
    }
  }

  void _checkAudioPreference() async {
    bool savedAudioState = await PreferencesHelper.getAudioEnabled();
    setState(() {
      audioEnabled = savedAudioState;
    });
  }

  void _toggleAudio() async {
    bool newAudioState = !audioEnabled;
    await PreferencesHelper.setAudioEnabled(newAudioState);

    if (newAudioState) {
      AudioManager.playBackgroundMusic();
    } else {
      AudioManager.stopBackgroundMusic();
    }

    setState(() {
      audioEnabled = newAudioState;
    });
  }

  Future<void> updateUserData(String key, dynamic value) async {
    await http.post(
      Uri.parse("https://ecoquest.ruputech.com/update_profile.php"),
      body: {'uid': userId, key: value.toString()},
    );
  }

  Future<void> uploadProfilePicture() async {
    setState(() {
      isLoading = true;
    });

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      List<int> imageBytes = await file.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      const String clientId = '76e9648bc192561';
      final url = Uri.parse('https://api.imgur.com/3/image');

      final response = await http.post(
        url,
        headers: {'Authorization': 'Client-ID $clientId'},
        body: {'image': base64Image, 'type': 'base64'},
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final String imageUrl = jsonData['data']['link'];

        await updateUserData("profilePic", imageUrl);
        setState(() => profilePic = imageUrl);
      } else {
        print("Imgur upload failed: ${response.body}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image')));
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> changeNameDialog() async {
    final controller = TextEditingController(text: name);
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Change Name"),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    await updateUserData("name", newName);
                    setState(() => name = newName);
                  }
                  Navigator.pop(context);
                },
                child: Text("Save"),
              ),
            ],
          ),
    );
  }

  void copyUserIdToClipboard() {
    Clipboard.setData(ClipboardData(text: userId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("User ID copied to clipboard")));
  }

  void _logout() async {
    await PreferencesHelper.clearUser();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
      (Route<dynamic> route) => false,
    );
  }

  // 🔁 Build method stays unchanged — UI code reused from previous version
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(182, 140, 96, 1),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 32),
            Text(
              " Profile Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Start from the top
            end: Alignment.bottomCenter, // End at the bottom
            colors: [
              Color.fromRGBO(255, 255, 255, 1), // White (RGB)
              Color.fromRGBO(139, 105, 70, 1), // Tree brown (RGB)
              Color.fromRGBO(139, 105, 70, 1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child:
                isLoading
                    ? CircularProgressIndicator()
                    : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: uploadProfilePicture,
                            child: Container(
                              width: 150, // Width of the square box
                              height: 150, // Height of the square box
                              decoration: BoxDecoration(
                                color:
                                    Colors
                                        .grey[300], // Default background color if no image
                                borderRadius: BorderRadius.circular(
                                  15,
                                ), // Radius of 15 for rounded corners
                                border: Border.all(
                                  color:
                                      Colors
                                          .brown, // Border color for the square box
                                  width: 5, // Width of the border
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(136, 0, 0, 0),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ], // Shadow for dark mode
                                image:
                                    profilePic.isNotEmpty
                                        ? DecorationImage(
                                          image: NetworkImage(
                                            profilePic,
                                          ), // Use profile image if available
                                          fit:
                                              BoxFit
                                                  .cover, // To cover the area of the container
                                        )
                                        : null,
                              ),
                              child:
                                  profilePic.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        size: 50,
                                      ) // Icon to display when no image
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 8,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(136, 0, 0, 0),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ], // Shadow for dark mode
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: changeNameDialog,
                                    icon: Icon(Icons.edit),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(136, 0, 0, 0),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ], // Shadow for dark mode
                            ),
                            child: SwitchListTile(
                              title: Text(
                                "Audio",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              value: audioEnabled,
                              onChanged: (value) {
                                _toggleAudio();
                              },
                              secondary: Icon(Icons.volume_up),
                              activeColor: Color.fromRGBO(
                                34,
                                139,
                                34,
                                1,
                              ), // Tree Green color (RGB)
                              inactiveThumbColor: Color.fromRGBO(
                                139,
                                105,
                                70,
                                1,
                              ), // Tree Green color (RGB)
                              inactiveTrackColor: Color.fromRGBO(
                                169,
                                126,
                                85,
                                1,
                              ), // Tree Green color (RGB)
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(136, 0, 0, 0),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ], // Shadow for dark mode
                            ),
                            child: SwitchListTile(
                              title: Text(
                                "Notification",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              value: notificationEnabled,
                              onChanged: (value) {
                                setState(() => notificationEnabled = value);
                                updateUserData("notificationEnabled", value);
                              },
                              secondary: Icon(Icons.notifications_active),
                              activeColor: Color.fromRGBO(
                                34,
                                139,
                                34,
                                1,
                              ), // Tree Green color (RGB)
                              inactiveThumbColor: Color.fromRGBO(
                                139,
                                105,
                                70,
                                1,
                              ), // Tree Green color (RGB)
                              inactiveTrackColor: Color.fromRGBO(
                                169,
                                126,
                                85,
                                1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(136, 0, 0, 0),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ], // Shadow for dark mode
                            ),
                            child: ListTile(
                              leading: Icon(Icons.link),
                              title: Text(
                                "Social Media",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Icon(Icons.login),
                              onTap:
                                  () => print("Connect to social media tapped"),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () async {
                              // Clear SharedPreferences (e.g., login status, UID, etc.)
                              await PreferencesHelper.clearUser();

                              // Navigate to home screen (or login)
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyApp(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(136, 0, 0, 0),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ], // Shadow for dark mode
                              ),
                              child: ListTile(
                                leading: Icon(Icons.people),
                                title: Text(
                                  "Logout",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: Icon(Icons.logout, color: Colors.red),
                                onTap: () async {
                                  // Clear SharedPreferences (e.g., login status, UID, etc.)
                                  await PreferencesHelper.clearUser();

                                  // Navigate to home screen (or login)
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyApp(),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(136, 0, 0, 0),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ], // Shadow for dark mode
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "ID: $userId",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy),
                                  onPressed: copyUserIdToClipboard,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context); // Close the settings screen
          },
          child: Icon(Icons.cancel, size: 24, color: Colors.white),
          backgroundColor: Color.fromRGBO(182, 140, 96, 1), // Back button color
        ),
      ),
    );
  }
}
