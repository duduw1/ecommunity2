import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/product_model.dart'; // MODIFICADO: Importa o novo modelo.

// MODIFICADO: A classe agora se chama ProductRepository.
class ProductRepository {
  // MODIFICADO: A coleção no Firestore agora se chama 'products'. É mais limpo.
  final _productsCollection = FirebaseFirestore.instance.collection('products');

  /// MODIFICADO: O método agora retorna uma lista de Products.
  Future<List<Product>> getAvailableProducts() async {
    try {
      final querySnapshot = await _productsCollection
          .where('status', isEqualTo: 'Available')
          .orderBy('postedAt', descending: true)
          .get();

      // MODIFICADO: Mapeia para o objeto Product.
      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Erro ao buscar produtos: $e");
      return [];
    }
  }

  /// MODIFICADO: O método agora adiciona um produto.
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      productData['postedAt'] = FieldValue.serverTimestamp();
      productData['status'] = 'Available';
      await _productsCollection.add(productData);
    } catch (e) {
      print("Erro ao adicionar produto: $e");
      throw Exception('Não foi possível adicionar o produto.');
    }
  }

  /// MODIFICADO: O método atualiza o status de um produto.
  Future<void> updateProductStatus(String productId, String newStatus) async {
    try {
      await _productsCollection.doc(productId).update({'status': newStatus});
    } catch (e) {
      print("Erro ao atualizar status do produto: $e");
      throw Exception('Não foi possível atualizar o produto.');
    }
  }
}