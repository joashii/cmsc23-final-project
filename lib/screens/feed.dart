import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../api/pantry.api.dart';
import '../provider/auth.provider.dart';

class FoodFeedPage extends StatelessWidget {
  const FoodFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Pantry"),
        // The drawer icon automatically appears if the drawer property is set
      ),
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
                Navigator.pop(context); // Close the drawer first
                Navigator.pushNamed(context, '/profile'); // Navigate to profile
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
