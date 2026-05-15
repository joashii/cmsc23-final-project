import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth.provider.dart';

import 'package:elbeats/screens/account-creation/select_interests.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  // 1. The GlobalKey identifies the form for validation
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers to retrieve the text values
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
                prefixIcon: Icon(
                  Icons.lock_reset,
                ), // Changed icon to differentiate
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
                      // 1. Create the Auth Account
                      await auth.signUp(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );

                      // 2. Move to Step 2: Interest Tags
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InterestTagsScreen(),
                          ),
                        );
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
