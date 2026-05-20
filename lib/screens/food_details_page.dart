import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';

class FoodDetailsPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> foodData;

  const FoodDetailsPage({
    super.key,
    required this.docId,
    required this.foodData,
  });

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final ownerId = widget.foodData['ownerId'];
    final bool isOwner = currentUserId == ownerId;

    final List<dynamic> dietaryTags = widget.foodData['dietaryTags'] ?? [];

    final List<dynamic> requestedUsers = widget.foodData['requestedBy'] ?? [];

    final bool hasRequested = requestedUsers.contains(currentUserId);

    return Scaffold(
      backgroundColor: AppColors.lightScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO IMAGE + BACK BUTTON
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: widget.foodData["imageBase64"] != null
                      ? Image.memory(
                          base64Decode(widget.foodData["imageBase64"]),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                Positioned(
                  top: 50,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // FLOATING DETAILS CARD
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.lightScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ITEM NAME + DELETE BUTTON
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.foodData['name'] ?? "Unnamed Item",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.foodData['category'] ?? "No category",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isOwner)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Post"),
                                    content: const Text(
                                      "Are you sure you want to delete this post?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection("food_items")
                                      .doc(widget.docId)
                                      .delete();

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Los Banos, Laguna",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),

                    const SizedBox(height: 20),

                    // DIETARY TAGS
                    if (dietaryTags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dietaryTags.map((tag) {
                          return Chip(
                            backgroundColor: AppColors.lightMint,
                            label: Text(
                              tag.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    // DESCRIPTION
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.foodData['description'] ??
                          "No description provided",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 24),

                    // SHELF LIFE
                    const Text(
                      "Shelf Life",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.foodData['shelfLife'] ?? "Not specified",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 24),

                    // PREFERRED SETUP
                    const Text(
                      "Preferred Setup",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.foodData['setupMethod'] ?? "Not specified",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 30),

                    // REQUEST BUTTON (NON OWNER)
                    if (!isOwner)
                      SizedBox(
                        width: double.infinity,
                        child: hasRequested
                            ? OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: AppColors.forestGreen,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: null,
                                child: Text(
                                  "Request Sent",
                                  style: TextStyle(
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("food_items")
                                      .doc(widget.docId)
                                      .update({
                                        "status": "Pending",
                                        "requestedBy": FieldValue.arrayUnion([
                                          currentUserId,
                                        ]),
                                      });

                                  setState(() {
                                    widget.foodData["requestedBy"] = [
                                      ...requestedUsers,
                                      currentUserId,
                                    ];
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Request sent successfully!",
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("Send Request"),
                              ),
                      ),

                    const SizedBox(height: 30),

                    // OWNER REQUEST VIEW
                    if (isOwner) ...[
                      const Text(
                        "View Requests",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("food_items")
                            .doc(widget.docId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final updatedData =
                              snapshot.data!.data() as Map<String, dynamic>;

                          final List requesters =
                              updatedData["requestedBy"] ?? [];

                          if (requesters.isEmpty) {
                            return const Text("No requests yet.");
                          }

                          return Column(
                            children: requesters.map<Widget>((requesterId) {
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(requesterId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }

                                  final userData =
                                      userSnapshot.data!.data()
                                          as Map<String, dynamic>;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.sproutGreen,
                                        child: Text(
                                          userData["username"][0].toUpperCase(),
                                        ),
                                      ),
                                      title: Text(
                                        userData["username"] ?? "Unknown User",
                                      ),
                                      subtitle: Text(userData["email"] ?? ""),
                                      trailing: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.forestGreen,
                                        ),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection("food_items")
                                              .doc(widget.docId)
                                              .update({
                                                "status": "Reserved",
                                                "acceptedRequester":
                                                    requesterId,
                                              });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Requester accepted!",
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text("Accept"),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
