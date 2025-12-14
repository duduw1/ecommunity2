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

  // --- NOVAS FUNÇÕES PARA INTERESSES ---

  /// Salva um produto na subcoleção 'interests' do usuário
  Future<void> addInterest(String userId, Product product) async {
    try {
      // Salvamos uma cópia dos dados do produto para facilitar a exibição
      // mesmo que o produto original mude, mantemos o registro do interesse naquele momento.
      await _usersCollection
          .doc(userId)
          .collection('interests')
          .doc(product.id)
          .set({
            ...product.toMap(),
            'interestedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print("Erro ao salvar interesse: $e");
      throw Exception('Não foi possível salvar o interesse.');
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
