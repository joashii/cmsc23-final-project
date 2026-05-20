import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth.provider.dart'; // Adjust path if necessary

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Key for form validation logic
  final _formKey = GlobalKey<FormState>();

  // Controllers to grab the text from the inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Track the loading state of the login request
  bool _isLoading = false;

  // Clean up controllers when the widget is destroyed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              "Good to see you again.",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary, // Forest Green
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ready to see what’s cooking in the community?",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Email Field
            TextFormField(
              controller: _emailController,
              enabled: !_isLoading, // Disable during network request
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                label: Text("Email"),
                border: OutlineInputBorder(),
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
              enabled: !_isLoading, // Disable during network request
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
                // Disable the click handler entirely while loading
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);

                          try {
                            if (!context.mounted) return;
                            // Access your existing AuthProvider
                            final auth = context.read<UserAuthProvider>();

                            await auth.signIn(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );

                            // AuthWrapper automatically reacts to the stream changing.
                          } catch (e) {
                            // Turn off loading spinner if an error happens so they can try again
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }

                            // Show error if login fails (e.g. wrong password)
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: ${e.toString()}"),
                                ),
                              );
                            }
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Login", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8), // Small gap between buttons
            // Forgot Password Prompt
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      // Navigate to a forgot password screen or show a dialog
                      print("Redirect to Forgot Password logic");
                    },
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary, // Harvest Gold
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
