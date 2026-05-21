import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebasePantryAPI {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // Add a new food item and return the reference
  Future<DocumentReference<Map<String, dynamic>>> addFoodItem(Map<String, dynamic> item) async {
    return await db.collection("food_items").add(item);
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

  Future<void> requestItem(String docId, String userId) async {
    await db.collection("food_items").doc(docId).update({
      "status": "Pending",
      "requestedBy": FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> acceptRequest(String docId) async {
    await db.collection("food_items").doc(docId).update({"status": "Reserved"});
  }

  Stream<QuerySnapshot> getUserItems(String userId) {
    return FirebaseFirestore.instance
        .collection('food_items')
        .where('ownerId', isEqualTo: userId)
        .where('status', whereIn: ['Available', 'Reserved', 'Completed'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAvailableItems() {
    return FirebaseFirestore.instance
        .collection('food_items')
        .where('status', whereIn: ['Available', 'Pending'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
