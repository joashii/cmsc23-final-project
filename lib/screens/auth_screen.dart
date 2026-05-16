import 'package:flutter/material.dart';
import 'package:elbeats/components/login_form.dart';
import 'package:elbeats/components/signup_form.dart';
// import 'package:provider/provider.dart';
// import '../provider/auth.provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Forces the content to be at least the height of the screen
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Hug the children
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. Logo
                    const SizedBox(height: 40),
                    Image.asset('assets/branding/logo.png', height: 240),
                    const SizedBox(height: 24),

                    // 2. The Slider (SegmentedButton)
                    SegmentedButton<int>(
                      // THIS LINE REMOVES THE CHECKMARK:
                      showSelectedIcon: false,

                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: colorScheme.primary,
                        selectedForegroundColor: colorScheme.onPrimary,
                        side: BorderSide(color: colorScheme.outline),
                        // Optional: Add some padding to make the buttons feel more substantial
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('Login'),
                          icon: Icon(
                            Icons.login,
                          ), // You can keep or remove these icons too
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Sign Up'),
                          icon: Icon(Icons.person_add),
                        ),
                      ],
                      selected: {_currentIndex},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() => _currentIndex = newSelection.first);
                        _pageController.animateToPage(
                          _currentIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. The Sliding Fields
                    // We need a fixed height for PageView here because it's inside a ScrollView
                    SizedBox(
                      height: 520, // Adjust this based on your Form height
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                        },
                        children: const [LoginForm(), SignupForm()],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
