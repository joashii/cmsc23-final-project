import 'package:elbeats/api/auth.api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth.provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<String> options = ["Vegan", "Home-Cooked", "Raw", "Halal"];
  List<String> selectedTags = [];

  @override
Widget build(BuildContext context) {
  // Use the newly defined variable[cite: 2, 6]
  final user = context.watch<UserAuthProvider>().userObj; 

  return Scaffold(
    appBar: AppBar(title: const Text("Edit Profile")),
    body: user == null 
      ? const Center(child: CircularProgressIndicator()) 
      : Column(
          children: [
            Text("User ID: ${user.uid}"), //[cite: 5, 6]
            // ... dietary tag UI ...
            ElevatedButton(
              onPressed: () async {
                // Update Firestore using the user's UID
                await FirebaseAuthAPI().updateUserTags(user.uid, selectedTags);
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            )
          ],
        ),
  );
}
}