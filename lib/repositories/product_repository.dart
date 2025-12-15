import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/product_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Import para debugPrint

class ProductRepository {
  final _productsCollection = FirebaseFirestore.instance.collection('products');

  Future<List<Product>> getAvailableProducts() async {
    try {
      final querySnapshot = await _productsCollection
          .where('status', isEqualTo: 'Available')
          .orderBy('postedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar produtos: $e");
      return [];
    }
  }

  /// Busca produtos doados por um usuário específico (Histórico de Doações)
  Future<List<Product>> getProductsByDonator(String donatorId) async {
    try {
      final querySnapshot = await _productsCollection
          .where('donatorId', isEqualTo: donatorId)
          .orderBy('postedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar minhas doações: $e");
      return [];
    }
  }

  /// Busca as avaliações recebidas pelo usuário (como doador)
  /// Retorna os produtos que ele doou e que foram avaliados
  Future<List<Product>> getDonationReviews(String userId) async {
    try {
      // Busca todos os doados
      final querySnapshot = await _productsCollection
          .where('donatorId', isEqualTo: userId)
          .where('status', isEqualTo: 'Donated') 
          .orderBy('postedAt', descending: true)
          .get();

      final allDonated = querySnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      // Filtra apenas os que têm avaliação
      return allDonated.where((p) => p.receiverRating != null).toList();
    } catch (e) {
      debugPrint("Erro ao buscar avaliações recebidas: $e");
      return [];
    }
  }

  /// Busca as avaliações que o usuário FEZ (itens que ele recebeu e avaliou)
  Future<List<Product>> getReviewsMadeByUser(String userId) async {
    try {
      final allReceived = await getProductsReceivedBy(userId);
      // Filtra apenas os que já foram avaliados pelo usuário
      return allReceived.where((p) => p.receiverRating != null).toList();
    } catch (e) {
      debugPrint("Erro ao buscar avaliações feitas: $e");
      return [];
    }
  }

  /// Busca produtos recebidos por um usuário (Histórico de Recebidos)
  Future<List<Product>> getProductsReceivedBy(String userId) async {
    try {
      final querySnapshot = await _productsCollection
          .where('receiverId', isEqualTo: userId)
          .orderBy('donatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Erro ao buscar recebidos: $e");
      return [];
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      productData['postedAt'] = FieldValue.serverTimestamp();
      productData['status'] = 'Available';
      await _productsCollection.add(productData);
    } catch (e) {
      debugPrint("Erro ao adicionar produto: $e");
      throw Exception('Não foi possível adicionar o produto.');
    }
  }

  Future<void> updateProductStatus(String productId, String newStatus) async {
    try {
      await _productsCollection.doc(productId).update({'status': newStatus});
    } catch (e) {
      debugPrint("Erro ao atualizar status do produto: $e");
      throw Exception('Não foi possível atualizar o produto.');
    }
  }

  Future<void> markAsDonated({
    required String productId,
    required String receiverId,
    required String donatorId,
    required String donatorName,
    required int ratingToReceiver,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final productRef = _productsCollection.doc(productId);
      batch.update(productRef, {
        'status': 'Donated',
        'receiverId': receiverId,
        'donatedAt': FieldValue.serverTimestamp(),
      });

      final donatorRef = FirebaseFirestore.instance.collection('users').doc(donatorId);
      final receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverId);

      batch.update(donatorRef, {
        'points': FieldValue.increment(50),
      });

      batch.update(receiverRef, {
        'ratingSum': FieldValue.increment(ratingToReceiver),
        'ratingCount': FieldValue.increment(1),
      });

      final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': receiverId,
        'fromUserName': donatorName,
        'type': 'rate_item', 
        'message': 'Recebeu o item? Avalie a doação!',
        'relatedId': productId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("Erro ao marcar como doado: $e");
      throw Exception('Falha ao registrar doação.');
    }
  }

  Future<void> rateItem(String productId, int rating, String comment) async {
    try {
      final productRef = _productsCollection.doc(productId);
      
      final productSnapshot = await productRef.get();
      if (!productSnapshot.exists) throw Exception("Produto não encontrado");
      
      final data = productSnapshot.data() as Map<String, dynamic>;
      final donatorId = data['donatorId'];

      if (donatorId == null) throw Exception("Doador não identificado no produto");

      final batch = FirebaseFirestore.instance.batch();

      batch.update(productRef, {
        'receiverRating': rating,
        'receiverComment': comment,
      });

      final donatorRef = FirebaseFirestore.instance.collection('users').doc(donatorId);
      batch.update(donatorRef, {
        'ratingSum': FieldValue.increment(rating),
        'ratingCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("Erro ao avaliar item: $e");
      throw Exception('Falha ao enviar avaliação.');
    }
  }

  /// Permite editar uma avaliação feita anteriormente
  Future<void> updateReview({
    required String productId,
    required int oldRating,
    required int newRating,
    required String newComment,
  }) async {
    try {
      final productRef = _productsCollection.doc(productId);
      
      final productSnapshot = await productRef.get();
      if (!productSnapshot.exists) throw Exception("Produto não encontrado");
      
      final data = productSnapshot.data() as Map<String, dynamic>;
      final donatorId = data['donatorId'];
      if (donatorId == null) throw Exception("Doador não identificado");

      final batch = FirebaseFirestore.instance.batch();

      // 1. Atualizar produto
      batch.update(productRef, {
        'receiverRating': newRating,
        'receiverComment': newComment,
      });

      // 2. Atualizar user do doador (reputação)
      final donatorRef = FirebaseFirestore.instance.collection('users').doc(donatorId);
      final diff = newRating - oldRating;
      
      if (diff != 0) {
        batch.update(donatorRef, {
          'ratingSum': FieldValue.increment(diff),
          // ratingCount não muda pois é apenas edição
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Erro ao atualizar avaliação: $e");
      throw Exception('Falha ao atualizar avaliação.');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final collection = _productsCollection;
      final productData = product.toMap();
      await collection.doc(product.id).update(productData);
    } catch (e) {
      debugPrint("Erro ao atualizar produto no Firestore: $e");
      throw Exception('Não foi possível atualizar o produto. Tente novamente.');
    }
  }

  Future<void> deleteProduct(Product product) async {
    try {
      if (product.imageUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(product.imageUrl);
          await ref.delete();
        } on FirebaseException catch (e) {
          debugPrint("Erro ao excluir imagem (pode não existir): $e");
        }
      }
      await _productsCollection.doc(product.id).delete();
    } catch (e) {
      debugPrint("Erro ao excluir produto: $e");
      throw Exception('Não foi possível excluir o produto.');
    }
  }
}
