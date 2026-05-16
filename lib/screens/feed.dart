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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location header section
              _buildHeader(),
              const SizedBox(height: 20),

              // Search bar for food cravings/search queries
              _buildSearchBar(),
              const SizedBox(height: 20),

              // Horizontal food category filters
              _buildCategoryChips(),
              const SizedBox(height: 20),

              // Suggested recipes based on pantry items
              _buildRecipeSection(),
              const SizedBox(height: 20),

              // Community food listings from Firestore
              _buildCommunitySection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/post-item'),
      ),
    );
  }

  // Displays user's current location and favorites button
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "SEARCHING FROM",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              "Los Banos, Laguna",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
      ],
    );
  }

  // Search input for food items or cravings
  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Craving anything?",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // Horizontal list of food categories
  Widget _buildCategoryChips() {
    final categories = ["Vegetables", "Rice Meals", "Bread", "Fruits"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(label: Text(category)),
          );
        }).toList(),
      ),
    );
  }

  // Displays recommended recipes section
  Widget _buildRecipeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Based on Today's Pantry",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text("Recipe ${index + 1}")),
              );
            },
          ),
        ),
      ],
    );
  }

  // Fetches and displays community food posts from Firestore
  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What the Community has to offer",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder(
          stream: FirebasePantryAPI().getAllItems(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Text("No food items available.");
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                String itemName = data['name'] ?? "Unnamed Item";
                var quantity = data['quantity'] ?? 1;
                String itemStatus = data['status'] ?? "Available";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.fastfood),
                    title: Text(itemName),
                    subtitle: Text("Qty: $quantity"),

                    trailing: itemStatus == "Available"
                        ? ElevatedButton(
                            onPressed: () async {
                              await FirebasePantryAPI().updateItemStatus(
                                doc.id,
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
                      await FirebasePantryAPI().deleteFoodItem(doc.id);
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
