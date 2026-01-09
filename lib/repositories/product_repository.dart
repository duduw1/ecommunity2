import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addProduct(Map<String, dynamic> data) async {
    final docRef = await _db.collection('products').add({
      ...data,
      'postedAt': FieldValue.serverTimestamp(),
      'status': 'Available',
    });
    return docRef.id;
  }

  Future<void> updateProduct(Product product) {
    // CORRIGIDO: de toJson para toMap
    return _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(Product product) {
    return _db.collection('products').doc(product.id).delete();
  }

  Future<List<Product>> getAvailableProducts() async {
    final snapshot = await _db
        .collection('products')
        .where('status', isEqualTo: 'Available')
        .orderBy('postedAt', descending: true)
        .get();
    // CORRIGIDO: de fromSnapshot para fromFirestore
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // CORRIGIDO: Nome da função de getDonationReviews para getProductsByDonator
  Future<List<Product>> getProductsByDonator(String userId) async {
    final snapshot = await _db
        .collection('products')
        .where('donatorId', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // CORRIGIDO: Nova função getProductsReceivedBy
  Future<List<Product>> getProductsReceivedBy(String userId) async {
    final snapshot = await _db
        .collection('products')
        .where('receiverId', isEqualTo: userId)
        .orderBy('donatedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<List<Product>> getDonationReviews(String userId) async {
    final snapshot = await _db
        .collection('products')
        .where('donatorId', isEqualTo: userId)
        .where('status', isEqualTo: 'Donated')
        .where('receiverRating', isGreaterThan: 0)
        .orderBy('receiverRating', descending: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<List<Product>> getReviewsMadeByUser(String userId) async {
    final snapshot = await _db
        .collection('products')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'Donated')
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<void> markAsDonated({
    required String productId, 
    required String receiverId, 
    required String donatorId,
    required String donatorName, 
    required int ratingToReceiver,
  }) async {
    final productRef = _db.collection('products').doc(productId);
    final donatorRef = _db.collection('users').doc(donatorId);

    await _db.runTransaction((transaction) async {
      transaction.update(productRef, {
        'status': 'Donated',
        'receiverId': receiverId,
        'receiverRating': ratingToReceiver, 
        'donatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(donatorRef, {
        'points': FieldValue.increment(50),
      });
    });
  }

  // CORRIGIDO: Nome da função de updateReview para rateItem
  Future<void> rateItem(
    String productId,
    int rating,
    String comment,
  ) async {
     final productRef = _db.collection('products').doc(productId);

     await productRef.update({
       'receiverRating': rating,
       'receiverComment': comment,
     });
  }

   Future<void> updateReview({
    required String productId,
    required int oldRating,
    required int newRating,
    required String newComment
  }) async {
     final productRef = _db.collection('products').doc(productId);

     await productRef.update({
       'receiverRating': newRating,
       'receiverComment': newComment,
     });
  }
}
