import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elbeats/screens/qr/qr_generator_screen.dart';
import 'package:elbeats/screens/qr/qr_scanner_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestDetailsScreen extends StatelessWidget {
  final String claimId;
  final String itemId;

  const RequestDetailsScreen({
    super.key,
    required this.claimId,
    required this.itemId,
  });

  Color _statusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "cancelled":
        return Colors.red.withOpacity(0.5);
      default:
        return Colors.orange;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Unknown";

    final date = (timestamp as Timestamp).toDate();

    return DateFormat("MMM d, y h:mm a").format(date);
  }

  Future<void> _showAcceptanceDialog(
    BuildContext context,
    String claimId,
    String itemId,
    Map<String, dynamic> item,
  ) async {
    final formKey = GlobalKey<FormState>();

    final String setupMethod = item["setupMethod"] ?? "Delivery";

    DateTime? selectedDateTime;
    final locationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Schedule Handover"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SHOW MODE (READ ONLY)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Mode: $setupMethod",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // DATE/TIME PICKER
                      ElevatedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            initialDate: DateTime.now(),
                          );

                          if (date == null) return;

                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (time == null) return;

                          setState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        child: Text(
                          selectedDateTime == null
                              ? "Pick Time"
                              : _formatDate(Timestamp.fromDate(selectedDateTime!)),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ONLY FOR MEETUP
                      if (setupMethod == "Meetup")
                        TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: "Meetup Location",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Location required for meetup";
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDateTime == null) return;
                    if (setupMethod == "Meetup" &&
                        locationController.text.isEmpty) return;

                    final firestore = FirebaseFirestore.instance;

                    // UPDATE FOOD ITEM
                    await firestore.collection("food_items").doc(itemId).update({
                      "status": "Reserved",
                    });

                    // ACCEPT CLAIM
                    await firestore.collection("claims").doc(claimId).update({
                      "status": "accepted",
                      "acceptedAt": FieldValue.serverTimestamp(),
                      "scheduledTime": Timestamp.fromDate(selectedDateTime!),
                      "setupMethod": setupMethod,
                      if (setupMethod == "Meetup")
                        "location": locationController.text,
                    });

                    // REJECT OTHERS
                    final otherClaims = await firestore
                        .collection("claims")
                        .where("itemId", isEqualTo: itemId)
                        .where("status", isEqualTo: "pending")
                        .get();

                    final batch = firestore.batch();

                    for (var doc in otherClaims.docs) {
                      if (doc.id != claimId) {
                        batch.update(doc.reference, {
                          "status": "rejected",
                          "rejectedAt": FieldValue.serverTimestamp(),
                        });
                      }
                    }

                    await batch.commit();

                    Navigator.pop(context);
                  },
                  child: const Text("Confirm"),
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
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("claims")
            .doc(claimId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final claim = snapshot.data!.data() as Map<String, dynamic>;
          final requesterId = claim["requesterID"];
          final ownerId = claim["ownerID"];
          final status = claim["status"] ?? "pending";

          final historyItems = [
            {
              "title": "Requested at",
              "timestamp": claim["requestedAt"],
            },
            {
              "title": "Accepted at",
              "timestamp": claim["acceptedAt"],
            },
            {
              "title": "Rejected at",
              "timestamp": claim["rejectedAt"],
            },
            {
              "title": "Cancelled at",
              "timestamp": claim["cancelledAt"],
            },
            {
              "title": "Completed at",
              "timestamp": claim["completedAt"],
            },
          ].where((e) => e["timestamp"] != null).toList();

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("food_items")
                .doc(itemId)
                .get(),
            builder: (context, itemSnap) {
              if (!itemSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final item =
                  itemSnap.data!.data() as Map<String, dynamic>;


              final isOwner = currentUserId == ownerId;
              final isRequester = currentUserId == requesterId;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(requesterId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final user =
                      userSnap.data!.data() as Map<String, dynamic>;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Details
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // STATUS
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                // ================= HEADER =================
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Request - $claimId",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // ================= FOOD SECTION =================
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // FOOD IMAGE
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item["imageBase64"] != null
                                          ? Image.memory(
                                              base64Decode(item["imageBase64"]),
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 90,
                                              height: 90,
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.fastfood),
                                            ),
                                    ),

                                    const SizedBox(width: 12),

                                    // NAME + DESC
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item["name"] ?? "Unknown Item",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          Text(
                                            item["description"] ?? "",
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // ================= POSTER =================
                                Text(
                                  "Posted by: ${item["ownerName"] ?? "Unknown"}",
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),

                                const SizedBox(height: 12),

                                Divider(color: Colors.grey.shade300),

                                const SizedBox(height: 12),

                                // ================= FOOTER =================
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Requested by: ${user["username"] ?? "Unknown"}",
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),

                                    Text(
                                      claim["requestedAt"] != null
                                          ? "Requested At: ${_formatDate(claim["requestedAt"])}"
                                          : "",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                if (status == "accepted") ...[
                                  const SizedBox(height: 12),
                                  Divider(color: Colors.grey.shade300),

                                  const Text(
                                    "Handover Details",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // MODE
                                  Text(
                                    "Mode: ${claim["setupMethod"] ?? "N/A"}",
                                    style: const TextStyle(fontSize: 13),
                                  ),

                                  const SizedBox(height: 4),

                                  // SCHEDULE
                                  Text(
                                    claim["scheduledTime"] != null
                                        ? "Scheduled: ${_formatDate(claim["scheduledTime"])}"
                                        : "Scheduled: N/A",
                                    style: const TextStyle(fontSize: 13),
                                  ),

                                  const SizedBox(height: 4),

                                  // LOCATION (ONLY FOR MEETUP)
                                  if (claim["setupMethod"] == "Meetup")
                                    Text(
                                      "Location: ${claim["location"] ?? "N/A"}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade300),

                        const Text(
                          "Request History",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            historyItems.length,
                            (index) {
                              final item = historyItems[index];

                              return _historyItem(
                                item["title"] as String,
                                item["timestamp"],
                                isLast: index == historyItems.length - 1,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "Message",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              claim["message"] ?? "No message",
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ===================== ACTIONS =====================
                        if (status == "accepted") ...[
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    isOwner
                                        ? Icons.qr_code
                                        : Icons.qr_code_scanner,
                                  ),
                                  label: Text(
                                    isOwner ? "Generate QR" : "Scan QR",
                                  ),
                                  onPressed: () {
                                    if (isOwner) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QRGeneratorScreen(
                                            claimId: claimId,
                                            itemId: itemId,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QRScannerScreen(
                                            claimId: claimId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (status == "pending") ...[
                          // OWNER ACTIONS
                          if (isOwner)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection("claims")
                                          .doc(claimId)
                                          .update({
                                        "status": "rejected",
                                        "rejectedAt":
                                            FieldValue.serverTimestamp(),
                                      });
                                    },
                                    child: const Text(
                                      "Reject",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () async {
                                      await _showAcceptanceDialog(
                                        context,
                                        claimId,
                                        itemId,
                                        item,
                                      );
                                    },
                                    child: const Text(
                                      "Accept",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // REQUESTER ACTIONS
                          if (isRequester)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("claims")
                                      .doc(claimId)
                                      .update({
                                    "status": "cancelled",
                                    "cancelledAt":
                                        FieldValue.serverTimestamp(),
                                  });
                                },
                                child: const Text(
                                  "Cancel Request",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _historyItem(
    String title,
    dynamic timestamp, {
    bool isLast = false,
  }) {
    if (timestamp == null) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIMELINE
          Column(
            children: [
              // DOT
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),

              // LINE
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _formatDate(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}