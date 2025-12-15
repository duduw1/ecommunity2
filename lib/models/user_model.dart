import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final int points;
  final List<String> followers;
  final List<String> following;
  final String accountType; // 'personal' or 'business'
  final double ratingSum; // Soma das notas recebidas
  final int ratingCount; // Número de avaliações recebidas

  User({
    required this.id,
    required this.name,
    required this.email,
    this.points = 0,
    this.followers = const [],
    this.following = const [],
    this.accountType = 'personal',
    this.ratingSum = 0.0,
    this.ratingCount = 0,
  });

  // Getter para a média de reputação (0 a 5)
  double get rating => ratingCount == 0 ? 0.0 : ratingSum / ratingCount;

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      points: data['points'] ?? 0,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      accountType: data['accountType'] ?? 'personal',
      ratingSum: (data['ratingSum'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'points': points,
      'followers': followers,
      'following': following,
      'accountType': accountType,
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
    };
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'email': email,
      'points': points,
      'followers': followers,
      'following': following,
      'accountType': accountType,
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
    });
  }

  factory User.fromJson(String jsonString) {
    Map<String, dynamic> data = jsonDecode(jsonString);
    return User(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      points: data['points'] ?? 0,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      accountType: data['accountType'] ?? 'personal',
      ratingSum: (data['ratingSum'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
    );
  }
}
