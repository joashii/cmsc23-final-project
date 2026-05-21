import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elbeats/screens/chat/chat_screen.dart';
import 'package:elbeats/screens/qr/qr_generator_screen.dart';
import 'package:elbeats/screens/qr/qr_scanner_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Data class to hold all parallel-loaded data ───────────────────────────
class _RequestData {
  final Map<String, dynamic> item;
  final Map<String, dynamic> user;

  const _RequestData({required this.item, required this.user});
}

// ─── StatefulWidget to own the TextEditingController ───────────────────────
class RequestDetailsScreen extends StatefulWidget {
  final String claimId;
  final String itemId;

  const RequestDetailsScreen({
    super.key,
    required this.claimId,
    required this.itemId,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  // Owned here so it's never recreated on rebuild
  final _messageController = TextEditingController();

  // Cache the parallel future so it isn't re-fired on stream updates
  late Future<_RequestData> _requestDataFuture;

  final _firestore = FirebaseFirestore.instance;
  final _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _requestDataFuture = _loadRequestData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ── Load item + requester user in parallel ────────────────────────────────
  Future<_RequestData> _loadRequestData() async {
    // Fetch the claim first to get requesterId
    final claimDoc =
        await _firestore.collection("claims").doc(widget.claimId).get();
    final claim = claimDoc.data() as Map<String, dynamic>;
    final requesterId = claim["requesterID"] as String;

    // Then fetch item + user in parallel
    final results = await Future.wait([
      _firestore.collection("food_items").doc(widget.itemId).get(),
      _firestore.collection("users").doc(requesterId).get(),
    ]);

    return _RequestData(
      item: results[0].data() as Map<String, dynamic>,
      user: results[1].data() as Map<String, dynamic>,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Unknown";
    final date = (timestamp as Timestamp).toDate();
    return DateFormat("MMM d, y h:mm a").format(date);
  }

  Future<void> _addSystemMessage({
    required String chatId,
    required String content,
  }) async {
    final chatRef = _firestore.collection("chats").doc(chatId);
    final batch = _firestore.batch();

    final msgRef = chatRef.collection("messages").doc();
    batch.set(msgRef, {
      "type": "system",
      "content": content,
      "sentAt": FieldValue.serverTimestamp(),
      "senderID": _currentUserId,
    });

    batch.update(chatRef, {
      "lastMessage": content,
      "lastMessageAt": FieldValue.serverTimestamp(),
      "lastMessageSenderID": _currentUserId,
    });

    await batch.commit();
  }

  Future<void> _sendMessage(String chatId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatRef = _firestore.collection("chats").doc(chatId);
    final batch = _firestore.batch();

    batch.set(chatRef.collection("messages").doc(), {
      "type": "text",
      "content": text,
      "sentAt": FieldValue.serverTimestamp(),
      "senderID": _currentUserId,
    });

    batch.update(chatRef, {
      "lastMessage": text,
      "lastMessageAt": FieldValue.serverTimestamp(),
      "lastMessageSenderID": _currentUserId,
    });

    await batch.commit();
    _messageController.clear();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  Future<bool> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    Color confirmColor = Colors.green,
    Color cancelColor = Colors.red,
    String confirmText = "Confirm",
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: cancelColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showAcceptanceDialog(
    BuildContext context, {
    required String chatId,
    required Map<String, dynamic> item,
  }) async {
    final formKey = GlobalKey<FormState>();
    final String setupMethod = item["setupMethod"] ?? "Delivery";
    DateTime? selectedDateTime;
    final locationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Schedule Handover"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode (read-only)
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

                  // Date/time picker
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

                      setDialogState(() {
                        selectedDateTime = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute,
                        );
                      });
                    },
                    child: Text(
                      selectedDateTime == null
                          ? "Pick Time"
                          : _formatDate(
                              Timestamp.fromDate(selectedDateTime!)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (setupMethod == "Meetup")
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                          labelText: "Meetup Location"),
                      validator: (v) =>
                          (v == null || v.isEmpty)
                              ? "Location required for meetup"
                              : null,
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                if (selectedDateTime == null) return;
                if (setupMethod == "Meetup" &&
                    locationController.text.isEmpty) return;

                final batch = _firestore.batch();

                batch.update(
                  _firestore.collection("food_items").doc(widget.itemId),
                  {"status": "Reserved"},
                );

                batch.update(
                  _firestore.collection("claims").doc(widget.claimId),
                  {
                    "status": "accepted",
                    "acceptedAt": FieldValue.serverTimestamp(),
                    "scheduledTime":
                        Timestamp.fromDate(selectedDateTime!),
                    "setupMethod": setupMethod,
                    if (setupMethod == "Meetup")
                      "location": locationController.text,
                  },
                );

                await batch.commit();

                await _addSystemMessage(
                  chatId: chatId,
                  content: "Request accepted",
                );

                // Reject other pending claims in parallel-friendly batch
                final otherClaims = await _firestore
                    .collection("claims")
                    .where("itemID", isEqualTo: widget.itemId)
                    .where("status", isEqualTo: "pending")
                    .get();

                final rejectBatch = _firestore.batch();
                for (final doc in otherClaims.docs) {
                  if (doc.id != widget.claimId) {
                    rejectBatch.update(doc.reference, {
                      "status": "rejected",
                      "rejectedAt": FieldValue.serverTimestamp(),
                    });
                  }
                }
                await rejectBatch.commit();

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Confirm",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),
      // Outermost: claim stream (live status updates)
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection("claims")
            .doc(widget.claimId)
            .snapshots(),
        builder: (context, claimSnap) {
          if (!claimSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final claim =
              claimSnap.data!.data() as Map<String, dynamic>;
          final status = claim["status"] ?? "pending";
          final chatId = claim["chatID"] as String;
          final ownerId = claim["ownerID"] as String;
          final requesterId = claim["requesterID"] as String;
          final isOwner = _currentUserId == ownerId;
          final isRequester = _currentUserId == requesterId;

          // Static data loaded once (not re-fetched on stream updates)
          return FutureBuilder<_RequestData>(
            future: _requestDataFuture,
            builder: (context, dataSnap) {
              if (!dataSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final item = dataSnap.data!.item;
              final user = dataSnap.data!.user;

              return _RequestDetailsBody(
                claimId: widget.claimId,
                itemId: widget.itemId,
                claim: claim,
                item: item,
                user: user,
                chatId: chatId,
                status: status,
                isOwner: isOwner,
                isRequester: isRequester,
                currentUserId: _currentUserId,
                messageController: _messageController,
                formatDate: _formatDate,
                statusColor: _statusColor,
                addSystemMessage: _addSystemMessage,
                sendMessage: _sendMessage,
                showConfirmationDialog: _showConfirmationDialog,
                showAcceptanceDialog: (ctx) => _showAcceptanceDialog(
                  ctx,
                  chatId: chatId,
                  item: item,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Body extracted so the chat stream only rebuilds this subtree ───────────
class _RequestDetailsBody extends StatelessWidget {
  final String claimId;
  final String itemId;
  final Map<String, dynamic> claim;
  final Map<String, dynamic> item;
  final Map<String, dynamic> user;
  final String chatId;
  final String status;
  final bool isOwner;
  final bool isRequester;
  final String currentUserId;
  final TextEditingController messageController;
  final String Function(dynamic) formatDate;
  final Color Function(String) statusColor;
  final Future<void> Function({required String chatId, required String content})
      addSystemMessage;
  final Future<void> Function(String chatId) sendMessage;
  final Future<bool> Function(BuildContext,
      {required String title,
      required String message,
      Color confirmColor,
      Color cancelColor,
      String confirmText}) showConfirmationDialog;
  final Future<void> Function(BuildContext) showAcceptanceDialog;

  const _RequestDetailsBody({
    required this.claimId,
    required this.itemId,
    required this.claim,
    required this.item,
    required this.user,
    required this.chatId,
    required this.status,
    required this.isOwner,
    required this.isRequester,
    required this.currentUserId,
    required this.messageController,
    required this.formatDate,
    required this.statusColor,
    required this.addSystemMessage,
    required this.sendMessage,
    required this.showConfirmationDialog,
    required this.showAcceptanceDialog,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final historyItems = [
      {"title": "Requested at", "timestamp": claim["requestedAt"], "color": Colors.green.shade300},
      {"title": "Accepted at",  "timestamp": claim["acceptedAt"],  "color": Colors.green},
      {"title": "Rejected at",  "timestamp": claim["rejectedAt"],  "color": Colors.red},
      {"title": "Cancelled at", "timestamp": claim["cancelledAt"], "color": Colors.red.shade300},
      {"title": "Completed at", "timestamp": claim["completedAt"], "color": Colors.green},
    ].where((e) => e["timestamp"] != null).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Details card ────────────────────────────────────────────────
          _DetailsCard(
            claimId: claimId,
            claim: claim,
            item: item,
            user: user,
            status: status,
            statusColor: statusColor,
            formatDate: formatDate,
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),

          // ── History timeline ────────────────────────────────────────────
          const Text(
            "Request History",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ...List.generate(historyItems.length, (i) {
            final h = historyItems[i];
            final nextColor = i < historyItems.length - 1
                ? historyItems[i + 1]["color"] as Color
                : h["color"] as Color;
            return _HistoryItem(
              title: h["title"] as String,
              timestamp: h["timestamp"],
              color: h["color"] as Color,
              nextColor: nextColor,
              isLast: i == historyItems.length - 1,
              formatDate: formatDate,
            );
          }),

          const SizedBox(height: 20),

          // ── Chat preview (own stream, only this widget rebuilds) ────────
          _ChatPreview(
            chatId: chatId,
            messageController: messageController,
            formatDate: formatDate,
            onSend: () => sendMessage(chatId),
          ),

          const SizedBox(height: 24),

          // ── Actions ─────────────────────────────────────────────────────
          _ActionButtons(
            claimId: claimId,
            itemId: itemId,
            chatId: chatId,
            status: status,
            isOwner: isOwner,
            isRequester: isRequester,
            currentUserId: currentUserId,
            addSystemMessage: addSystemMessage,
            showConfirmationDialog: showConfirmationDialog,
            showAcceptanceDialog: showAcceptanceDialog,
          ),
        ],
      ),
    );
  }
}

// ─── Details card ────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final String claimId;
  final Map<String, dynamic> claim;
  final Map<String, dynamic> item;
  final Map<String, dynamic> user;
  final String status;
  final Color Function(String) statusColor;
  final String Function(dynamic) formatDate;

  const _DetailsCard({
    required this.claimId,
    required this.claim,
    required this.item,
    required this.user,
    required this.status,
    required this.statusColor,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            Text(
              "Request - $claimId",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Food section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item["imageBase64"] != null
                      ? Image.memory(
                          base64Decode(item["imageBase64"]),
                          width: 90, height: 90,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 90, height: 90,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.fastfood),
                        ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["name"] ?? "Unknown Item",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item["description"] ?? "",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "Posted by: ${item["ownerName"] ?? "Unknown"}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),

            Text(
              "Requested by: ${user["username"] ?? "Unknown"}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              claim["requestedAt"] != null
                  ? "Requested At: ${formatDate(claim["requestedAt"])}"
                  : "",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            // Handover details (accepted only)
            if (status == "accepted") ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade300),
              const Text(
                "Handover Details",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Mode: ${claim["setupMethod"] ?? "N/A"}",
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                claim["scheduledTime"] != null
                    ? "Scheduled: ${formatDate(claim["scheduledTime"])}"
                    : "Scheduled: N/A",
                style: const TextStyle(fontSize: 13),
              ),
              if (claim["setupMethod"] == "Meetup") ...[
                const SizedBox(height: 4),
                Text(
                  "Location: ${claim["location"] ?? "N/A"}",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Chat preview with its own isolated stream ───────────────────────────────
class _ChatPreview extends StatelessWidget {
  final String chatId;
  final TextEditingController messageController;
  final String Function(dynamic) formatDate;
  final VoidCallback onSend;

  const _ChatPreview({
    required this.chatId,
    required this.messageController,
    required this.formatDate,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .snapshots(),
      builder: (context, chatSnap) {
        if (!chatSnap.hasData) return const SizedBox.shrink();

        final chat = chatSnap.data!.data() as Map<String, dynamic>;

        return Column(
          children: [
            // Chat link tile
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: chatId)),
              ),
              child: Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(chat["lastMessage"] ?? "No messages yet"),
                  subtitle: Text(
                    chat["lastMessageAt"] != null
                        ? formatDate(chat["lastMessageAt"])
                        : "",
                  ),
                  trailing: const Icon(Icons.chat_bubble_outline),
                ),
              ),
            ),

            // Quick reply input
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Reply...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: onSend,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final String claimId;
  final String itemId;
  final String chatId;
  final String status;
  final bool isOwner;
  final bool isRequester;
  final String currentUserId;
  final Future<void> Function({required String chatId, required String content})
      addSystemMessage;
  final Future<bool> Function(BuildContext,
      {required String title,
      required String message,
      Color confirmColor,
      Color cancelColor,
      String confirmText}) showConfirmationDialog;
  final Future<void> Function(BuildContext) showAcceptanceDialog;

  const _ActionButtons({
    required this.claimId,
    required this.itemId,
    required this.chatId,
    required this.status,
    required this.isOwner,
    required this.isRequester,
    required this.currentUserId,
    required this.addSystemMessage,
    required this.showConfirmationDialog,
    required this.showAcceptanceDialog,
  });

  Future<void> _cancelClaim(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: "Cancel Request",
      message: "Are you sure you want to cancel this request?",
      confirmText: "Yes, Cancel",
      confirmColor: Colors.red,
      cancelColor: Colors.grey,
    );
    if (!confirmed) return;

    await FirebaseFirestore.instance
        .collection("claims")
        .doc(claimId)
        .update({
      "status": "cancelled",
      "cancelledAt": FieldValue.serverTimestamp(),
    });

    await addSystemMessage(chatId: chatId, content: "Request cancelled");
  }

  @override
  Widget build(BuildContext context) {
    if (status == "accepted") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // QR button
          ElevatedButton.icon(
            icon: Icon(isOwner ? Icons.qr_code : Icons.qr_code_scanner),
            label: Text(isOwner ? "Generate QR" : "Scan QR"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isOwner
                    ? QRGeneratorScreen(claimId: claimId, itemId: itemId)
                    : QRScannerScreen(claimId: claimId),
              ),
            ),
          ),

          if (isRequester) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _cancelClaim(context),
              child: const Text("Cancel Request",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      );
    }

    if (status == "pending") {
      if (isOwner) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: "Reject Request",
                    message: "Are you sure you want to reject this request?",
                    confirmText: "Reject",
                    confirmColor: Colors.red,
                    cancelColor: Colors.grey,
                  );
                  if (!confirmed) return;

                  await FirebaseFirestore.instance
                      .collection("claims")
                      .doc(claimId)
                      .update({
                    "status": "rejected",
                    "rejectedAt": FieldValue.serverTimestamp(),
                  });

                  await addSystemMessage(
                      chatId: chatId, content: "Request rejected");
                },
                child: const Text("Reject",
                    style: TextStyle(color: Colors.white)),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => showAcceptanceDialog(context),
                child: const Text("Accept",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      }

      if (isRequester) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _cancelClaim(context),
            child: const Text("Cancel Request",
                style: TextStyle(color: Colors.white)),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}

// ─── Timeline item ────────────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final String title;
  final dynamic timestamp;
  final Color color;
  final Color nextColor;
  final bool isLast;
  final String Function(dynamic) formatDate;

  const _HistoryItem({
    required this.title,
    required this.timestamp,
    required this.color,
    required this.nextColor,
    required this.isLast,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (timestamp == null) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.8),
                          nextColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(timestamp),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
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