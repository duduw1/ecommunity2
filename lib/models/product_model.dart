// lib/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String location;
  final Timestamp postedAt;
  final String donatorId;
  final String donatorName;
  final String status;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.postedAt,
    required this.donatorId,
    required this.donatorName,
    required this.status,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? 'Sem Título',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'Geral',
      location: data['location'] ?? 'Não informado',
      postedAt: data['postedAt'] ?? Timestamp.now(),
      donatorId: data['donatorId'] ?? '',
      donatorName: data['donatorName'] ?? 'Anônimo',
      status: data['status'] ?? 'Available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'location': location,
      'postedAt': postedAt,
      'donatorId': donatorId,
      'donatorName': donatorName,
      'status': status,
    };
  }

  // 👇 ADICIONEI ESTE MÉTODO CORRIGIDO E COMPLETO 👇
  /// Cria uma cópia do objeto Product, permitindo alterar alguns de seus valores.
  Product copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    String? location,
    Timestamp? postedAt,
    String? donatorId,
    String? donatorName,
    String? status,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      location: location ?? this.location,
      postedAt: postedAt ?? this.postedAt,
      donatorId: donatorId ?? this.donatorId,
      donatorName: donatorName ?? this.donatorName,
      status: status ?? this.status,
    );
  }
}