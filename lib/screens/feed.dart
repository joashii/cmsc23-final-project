import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../api/pantry.api.dart';
import '../provider/auth.provider.dart';

class FoodFeedPage extends StatefulWidget {
  const FoodFeedPage({super.key});

  @override
  State<FoodFeedPage> createState() => _FoodFeedPageState();
}

class _FoodFeedPageState extends State<FoodFeedPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<UserAuthProvider>();
      if (auth.isNewRegistration) {
        _showNotificationModal();
        auth.setNewRegistration(false);
      }
    });
  }

  void _showNotificationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.notifications_active,
          color: Theme.of(context).colorScheme.primary,
          size: 40,
        ),
        title: const Text("Stay Updated"),
        content: const Text(
          "Would you like to receive alerts when new food is shared in your area? "
          "You can change this anytime in settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications Enabled!")),
              );
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Community Pantry")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Elbeats Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View & Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                context.read<UserAuthProvider>().signOut();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebasePantryAPI().getAllItems(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading feed"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data?.docs.length ?? 0,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              Timestamp expiryTimestamp = data['expirationDate'];
              DateTime expiryDate = expiryTimestamp.toDate();
              String formattedDate =
                  "${expiryDate.year}-${expiryDate.month}-${expiryDate.day}";

              return ListTile(
                title: Text(data['name']),
                subtitle: Text(
                  "Qty: ${data['quantity']} | Expires: $formattedDate",
                ),
                trailing: data['status'] == 'Available'
                    ? ElevatedButton(
                        onPressed: () async {
                          String docId = snapshot.data!.docs[index].id;
                          await FirebasePantryAPI().updateItemStatus(
                            docId,
                            "Reserved",
                          );
                        },
                        child: const Text("Request"),
                      )
                    : const Text(
                        "Reserved",
                        style: TextStyle(color: Colors.orange),
                      ),
                onLongPress: () async {
                  String docId = snapshot.data!.docs[index].id;
                  await FirebasePantryAPI().deleteFoodItem(docId);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/post-item'),
      ),
    );
  }
}
