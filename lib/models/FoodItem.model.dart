import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  String? id;
  String name;
  int quantity;
  DateTime expirationDate;
  String? imageUrl;

  FoodItem({this.id, required this.name, required this.quantity, required this.expirationDate, this.imageUrl});

  // Convert for Firestore
  Map<String, dynamic> toJson() => {
    "name": name,
    "quantity": quantity,
    "expirationDate": expirationDate,
    "imageUrl": imageUrl,
  };

  // Create from Firestore 
  factory FoodItem.fromJson(Map<String, dynamic> json, String id) {
    return FoodItem(
      id: id,
      name: json['name'],
      quantity: json['quantity'],
      // Handle both String (from local) and Timestamp (from Firestore)
      expirationDate: (json['expirationDate'] as Timestamp).toDate(), 
      imageUrl: json['imageUrl'],
    );
  }
}