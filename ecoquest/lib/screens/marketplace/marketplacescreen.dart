import 'package:ecoquest/services/sharedpreferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  String userId = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchMarketplaceItems();
  }

  Future<void> loadUserData() async {
    final uid = await PreferencesHelper.getUserID();
    print("User ID: $uid");
    setState(() {
      userId = uid ?? "";
    });
    if (userId.isEmpty) return;
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

  void showPurchaseDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item['image_url'],
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "RM ${item['cost']}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text("Are you sure you want to purchase this item?"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog

                        try {
                          // 1. Call backend to get Stripe checkout session URL
                          final response = await http.post(
                            Uri.parse(
                              'https://ecoquest.ruputech.com/create_payment_intent.php',
                            ),
                            body: {
                              'title': item['title'],
                              'cost': item['cost'].toString(),
                            },
                          );

                          final data = jsonDecode(response.body);
                          final checkoutUrl = data['url'];

                          print("✅ Got checkout URL: $checkoutUrl");

                          if (checkoutUrl != null &&
                              checkoutUrl.toString().startsWith("https://")) {
                            await launchUrl(Uri.parse(checkoutUrl));
                          } else {
                            showFailureSnackbar("Invalid checkout URL.");
                          }
                        } catch (e) {
                          showFailureSnackbar("Payment failed: $e");
                          print(e);
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showFailureSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ $message"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showSuccessSnackbar(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎉 You’ve successfully purchased \"$itemName\"!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
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
                    return GestureDetector(
                      onTap: () => showPurchaseDialog(item),
                      child: Container(
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
                                          item['image_url']
                                              .toString()
                                              .isNotEmpty)
                                      ? Image.network(
                                        item['image_url'],
                                        fit: BoxFit.contain,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("RM ${item['cost']}"),
                          ],
                        ),
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
