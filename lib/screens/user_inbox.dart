import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:elbeats/api/notification.api.dart';
import 'package:elbeats/screens/food_details_page.dart';

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
                            : Icons.location_on_outlined,
                    color: type == "request_received"
                        ? Colors.orange
                        : type == "request_approved"
                            ? Colors.green
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
    // Mock Data
    final mockChats = [
      {
        "name": "Juana Dela Cruz",
        "lastMsg": "Can I pick up the items at 4 PM?",
        "time": "10m ago",
        "unread": true,
      },
      {
        "name": "Mark Santos",
        "lastMsg": "Thank you so much for the food!",
        "time": "Yesterday",
        "unread": false,
      },
    ];

    return ListView.builder(
      itemCount: mockChats.length,
      itemBuilder: (context, index) {
        final chat = mockChats[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.outlineVariant,
            child: Icon(Icons.person, color: colorScheme.onSurface),
          ),
          title: Text(
            chat['name'] as String,
            style: TextStyle(
              fontWeight: chat['unread'] as bool
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            chat['lastMsg'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat['time'] as String,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              if (chat['unread'] as bool)
                CircleAvatar(radius: 4, backgroundColor: colorScheme.primary),
            ],
          ),
          onTap: () {
            // Navigate to actual chat room screen
          },
        );
      },
    );
  }
}
