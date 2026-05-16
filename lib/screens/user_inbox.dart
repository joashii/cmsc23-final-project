import 'package:flutter/material.dart';

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

  // Notification Builder
  Widget _buildNotificationsList(ColorScheme colorScheme) {
    // Mock Data
    final mockNotifs = [
      {
        "title": "New listing nearby!",
        "body": "Someone shared 'Fresh Mangoes' in Batong Malake.",
        "time": "2m ago",
        "unread": true,
      },
      {
        "title": "Request Accepted",
        "body": "Your request for 'Sourdough Bread' was approved.",
        "time": "1h ago",
        "unread": false,
      },
    ];

    return ListView.builder(
      itemCount: mockNotifs.length,
      itemBuilder: (context, index) {
        final notif = mockNotifs[index];
        return Container(
          color: notif['unread'] as bool
              ? colorScheme.primaryContainer.withValues(alpha: 0.2)
              : Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(Icons.notifications, color: colorScheme.secondary),
            ),
            title: Text(
              notif['title'] as String,
              style: TextStyle(
                fontWeight: notif['unread'] as bool
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(notif['body'] as String),
            trailing: Text(
              notif['time'] as String,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              // Handle notification click
            },
          ),
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
