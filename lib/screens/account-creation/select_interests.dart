import 'package:flutter/material.dart';

class InterestTagsScreen extends StatefulWidget {
  const InterestTagsScreen({super.key});

  @override
  State<InterestTagsScreen> createState() => _InterestTagsScreenState();
}

class _InterestTagsScreenState extends State<InterestTagsScreen> {
  // Typical food categories for a sharing app
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Cooked Meals',
    'Baked Goods',
    'Canned Items',
    'Pantry Staples',
    'Dairy & Eggs',
    'Beverages',
    'Snacks',
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
              height: 50,
              child: FilledButton(
                onPressed: _selectedTags.isEmpty
                    ? null // Disable button until at least one tag is picked
                    : () {
                        // TODO: Navigate to Role Selection Screen
                        print("Selected Tags: $_selectedTags");
                      },
                child: const Text("Next"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
