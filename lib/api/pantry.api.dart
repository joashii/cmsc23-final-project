import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebasePantryAPI {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // Add a new food item 
  Future<void> addFoodItem(Map<String, dynamic> item) async {
    await db.collection("food_items").add(item);
  }

  // Update status of existing entry
  Future<void> updateItemStatus(String docId, String status) async {
    await db.collection("food_items").doc(docId).update({"status": status});
  }

  // Get a real-time stream of all items
  Stream<QuerySnapshot> getAllItems() {
    return db.collection("food_items").snapshots();
  }

  // Delete an existing item
  Future<void> deleteFoodItem(String docId) async {
    try {
      await db.collection("food_items").doc(docId).delete();
      debugPrint("Successfully deleted item!");
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }
}