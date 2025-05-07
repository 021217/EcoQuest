import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EcoTipsScreen extends StatefulWidget {
  const EcoTipsScreen({super.key});

  @override
  State<EcoTipsScreen> createState() => _EcoTipsScreenState();
}

class _EcoTipsScreenState extends State<EcoTipsScreen> {
  List<Map<String, dynamic>> tips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTips();
  }

  Future<void> fetchTips() async {
    final response = await http.get(
      Uri.parse("https://ecoquest.ruputech.com/get_tips.php"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          tips = List<Map<String, dynamic>>.from(data["tips"]);
          isLoading = false;
        });
      }
    }
  }

  void showTipDialog(String title, String content, String? imageUrl) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: title,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image:
                          imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                              : null,
                      color: Colors.grey[300],
                    ),
                    child:
                        imageUrl == null || imageUrl.isEmpty
                            ? const Icon(Icons.image, size: 40)
                            : null,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          child: Text(
                            content,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 32),
            Text(
              "Eco Tips",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(182, 140, 96, 1),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
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
                child: ListView.builder(
                  itemCount: tips.length,
                  itemBuilder: (context, index) {
                    final tip = tips[index];
                    return Container(
                      key: ValueKey(tip['title']),
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.brown[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: tip['title'],
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  tip['img'] != null && tip['img'] != ""
                                      ? NetworkImage(tip['img'])
                                      : null,
                              backgroundColor: Colors.grey[300],
                              child:
                                  tip['img'] == null || tip['img'] == ""
                                      ? const Icon(Icons.image)
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              tip['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                () => showTipDialog(
                                  tip['title'],
                                  tip['content'],
                                  tip['img'],
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                182,
                                140,
                                96,
                                1,
                              ),
                            ),
                            child: const Text(
                              "Learn",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
