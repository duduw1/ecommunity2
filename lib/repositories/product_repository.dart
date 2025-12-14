import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/product_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
      print("Erro ao buscar produtos: $e");
      return [];
    }
  }

  // --- NOVA FUNÇÃO ---
  /// Busca produtos doados por um usuário específico
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
      print("Erro ao buscar minhas doações: $e");
      return [];
    }
  }

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

  Future<void> updateProductStatus(String productId, String newStatus) async {
    try {
      await _productsCollection.doc(productId).update({'status': newStatus});
    } catch (e) {
      print("Erro ao atualizar status do produto: $e");
      throw Exception('Não foi possível atualizar o produto.');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final collection = _productsCollection;
      final productData = product.toMap();
      await collection.doc(product.id).update(productData);
    } catch (e) {
      print("Erro ao atualizar produto no Firestore: $e");
      throw Exception('Não foi possível atualizar o produto. Tente novamente.');
    }
  }

  Future<void> deleteProduct(Product product) async {
    try {
      // 1. Excluir a imagem do Firebase Storage
      if (product.imageUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(product.imageUrl);
          await ref.delete();
        } on FirebaseException catch (e) {
          print("Erro ao excluir imagem (pode não existir): $e");
        }
      }

      // 2. Excluir o documento do Firestore
      await _productsCollection.doc(product.id).delete();

    } catch (e) {
      print("Erro ao excluir produto: $e");
      throw Exception('Não foi possível excluir o produto.');
    }
  }
}
