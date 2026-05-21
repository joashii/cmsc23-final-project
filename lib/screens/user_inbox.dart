import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:elbeats/api/notification.api.dart';
import 'package:elbeats/screens/food_details_page.dart';
import 'package:elbeats/screens/chat/chat_screen.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Inbox"),
          centerTitle: false,
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: "Notifications"),
              Tab(text: "Messages"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationsList(colorScheme),
            _buildMessagesList(colorScheme),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      return DateFormat("MMM d").format(date);
    }
  }

  // Notification Builder
  Widget _buildNotificationsList(ColorScheme colorScheme) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text("Please log in to view notifications."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseNotificationAPI.getNotifications(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading notifications: ${snapshot.error}"),
          );
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  size: 64,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  "No notifications yet",
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final notif = doc.data() as Map<String, dynamic>;
            final String title = notif['title'] ?? '';
            final String body = notif['body'] ?? '';
            final String type = notif['type'] ?? '';
            final String postID = notif['postID'] ?? '';
            final bool unread = notif['unread'] ?? false;
            final Timestamp? timeStamp = notif['createdAt'] as Timestamp?;

            return Container(
              color: unread
                  ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                  : Colors.transparent,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: unread
                      ? colorScheme.primaryContainer
                      : colorScheme.outlineVariant,
                  child: Icon(
                    type == "request_received"
                        ? Icons.receipt_long_outlined
                        : type == "request_approved"
                            ? Icons.check_circle_outline
                            : type == "request_sent"
                                ? Icons.outbox_outlined
                                : Icons.location_on_outlined,
                    color: type == "request_received"
                        ? Colors.orange
                        : type == "request_approved"
                            ? Colors.green
                            : type == "request_sent"
                                ? Colors.blue
                                : colorScheme.primary,
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(body),
                trailing: Text(
                  _formatTime(timeStamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () async {
                  // Mark notification as read
                  if (unread) {
                    await FirebaseNotificationAPI.markAsRead(currentUserId, doc.id);
                  }

                  if (postID.isNotEmpty) {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      final foodDoc = await FirebaseFirestore.instance
                          .collection("food_items")
                          .doc(postID)
                          .get();

                      if (context.mounted) {
                        Navigator.pop(context); // Dismiss loading
                      }

                      if (foodDoc.exists && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodDetailsPage(
                              docId: postID,
                              foodData: foodDoc.data()!,
                            ),
                          ),
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("This post is no longer available."),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Dismiss loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error opening post: $e")),
                        );
                      }
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // Message Preview Builder
  Widget _buildMessagesList(ColorScheme colorScheme) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text("Please log in to view messages."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("participants", arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Error loading messages: ${snapshot.error}"),
            ),
          );
        }

        final chatDocs = snapshot.data?.docs ?? [];

        // Sort chats by lastMessageAt descending client-side
        final sortedDocs = List<QueryDocumentSnapshot>.from(chatDocs);
        sortedDocs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = dataA['lastMessageAt'] as Timestamp?;
          final timeB = dataB['lastMessageAt'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        if (sortedDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  "No messages yet",
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            return _ChatListTile(
              chatId: doc.id,
              chatData: doc.data() as Map<String, dynamic>,
              currentUserId: currentUserId,
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> chatData;
  final String currentUserId;
  final ColorScheme colorScheme;

  const _ChatListTile({
    required this.chatId,
    required this.chatData,
    required this.currentUserId,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => "");
    final postId = chatData['postID'] ?? "";

    final lastMessage = chatData['lastMessage'] ?? "No messages yet";
    final lastMessageAt = chatData['lastMessageAt'] as Timestamp?;
    final lastSeenMap = Map<String, dynamic>.from(chatData['lastSeen'] ?? {});
    final myLastSeen = lastSeenMap[currentUserId] as Timestamp?;

    // Check if unread (if last message sender is not currentUserId and last message is after myLastSeen)
    final lastMessageSenderID = chatData['lastMessageSenderID'] as String?;
    bool isUnread = false;
    if (lastMessageSenderID != null && lastMessageSenderID != currentUserId) {
      if (myLastSeen == null) {
        isUnread = true;
      } else if (lastMessageAt != null && lastMessageAt.toDate().isAfter(myLastSeen.toDate())) {
        isUnread = true;
      }
    }

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
        FirebaseFirestore.instance.collection("food_items").doc(postId).get(),
      ]),
      builder: (context, snapshot) {
        String displayName = "Loading...";
        String postTitle = "Loading...";
        String? avatarLetter;

        if (snapshot.hasData) {
          final userSnap = snapshot.data![0];
          final foodSnap = snapshot.data![1];

          if (userSnap.exists) {
            final userData = userSnap.data() as Map<String, dynamic>?;
            displayName = userData?['username'] ?? userData?['email'] ?? "User";
            if (displayName.isNotEmpty) {
              avatarLetter = displayName[0].toUpperCase();
            }
          }

          if (foodSnap.exists) {
            final foodData = foodSnap.data() as Map<String, dynamic>?;
            postTitle = foodData?['name'] ?? "Unnamed Post";
          } else {
            postTitle = "Deleted Post";
          }
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isUnread ? colorScheme.primaryContainer : colorScheme.outlineVariant,
            child: Text(
              avatarLetter ?? "?",
              style: TextStyle(
                color: isUnread ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            "$displayName : $postTitle",
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              color: isUnread ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(lastMessageAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isUnread ? colorScheme.primary : Colors.grey.shade600,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 6),
              if (isUnread)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "New",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(chatId: chatId),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      return DateFormat("MMM d").format(date);
    }
  }
}
