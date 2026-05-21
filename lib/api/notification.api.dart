import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseNotificationAPI {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Barangay Coordinates mapping in Los Baños (latitude, longitude)
  static const Map<String, Map<String, double>> barangayCoordinates = {
    'Anos': {'lat': 14.1813, 'lng': 121.2322},
    'Bagong Silang': {'lat': 14.1300, 'lng': 121.2150},
    'Bambang': {'lat': 14.1880, 'lng': 121.2200},
    'Batong Malake': {'lat': 14.1670, 'lng': 121.2420},
    'Baybayin': {'lat': 14.1860, 'lng': 121.2250},
    'Bayog': {'lat': 14.2000, 'lng': 121.2400},
    'Lalakay': {'lat': 14.1680, 'lng': 121.2050},
    'Maahas': {'lat': 14.1780, 'lng': 121.2620},
    'Malinta': {'lat': 14.1900, 'lng': 121.2500},
    'Mayondon': {'lat': 14.1950, 'lng': 121.2450},
    'Putho-Tuntungin': {'lat': 14.1500, 'lng': 121.2400},
    'San Antonio': {'lat': 14.1700, 'lng': 121.2280},
    'Tadlac': {'lat': 14.1850, 'lng': 121.2100},
    'Timugan': {'lat': 14.1758, 'lng': 121.2228},
  };

  // Calculate distance in kilometers between two barangays in Los Baños
  static double calculateDistance(String b1, String b2) {
    final p1 = barangayCoordinates[b1];
    final p2 = barangayCoordinates[b2];
    if (p1 == null || p2 == null) return 0.0;

    // Simple Euclidean approximation in km for Los Baños
    // 1 degree latitude ~ 111 km
    // 1 degree longitude ~ 111 km * cos(lat)
    // At ~14 degrees N, cos(14 deg) ~ 0.97
    final double dx = (p1['lng']! - p2['lng']!) * 111.0 * 0.97;
    final double dy = (p1['lat']! - p2['lat']!) * 111.0;
    return sqrt(dx * dx + dy * dy);
  }

  // Create a single notification
  static Future<void> sendNotification({
    required String recipientID,
    required String title,
    required String body,
    required String postID,
    required String type,
  }) async {
    try {
      await _db
          .collection("users")
          .doc(recipientID)
          .collection("notifications")
          .add({
        "recipientID": recipientID,
        "title": title,
        "body": body,
        "postID": postID,
        "type": type,
        "unread": true,
        "createdAt": FieldValue.serverTimestamp(),
      });
      debugPrint("Notification successfully sent to $recipientID");
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  // Get real-time stream of notifications for a user
  static Stream<QuerySnapshot> getNotifications(String userID) {
    return _db
        .collection("users")
        .doc(userID)
        .collection("notifications")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Mark notification as read
  static Future<void> markAsRead(String recipientID, String docId) async {
    try {
      await _db
          .collection("users")
          .doc(recipientID)
          .collection("notifications")
          .doc(docId)
          .update({"unread": false});
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  // Trigger notifications for all users within the poster's radius
  static Future<void> triggerNearbyNotifications({
    required String postID,
    required String postName,
    required String posterID,
    required String posterBarangay,
  }) async {
    try {
      final usersSnapshot = await _db
          .collection("users")
          .where("isOnboardingComplete", isEqualTo: true)
          .get();

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final userID = doc.id;

        // Skip the poster themselves
        if (userID == posterID) continue;

        final userBarangay = userData["barangay"] as String?;
        final userRadius = (userData["radius"] as num?)?.toDouble() ?? 2.0;

        if (userBarangay != null) {
          final distance = calculateDistance(posterBarangay, userBarangay);
          if (distance <= userRadius) {
            await sendNotification(
              recipientID: userID,
              title: "New listing nearby!",
              body: "Someone shared '$postName' in $posterBarangay.",
              postID: postID,
              type: "nearby_post",
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error triggering nearby notifications: $e");
    }
  }
}
