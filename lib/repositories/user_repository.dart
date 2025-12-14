import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/models/product_model.dart';

class UserRepository {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> addUser(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toMap());
    } catch (e) {
      print("Error adding user to Firestore: $e");
      throw e;
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
      print("Firebase Error getting user by ID: ${e.message}");
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
      print("Firebase Error getting user by email: ${e.message}");
      return null;
    }
  }

  Future<void> updateUser(User user) async {
    await _usersCollection.doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  // --- FUNÇÕES DE INTERESSE (ATUALIZADAS) ---

  /// Alterna o interesse: Se não existe, adiciona. Se existe, remove.
  /// Retorna TRUE se ficou interessado, FALSE se removeu o interesse.
  Future<bool> toggleInterest(String userId, Product product) async {
    try {
      final docRef = _usersCollection
          .doc(userId)
          .collection('interests')
          .doc(product.id);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Já tem interesse -> Remover
        await docRef.delete();
        return false; // Não está mais interessado
      } else {
        // Não tem interesse -> Adicionar
        await docRef.set({
          ...product.toMap(),
          'interestedAt': FieldValue.serverTimestamp(),
        });
        return true; // Agora está interessado
      }
    } catch (e) {
      print("Erro ao alternar interesse: $e");
      throw Exception('Erro ao atualizar interesse.');
    }
  }

  /// Verifica se o usuário já tem interesse em um produto específico
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

  /// Busca a lista de produtos que o usuário demonstrou interesse
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
      print("Erro ao buscar interesses: $e");
      return [];
    }
  }
}
