import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api/auth.api.dart';

class UserAuthProvider with ChangeNotifier {
  late FirebaseAuthAPI authService;
  late Stream<User?> uStream;
  User? userObj;

  UserAuthProvider() {
    authService = FirebaseAuthAPI();
    uStream = authService.getUser();
    
    // Listen to the stream and update userObj
    uStream.listen((User? user) {
      userObj = user;
      notifyListeners();
    });
  }

  Stream<User?> get userStream => uStream;
  User? get currentUser => userObj;

  Future<void> signIn(String email, String password) async {
    await authService.signIn(email, password); 
    notifyListeners(); 
  }

  Future<void> signUp(String email, String password) async {
    await authService.signUp(email, password); 
    notifyListeners(); 
  }

  Future<void> signOut() async {
    await authService.signOut(); 
    notifyListeners(); 
  } 
}