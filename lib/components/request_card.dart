import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elbeats/screens/request-item/request_item_details_screen.dart';
import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final String claimId;
  final String itemId;
  final Map<String, dynamic> item;
  final Map<String, dynamic> claim;
  final Map<String, dynamic>? userData;

  const RequestCard({
    super.key,
    required this.claimId,
    required this.itemId,
    required this.item,
    required this.claim,
    this.userData,
  });

  Color _statusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green.shade300;
      case "rejected":
        return Colors.red;
      case "cancelled":
        return Colors.red.withOpacity(0.5);
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = claim["status"] ?? "pending";
    final ownerId = claim["ownerID"];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get(),
      builder: (context, snapshot) {
        final userData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};

        final username = userData["username"] ?? "Unknown User";

        final email = userData["email"] ?? "";

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestDetailsScreen(
                  claimId: claimId,
                  itemId: itemId,
                ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
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

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Unknown Item',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          claim['message'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status
                  Container(
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}