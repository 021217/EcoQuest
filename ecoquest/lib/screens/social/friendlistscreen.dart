import 'dart:convert';
import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<Map<String, dynamic>> friends = [];
  List<Map<String, String>> addfriends = [];
  String userId = '';
  bool friendLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    userId = await PreferencesHelper.getUserID() ?? '';
    setState(() {}); // update UI if needed
    if (userId.isNotEmpty) {
      await fetchFriends(); // only call after userId is ready
    }
  }

  Future<void> fetchFriends() async {
    friendLoading = true;
    setState(() {}); // update UI to show loading state
    final response = await http.post(
      Uri.parse("https://ecoquest.ruputech.com/get_friends.php"),
      body: {"user_id": userId},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          friends = List<Map<String, dynamic>>.from(data['friends']);
        });
      }
    } else {
      print("Failed to fetch friends");
    }
    friendLoading = false;
    setState(() {}); // update UI after fetching friends
  }

  Future<void> showPendingRequestsDialog() async {
    final userId = await PreferencesHelper.getUserID();
    List<Map<String, dynamic>> pendingRequests = [];
    bool isLoading = true;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              // Fetch requests once
              if (isLoading) {
                http
                    .post(
                      Uri.parse(
                        "https://ecoquest.ruputech.com/get_pending_requests.php",
                      ),
                      body: {"user2": userId},
                    )
                    .then((response) {
                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        if (data["success"]) {
                          setState(() {
                            pendingRequests = List<Map<String, dynamic>>.from(
                              data["requests"],
                            );
                            isLoading = false;
                          });
                        } else {
                          setState(() => isLoading = false);
                        }
                      } else {
                        setState(() => isLoading = false);
                      }
                    });
              }

              return AlertDialog(
                title: const Center(
                  child: Text(
                    "Pending Friend Requests",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (pendingRequests.isEmpty)
                      const Text("No pending friend requests.")
                    else
                      SizedBox(
                        width: double.maxFinite,
                        height: 300,
                        child: ListView.builder(
                          itemCount: pendingRequests.length,
                          itemBuilder: (context, index) {
                            final user = pendingRequests[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      user['profile_pic'].isNotEmpty
                                          ? NetworkImage(user['profile_pic'])
                                          : null,
                                  child:
                                      user['profile_pic'].isEmpty
                                          ? const Icon(Icons.person)
                                          : null,
                                ),
                                title: Text(user['name']),
                                subtitle: Text("UID: ${user['id']}"),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'accept') {
                                      final res = await http.post(
                                        Uri.parse(
                                          "https://ecoquest.ruputech.com/respond_request.php",
                                        ),
                                        body: {
                                          "user1": user['id'],
                                          "user2": userId,
                                          "action": "accept",
                                        },
                                      );
                                      if (res.statusCode == 200) {
                                        fetchFriends(); // Refresh friends list
                                        setState(() {
                                          pendingRequests.removeAt(index);
                                        });
                                      }
                                    } else if (value == 'cancel') {
                                      final res = await http.post(
                                        Uri.parse(
                                          "https://ecoquest.ruputech.com/respond_request.php",
                                        ),
                                        body: {
                                          "user1": user["id"],
                                          "user2": userId,
                                          "action": "cancel",
                                        },
                                      );
                                      if (res.statusCode == 200) {
                                        setState(() {
                                          pendingRequests.removeAt(index);
                                        });
                                      }
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'accept',
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 8),
                                              Text("Accept"),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'cancel',
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text("Reject"),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> addFriendDialog() async {
    final TextEditingController _controller = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _searchUsers() async {
              String query = _controller.text.trim();
              if (query.isEmpty) return;

              setState(() => isLoading = true);

              final response = await http.post(
                Uri.parse("https://ecoquest.ruputech.com/get_user_list.php"),
                body: {"query": query, "id": userId},
              );

              setState(() => isLoading = false);

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                if (data["success"]) {
                  setState(() {
                    searchResults = List<Map<String, dynamic>>.from(
                      data["users"],
                    );
                  });
                } else {
                  setState(() => searchResults = []);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("User not found.")));
                }
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Server error.")));
              }
            }

            return AlertDialog(
              contentPadding: EdgeInsets.all(16),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Add Friend",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Enter UID or Name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: _searchUsers,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (searchResults.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      user["profile_pic"] != null &&
                                              user["profile_pic"]
                                                  .toString()
                                                  .isNotEmpty
                                          ? NetworkImage(user["profile_pic"])
                                          : null,
                                  child:
                                      user["profile_pic"] == null ||
                                              user["profile_pic"]
                                                  .toString()
                                                  .isEmpty
                                          ? Icon(Icons.person)
                                          : null,
                                ),
                                title: Text(user["name"]),
                                subtitle: Text("UID: ${user["id"]}"),
                                trailing: IconButton(
                                  icon: Icon(Icons.person_add),
                                  onPressed: () async {
                                    final response = await http.post(
                                      Uri.parse(
                                        "https://ecoquest.ruputech.com/send_friend_request.php",
                                      ),
                                      body: {
                                        "user1": userId,
                                        "user2": user["id"],
                                      },
                                    );

                                    final result = jsonDecode(response.body);
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text("Info"),
                                            content: Text(result["message"]),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text("OK"),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Text("No users found."),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
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
            Icon(Icons.people, size: 32),
            Text(
              " Social",
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Number of friends: ${friends.length}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notification_important),
                        onPressed: showPendingRequestsDialog,
                      ),
                      IconButton(
                        icon: Icon(Icons.person_add),
                        onPressed: addFriendDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  friendLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 5),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      friend["profile_pic"] != null &&
                                              friend["profile_pic"] != ""
                                          ? NetworkImage(friend["profile_pic"])
                                          : null,
                                  backgroundColor: Colors.blueAccent,
                                  child:
                                      friend["profile_pic"] == null ||
                                              friend["profile_pic"] == ""
                                          ? Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    friend["name"],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'remove') {
                                      final res = await http.post(
                                        Uri.parse(
                                          "https://ecoquest.ruputech.com/remove_friend.php",
                                        ),
                                        body: {
                                          "user1": userId,
                                          "user2":
                                              friend["id"], // or user["id"]
                                        },
                                      );
                                      if (res.statusCode == 200) {
                                        final data = jsonDecode(res.body);
                                        if (data["success"]) {
                                          setState(() {
                                            friends.removeAt(index);
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Friend removed"),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  offset: Offset(0, 40),
                                  icon: Icon(Icons.more_vert),
                                  itemBuilder:
                                      (BuildContext context) => [
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Remove Friend'),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
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
