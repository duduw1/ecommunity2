import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/models/product_model.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class UserRepository {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> addUser(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toMap());
    } catch (e) {
      debugPrint("Error adding user to Firestore: $e");
      rethrow; // Melhor prática: rethrow preserva o stack trace original
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        return User.fromFirestore(docSnapshot);
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint("Firebase Error getting user by ID: ${e.message}");
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return User.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint("Firebase Error getting user by email: ${e.message}");
      return null;
    }
  }

  /// Busca lista de usuários por seus IDs (com suporte a chunks de 10)
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    List<User> users = [];

    // Firestore 'whereIn' suporta no máximo 10 valores
    for (var i = 0; i < userIds.length; i += 10) {
      var end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      var chunk = userIds.sublist(i, end);

      try {
        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        users.addAll(
            querySnapshot.docs.map((doc) => User.fromFirestore(doc)).toList()
        );
      } catch (e) {
        debugPrint("Error fetching users chunk: $e");
      }
    }

    return users;
  }

  Future<void> updateUser(User user) async {
    await _usersCollection.doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  // --- FUNÇÕES DE PONTOS (NOVO) ---
  
  /// Adiciona pontos ao usuário
  Future<void> addPoints(String userId, int pointsToAdd) async {
    try {
      await _usersCollection.doc(userId).update({
        'points': FieldValue.increment(pointsToAdd),
      });
    } catch (e) {
      debugPrint("Erro ao adicionar pontos: $e");
    }
  }

  // --- FUNÇÕES DE INTERESSE ---

  Future<bool> toggleInterest(String userId, Product product) async {
    try {
      final docRef = _usersCollection
          .doc(userId)
          .collection('interests')
          .doc(product.id);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.delete();
        return false; 
      } else {
        await docRef.set({
          ...product.toMap(),
          'interestedAt': FieldValue.serverTimestamp(),
        });
        return true; 
      }
    } catch (e) {
      debugPrint("Erro ao alternar interesse: $e");
      throw Exception('Erro ao atualizar interesse.');
    }
  }

  Future<bool> hasInterest(String userId, String productId) async {
    try {
      final doc = await _usersCollection
          .doc(userId)
          .collection('interests')
          .doc(productId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<List<Product>> getUserInterests(String userId) async {
    try {
      final querySnapshot = await _usersCollection
          .doc(userId)
          .collection('interests')
          .orderBy('interestedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar interesses: $e");
      return [];
    }
  }

  // --- FUNÇÕES DE SEGUIR ---

  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return false;

    final currentUserRef = _usersCollection.doc(currentUserId);
    final targetUserRef = _usersCollection.doc(targetUserId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final currentUserSnapshot = await transaction.get(currentUserRef);

      if (!currentUserSnapshot.exists) {
        throw Exception("Usuário atual não encontrado.");
      }

      final currentUserData = currentUserSnapshot.data() as Map<String, dynamic>;
      final followingList = List<String>.from(currentUserData['following'] ?? []);
      
      final isFollowing = followingList.contains(targetUserId);

      if (isFollowing) {
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayRemove([targetUserId])
        });
        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayRemove([currentUserId])
        });
        return false;
      } else {
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayUnion([targetUserId])
        });
        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayUnion([currentUserId])
        });
        return true;
      }
    });
  }
}
