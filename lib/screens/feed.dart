import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/pantry.api.dart';
import '../provider/auth.provider.dart';
import 'food_details_page.dart';
import '../api/notification.api.dart';

class FoodFeedPage extends StatefulWidget {
  const FoodFeedPage({super.key});

  @override
  State<FoodFeedPage> createState() => _FoodFeedPageState();
}

class _FoodFeedPageState extends State<FoodFeedPage> {
  Color _getCategoryBgColor(String category) {
    switch (category) {
      case 'Fruits & Vegetables':
        return Colors.green.shade50;
      case 'Cooked Meals':
        return Colors.orange.shade50;
      case 'Baked Goods':
        return Colors.amber.shade50;
      case 'Canned & Pantry':
        return Colors.blue.shade50;
      case 'Dairy & Eggs':
        return Colors.yellow.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category) {
      case 'Fruits & Vegetables':
        return Colors.green.shade800;
      case 'Cooked Meals':
        return Colors.orange.shade900;
      case 'Baked Goods':
        return Colors.amber.shade900;
      case 'Canned & Pantry':
        return Colors.blue.shade800;
      case 'Dairy & Eggs':
        return Colors.yellow.shade900;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(currentUserId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final currentUserBarangay = userData?['barangay'] as String?;
        final currentUserRadius = (userData?['radius'] as num?)?.toDouble() ?? 2.0;

        return Scaffold(
          appBar: null,
          body: SafeArea(
            child: SingleChildScrollView(
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

                    _buildCommunitySection(currentUserBarangay, currentUserRadius),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  Widget _buildCommunitySection(String? currentUserBarangay, double currentUserRadius) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What the Community has to offer",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebasePantryAPI().getAvailableItems(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter items synchronously by radius
            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ownerId = data['ownerId'] ?? "";
              final posterBarangay = data['barangay'] as String? ?? "";

              // Show poster's own post regardless of distance
              if (ownerId == currentUserId) return true;

              if (posterBarangay.isEmpty || currentUserBarangay == null) return false;

              final distance = FirebaseNotificationAPI.calculateDistance(currentUserBarangay, posterBarangay);
              return distance <= currentUserRadius;
            }).toList();

            if (docs.isEmpty) {
              return const Text("No food items available within your radius.");
            }

            return Column(
              children: docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                final ownerId = data['ownerId'] ?? "";
                final bool isOwner = currentUserId == ownerId;
                final posterBarangay = data['barangay'] as String? ?? "";

                String itemName = data['name'] ?? "Unnamed Item";

                double distance = 0.0;
                if (!isOwner && currentUserBarangay != null && posterBarangay.isNotEmpty) {
                  distance = FirebaseNotificationAPI.calculateDistance(currentUserBarangay, posterBarangay);
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FoodDetailsPage(docId: doc.id, foodData: data),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
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
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category tag / badge with color coding
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryBgColor(
                                      data['category'] ?? "Other",
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['category'] ?? "Other",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getCategoryTextColor(
                                        data['category'] ?? "Other",
                                      ),
                                    ),
                                  ),
                                ),

                                const Spacer(flex: 2),

                                // Post Title
                                Text(
                                  itemName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Poster Photo & Details 
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.green.shade100,
                                      child: Text(
                                        (data['ownerName'] as String? ?? "A")
                                                .isNotEmpty
                                            ? (data['ownerName'] as String)[0]
                                                .toUpperCase()
                                            : "A",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            data['ownerName'] ?? "Anonymous User",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          if (isOwner)
                                            const Text(
                                              "Your Post",
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            )
                                          else if (posterBarangay.isNotEmpty)
                                            Text(
                                              "$posterBarangay (${distance.toStringAsFixed(1)} km away)",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
