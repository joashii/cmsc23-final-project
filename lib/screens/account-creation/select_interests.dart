import 'package:flutter/material.dart';
import 'package:elbeats/screens/account-creation/profile_setup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:elbeats/provider/auth.provider.dart';

class InterestTagsScreen extends StatefulWidget {
  const InterestTagsScreen({super.key});

  @override
  State<InterestTagsScreen> createState() => _InterestTagsScreenState();
}

class _InterestTagsScreenState extends State<InterestTagsScreen> {
  final List<String> _categories = [
    'Fruits & Vegetables',
    'Cooked Meals',
    'Baked Goods',
    'Canned & Pantry',
    'Dairy & Eggs',
  ];

  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Preferences"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What are you looking for?",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select categories that interest you to help us personalize your feed.",
            ),
            const SizedBox(height: 32),

            // The Tags Section
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _categories.map((category) {
                final isSelected = _selectedTags.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  showCheckmark: false, // Prevents layout shifting when checked
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(category);
                      } else {
                        _selectedTags.remove(category);
                      }
                    });
                  },
                  // Styling with your brand colors
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Navigation Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Disable the button if no tags are selected
                onPressed: _selectedTags.isEmpty
                    ? null
                    : () async {
                        final user = Provider.of<UserAuthProvider>(
                          context,
                          listen: false,
                        ).currentUser;

                        if (user != null) {
                          try {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(user.uid)
                                .update({
                              "interests": _selectedTags.toList(),
                            });
                          } catch (e) {
                            debugPrint("Error saving interests: $e");
                          }
                        }

                        if (context.mounted) {
                          // Navigate to the Role & Location screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileSetupScreen(),
                            ),
                          );
                        }
                      },
                child: const Text("Continue"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
