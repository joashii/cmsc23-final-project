import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth.provider.dart';

import 'package:elbeats/screens/account-creation/select_interests.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  // The GlobalKey identifies the form for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers to retrieve the text values
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Padding ensures content isn't flush against screen edges
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Welcome to ElbEats!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary, // Forest Green
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Experience a better way to share food.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 32),

            // Username Field
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                label: Text("Username"),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Username is required";
                }
                if (value.length < 3) {
                  return "Username must be at least 3 characters";
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                label: Text("Email"),
                border: OutlineInputBorder(), // Modern M3 outlined look
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Email is required";
                if (!value.contains('@')) return "Enter a valid email";
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                label: Text("Password"),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Password is required";
                }
                if (value.length < 6) return "Min 6 characters";
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_reset),
                label: Text("Confirm Password"),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please confirm your password";
                }
                if (value != _passwordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
              onChanged: (value) {
                if (_formKey.currentState != null) {
                  _formKey.currentState!.validate();
                }
              },
            ),

            const SizedBox(height: 32),

            // Login Button
            SizedBox(
              width: double.infinity, // Full width button
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary, // Forest Green
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimary, // White
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final auth = context.read<UserAuthProvider>();
                    try {
                      // Create the Auth Account
                      await auth.signUp(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );

                      final user = FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        // Write Firestore doc BEFORE auth stream triggers routing
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(user.uid)
                            .set({
                              "username": _usernameController.text.trim(),
                              "email": _emailController.text.trim(),
                              "uid": user.uid,
                              "isOnboardingComplete": false,
                            });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString(),
                            ), // This will show you exactly why it's failing
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text("Sign Up", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8), // Small gap between buttons
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
