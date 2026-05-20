import 'package:elbeats/components/main_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'provider/auth.provider.dart';

import 'screens/auth_screen.dart';
import 'screens/feed.dart';
import 'screens/user_profile.dart';
import 'screens/user-posts/post_item_page.dart';
import 'screens/account-creation/select_interests.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserAuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elbeats Food Sharing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: AppColors.lightScheme),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.darkScheme,
      ),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),

      routes: {
        '/main': (context) => const MainNav(),
        '/login': (context) => const AuthScreen(),
        '/feed': (context) => const FoodFeedPage(),
        '/post-item': (context) => const PostItemPage(postType: 'PANTRY'),
        '/make-request': (context) => const PostItemPage(postType: 'REQUEST'),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const AuthScreen();
        }

        return OnboardingCheckGate(user: authSnapshot.data!);
      },
    );
  }
}

class OnboardingCheckGate extends StatefulWidget {
  final User user;
  const OnboardingCheckGate({super.key, required this.user});

  @override
  State<OnboardingCheckGate> createState() => _OnboardingCheckGateState();
}

class _OnboardingCheckGateState extends State<OnboardingCheckGate> {
  late Stream<DocumentSnapshot> _userFirestoreStream;

  @override
  void initState() {
    super.initState();
    _initUserStream();
  }

  @override
  void didUpdateWidget(OnboardingCheckGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _initUserStream();
    }
  }

  void _initUserStream() {
    _userFirestoreStream = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userFirestoreStream,
      builder: (context, userSnapshot) {
        // Instead, show the error or provide a retry button.
        if (userSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text("Syncing with database..."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Manually refresh the stream after the token syncs
                      setState(() {
                        _initUserStream();
                      });
                    },
                    child: const Text("Enter App"),
                  ),
                ],
              ),
            ),
          );
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle missing user documents (if you manually created an account in Firebase)
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          // If the doc doesn't exist, route them to onboarding
          return const InterestTagsScreen();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final onboardingComplete = userData["isOnboardingComplete"] ?? false;

        if (!onboardingComplete) {
          return const InterestTagsScreen();
        }

        return const MainNav();
      },
    );
  }
}
