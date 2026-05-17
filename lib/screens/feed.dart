import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/pantry.api.dart';
import '../provider/auth.provider.dart';

class FoodFeedPage extends StatefulWidget {
  const FoodFeedPage({super.key});

  @override
  State<FoodFeedPage> createState() => _FoodFeedPageState();
}

class _FoodFeedPageState extends State<FoodFeedPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<UserAuthProvider>();

      if (auth.isNewRegistration) {
        _showNotificationModal();
        auth.setNewRegistration(false);
      }
    });
  }

  void _showNotificationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.notifications_active,
          color: Theme.of(context).colorScheme.primary,
          size: 40,
        ),
        title: const Text("Stay Updated"),
        content: const Text(
          "Would you like to receive alerts when new food is shared in your area?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Maybe Later"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications Enabled!")),
              );
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Community Pantry")),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                "Elbeats Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("View & Edit Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/profile");
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                context.read<UserAuthProvider>().signOut();
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),

              _buildSearchBar(),
              const SizedBox(height: 20),

              _buildCategoryChips(),
              const SizedBox(height: 20),

              _buildRecipeSection(),
              const SizedBox(height: 20),

              _buildCommunitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "SEARCHING FROM",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              "Los Banos, Laguna",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Craving anything?",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      "Fruits & Vegetables",
      "Cooked Meals",
      "Baked Goods",
      "Canned & Pantry",
      "Dairy & Eggs",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(category, style: const TextStyle(fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecipeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Based on Today's Pantry",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text("Recipe ${index + 1}")),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What the Community has to offer",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebasePantryAPI().getAllItems(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Text("No food items available.");
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                final ownerId = data['ownerId'] ?? "";
                final requesterId = data['requestedBy'] ?? "";
                final bool isOwner = currentUserId == ownerId;

                String itemName = data['name'] ?? "Unnamed Item";
                String itemStatus = data['status'] ?? "Available";

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          child: data["imageBase64"] != null
                              ? Image.memory(
                                  base64Decode(data["imageBase64"]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['postType'] ?? "PANTRY ITEM",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                data['shelfLife'] ?? "Fresh",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              const Spacer(),

                              if (isOwner && itemStatus == "Available")
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await FirebasePantryAPI().deleteFoodItem(
                                        doc.id,
                                      );
                                    },
                                    child: const Text("Cancel Post"),
                                  ),
                                )
                              else if (!isOwner && itemStatus == "Available")
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection("food_items")
                                          .doc(doc.id)
                                          .update({
                                            "status": "Pending",
                                            "requestedBy": currentUserId,
                                          });
                                    },
                                    child: const Text("Request"),
                                  ),
                                )
                              else if (isOwner && itemStatus == "Pending")
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await FirebasePantryAPI()
                                          .updateItemStatus(doc.id, "Reserved");
                                    },
                                    child: const Text("Accept Request"),
                                  ),
                                )
                              else if (!isOwner &&
                                  itemStatus == "Pending" &&
                                  requesterId == currentUserId)
                                const Text(
                                  "Waiting for owner approval",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else if (itemStatus == "Reserved")
                                const Text(
                                  "Reserved",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
