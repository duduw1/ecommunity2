import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id; // The document ID
  final String name;
  final String email;
  final String password;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // A factory constructor to create a User from a Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'],
    );
  }

  // A method to convert a User object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'password': password};
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    });
  }

  // 2. Factory to create a User object from a JSON string
  factory User.fromJson(String jsonString) {
    Map<String, dynamic> data = jsonDecode(jsonString);
    return User(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      password: data['password'],
    );
  }

}
