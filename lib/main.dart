import 'package:cmsc23_project/screens/selfie_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'provider/auth.provider.dart';

import 'screens/auth_screen.dart';
// import 'screens/signup.dart';
import 'screens/feed.dart';
import 'screens/editProfile.dart';
import 'screens/addPost.dart';

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
      initialRoute: '/',
      routes: {
        '/login': (context) => const AuthScreen(),
        '/feed': (context) => const FoodFeedPage(),
        '/post-item': (context) => const PostItemPage(),
        '/profile': (context) => const ProfilePage(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to user authentication status
    final userStream = context.watch<UserAuthProvider>().userStream;

    return StreamBuilder(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData) {
          return const AuthScreen();
        } else {
          // If logged in, show the feed
          return const FoodFeedPage();
        }
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selfie Verification Test")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: const Text("Selfie Verification"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SelfieVerificationScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}