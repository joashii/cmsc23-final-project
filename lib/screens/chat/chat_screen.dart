import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      resizeToAvoidBottomInset: true,

      // ================= INPUT BAR =================
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () async {
                    final text = messageController.text.trim();
                    if (text.isEmpty) return;

                    final chatRef = FirebaseFirestore.instance
                        .collection("chats")
                        .doc(chatId);

                    await chatRef.collection("messages").add({
                      "type": "text",
                      "content": text,
                      "sentAt": FieldValue.serverTimestamp(),
                      "senderID": FirebaseAuth.instance.currentUser!.uid,
                    });

                    await chatRef.update({
                      "lastMessage": text,
                      "lastMessageAt": FieldValue.serverTimestamp(),
                    });

                    messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      // ================= MESSAGES =================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .doc(chatId)
            .collection("messages")
            .orderBy("sentAt")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg =
                  messages[index].data() as Map<String, dynamic>;

              final isSystem = msg["type"] == "system";
              final isMe = msg["senderID"] == currentUserId;

              // ================= SYSTEM MESSAGE =================
              if (isSystem) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg["content"] ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              // ================= USER MESSAGE =================
              return Align(
                alignment:
                    isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg["content"] ?? "",
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}