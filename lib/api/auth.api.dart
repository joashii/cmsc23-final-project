import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthAPI {
  static final FirebaseAuth auth = FirebaseAuth.instance;

  // Monitor auth status changes
  Stream<User?> getUser() => auth.authStateChanges();

  // Sign Up 
  Future<void> signUp(String email, String password) async {
    try {
      await auth.createUserWithEmailAndPassword(email: email, password: password); 
    } on FirebaseAuthException catch (e) {
      debugPrint(e.code); 
    }
  }

  // Sign In
  Future<void> signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password); 
    } on FirebaseAuthException catch (e) {
      debugPrint(e.code); 
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await auth.signOut();
  }

  // Update Profile, needs Auth
  Future<void> updateUserTags(String uid, List<String> tags) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({"tags": tags});
  }
}