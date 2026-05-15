import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth.provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Dietary Tags logic 
  final List<String> dietOptions = ["Vegan", "Home-Cooked", "Raw", "Halal"];
  final List<String> selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Select your Dietary Interests:"),
            ),
            Wrap(
              spacing: 8.0,
              children: dietOptions.map((tag) => FilterChip(
                label: Text(tag),
                selected: selectedTags.contains(tag),
                onSelected: (selected) {
                  setState(() {
                    selected ? selectedTags.add(tag) : selectedTags.remove(tag);
                  });
                },
              )).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await context.read<UserAuthProvider>().signUp(
                  emailController.text.trim(), 
                  passwordController.text.trim()
                );
                // Note: In a full app, you'd save selectedTags to Firestore here!
              },
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}