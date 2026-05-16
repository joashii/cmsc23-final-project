import 'package:elbeats/screens/feed.dart';
import 'package:elbeats/screens/user_inbox.dart';
import 'package:elbeats/screens/user_profile.dart';
import 'package:flutter/material.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;

  // The pages for each tab
  final List<Widget> _pages = [
    const FoodFeedPage(), // Index 0
    const SizedBox.shrink(), // Index 1 (Placeholder for the "Add" button)
    const NotificationsPage(), // Index 2
    const ProfilePage(), // Index 3
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // If they click the middle "Add" button, show the menu instead of switching tabs
      _showAddPostMenu();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showAddPostMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "What would you like to do?",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.green),
                title: const Text("Share Food (Pantry Post)"),
                subtitle: const Text("Post items from your kitchen for others"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/post-item');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.handshake, color: Colors.orange),
                title: const Text("Make a Request"),
                subtitle: const Text(
                  "Ask the community for something you need",
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/make-request');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
