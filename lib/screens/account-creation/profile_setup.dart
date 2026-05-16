import 'package:flutter/material.dart';
import 'package:elbeats/screens/account-creation/identity_verification.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String? _selectedBarangay;
  double _radius = 2.0; // Default 2km
  Set<String> _role = {'giver'}; // Default role

  final List<String> _barangays = [
    'Anos',
    'Bagong Silang',
    'Bambang',
    'Batong Malake',
    'Baybayin',
    'Bayog',
    'Lalakay',
    'Maahas',
    'Malinta',
    'Mayondon',
    'Putho-Tuntungin',
    'San Antonio',
    'Tadlac',
    'Timugan',
  ];

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How will you use ElbEats?",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Role Selection
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'giver',
                  label: Text('Post Items'),
                  icon: Icon(Icons.file_upload),
                ),
                ButtonSegment(
                  value: 'receiver',
                  label: Text('Get Items'),
                  icon: Icon(Icons.file_download),
                ),
              ],
              selected: _role,
              onSelectionChanged: (newSelection) =>
                  setState(() => _role = newSelection),
            ),

            const SizedBox(height: 40),
            Text(
              "Where are you located?",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Barangay Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Barangay",
              ),
              items: _barangays
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBarangay = val),
            ),

            const SizedBox(height: 32),
            Text(
              "Viable Radius: ${_radius.toStringAsFixed(1)} km",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _radius,
              min: 0.5,
              max: 10.0,
              divisions: 19,
              label: "${_radius.toStringAsFixed(1)} km",
              onChanged: (val) => setState(() => _radius = val),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedBarangay == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IdentityVerificationScreen(),
                          ),
                        );
                      },
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
