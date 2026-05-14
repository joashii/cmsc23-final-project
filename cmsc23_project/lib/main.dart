import 'package:cmsc23_project/api/firebase_todo_api.dart';
import 'package:cmsc23_project/screens/editProfile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'provider/auth.provider.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/feed.dart';
import 'screens/addPost.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    FirebaseTodoAPI api = FirebaseTodoAPI();

    api.addTodo({
      "title": "Todo from Flutter",
      "completed": false,
      "id": "user_id",
    });

    return MaterialApp(
      title: 'Elbeats Food Sharing',
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
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
          return const LoginPage();
        } else {
          // If logged in, show the feed
          return const FoodFeedPage();
        }
      },
    );
  }
}
