import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'api/firebase_todo_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseTodoAPI api = FirebaseTodoAPI();

    api.addTodo({
      "title": "Todo from Flutter",
      "completed": false,
      "id": "user_id",
    });

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Firebase Setup")),
        body: Center(child: Text("Firebase is working")),
      ),
    );
  }
}
