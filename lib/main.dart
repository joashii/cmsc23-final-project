import 'package:elbeats/components/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'provider/auth.provider.dart';

import 'screens/auth_screen.dart';
// import 'screens/signup.dart';
import 'screens/feed.dart';
import 'screens/user_profile.dart';
import 'screens/addPost.dart';

import 'theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase failed to initialize.
    // App will still launch; auth-dependent features will be unavailable.
    debugPrint('Firebase initialization failed: $e');
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
        '/main': (context) => const MainNav(),
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
    // Skip login/signup
    return const ProfilePage();
  }
}
