import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthAPI {
  static final FirebaseAuth auth = FirebaseAuth.instance;

  // Monitor auth status changes
  Stream<User?> getUser() => auth.authStateChanges();

  // Sign Up
  // Creates a new Firebase Authentication account using email and password
  // 'rethrow' allows the UI layer to catch errors and display proper messages
  Future<void> signUp(String email, String password) async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(e.code); // Logs Firebase error for debugging
      rethrow;
    }
  }

  // Sign In
  // Logs in an existing user using Firebase Authentication
  // Errors are passed back to the UI for proper handling
  Future<void> signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint(e.code); // Helps identify login issues
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await auth.signOut();
  }

  // Update Profile, needs Auth
  Future<void> updateUserTags(String uid, List<String> tags) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "tags": tags,
    });
  }
}
