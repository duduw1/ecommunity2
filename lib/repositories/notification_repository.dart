import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/notification_model.dart';

class NotificationRepository {
  final CollectionReference _notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  /// Envia uma notificação para um usuário específico
  Future<void> sendNotification({
    required String toUserId,
    required String fromUserName,
    required String type, // 'like', 'comment', 'interest', 'message'
    required String message,
    required String relatedId,
  }) async {
    try {
      await _notificationsCollection.add({
        'userId': toUserId,
        'fromUserName': fromUserName,
        'type': type,
        'message': message,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erro ao enviar notificação: $e");
    }
  }

  /// Busca as notificações do usuário (Stream para tempo real)
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Marca uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({'isRead': true});
  }
}
