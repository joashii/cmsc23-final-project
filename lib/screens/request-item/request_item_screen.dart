import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestItemScreen extends StatefulWidget {
  final String itemID;
  final String ownerID;

  const RequestItemScreen({
    super.key,
    required this.itemID,
    required this.ownerID,
  });

  @override
  State<RequestItemScreen> createState() => _RequestItemScreenState();
}

class _RequestItemScreenState extends State<RequestItemScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = false;

  Future<void> submitRequest() async {
    final message = _messageController.text.trim();

    // ✅ Prevent empty message
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message before sending.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('claims').add({
        "itemID": widget.itemID,
        "message": message,
        "ownerID": widget.ownerID,
        "qrVerified": false,
        "requestedAt": Timestamp.now(),
        "requesterID": currentUser!.uid,
        "status": "pending",
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<DocumentSnapshot> getItem() {
    return FirebaseFirestore.instance
        .collection('food_items')
        .doc(widget.itemID)
        .get();
  }

  Future<DocumentSnapshot> getOwner() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.ownerID)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Item")),

      body: FutureBuilder(
        future: Future.wait([getItem(), getOwner()]),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = snapshot.data![0].data() as Map<String, dynamic>;
          final owner = snapshot.data![1].data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── ITEM DETAILS ───
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Unnamed Item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Category: ${item['category'] ?? '-'}"),
                        Text("Post Type: ${item['postType'] ?? '-'}"),
                        Text("Shelf Life: ${item['shelfLife'] ?? '-'}"),
                        Text("Status: ${item['status'] ?? '-'}"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── OWNER NAME ONLY ───
                Text(
                  "Owner: ${owner['username'] ?? owner['email'] ?? 'Unknown'}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                // ─── MESSAGE BOX ───
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Message to Owner",
                    hintText: "Example: When can this be picked up?",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── SUBMIT BUTTON ───
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitRequest,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Send Request"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}