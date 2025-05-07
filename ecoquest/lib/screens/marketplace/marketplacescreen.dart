import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMarketplaceItems();
  }

  Future<void> fetchMarketplaceItems() async {
    final response = await http.get(
      Uri.parse("https://ecoquest.ruputech.com/get_marketplace_items.php"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        setState(() {
          items = List<Map<String, dynamic>>.from(data["items"]);
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 32),
            Text(
              "Marketplace",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(182, 140, 96, 1),
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
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child:
                                (item['image_url'] != null &&
                                        item['image_url'].toString().isNotEmpty)
                                    ? Image.network(
                                      item['image_url'],
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                    )
                                    : const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            item['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("RM ${item['cost']}"),
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
