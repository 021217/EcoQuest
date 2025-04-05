import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecoquest/main.dart';
import 'package:ecoquest/screens/authentication/signIn.dart';
import 'package:ecoquest/services/audiomanager.dart';
import 'package:ecoquest/services/auth.dart';
import 'package:ecoquest/services/permissionhelper.dart';
import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String name = "";
  String profilePic = "";
  bool audioEnabled = true;
  bool notificationEnabled = true;
  String userId = "";
  bool isLoading = false; // ✅ Loading state for image upload

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _checkAudioPreference();
  }

  Future<void> fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot =
          await _firestore.collection("users").doc(user.uid).get();
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        name = data["name"] ?? "";
        profilePic = data["profilePic"] ?? "";
        userId = user.uid;
      });
    }
  }

  void _checkAudioPreference() async {
    bool savedAudioState = await PreferencesHelper.getAudioEnabled();
    setState(() {
      audioEnabled = savedAudioState; // ✅ Update UI with stored value
    });
    print("Loaded Audio Preference: $audioEnabled");
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
      audioEnabled = newAudioState; // ✅ Update UI when toggling
    });

    print("Audio toggled: ${newAudioState ? 'ON' : 'OFF'}");
  }

  Future<void> updateUserData(String key, dynamic value) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection("users").doc(user.uid).update({key: value});
    }
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

      const String clientId =
          '76e9648bc192561'; // Replace with your actual Imgur Client ID
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
                onPressed: () {
                  Navigator.pop(context);
                },
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
                              await AuthService()
                                  .signOut(); // Sign out the user
                              // Navigate to SignIn screen and remove all previous routes from the stack
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyApp(),
                                ), // Push SignIn screen
                                (Route<dynamic> route) =>
                                    false, // Remove all previous routes
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
                                  await AuthService()
                                      .signOut(); // Sign out the user
                                  // Navigate to SignIn screen and remove all previous routes from the stack
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyApp(),
                                    ), // Push SignIn screen
                                    (Route<dynamic> route) =>
                                        false, // Remove all previous routes
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
