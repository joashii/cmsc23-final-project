import 'package:flutter/material.dart';
import 'package:elbeats/screens/account-creation/profile_setup.dart';

class InterestTagsScreen extends StatefulWidget {
  const InterestTagsScreen({super.key});

  @override
  State<InterestTagsScreen> createState() => _InterestTagsScreenState();
}

class _InterestTagsScreenState extends State<InterestTagsScreen> {
  // Typical food categories for a sharing app
  final List<String> _categories = [
    'Vegan',
    'Homecooked',
    'Vegetables',
    'Fruits',
    'Canned Items',
    'Snacks',
    'Dairy and Eggs',
    'Halal',
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
                // 1. Logic to disable the button if no tags are selected
                onPressed: _selectedTags.isEmpty
                    ? null
                    : () {
                        // 2. Optional: Save the data to your Provider before navigating
                        // context.read<UserAuthProvider>().setInterests(_selectedTags.toList());

                        // 3. Navigate to the Role & Location screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSetupScreen(),
                          ),
                        );
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
