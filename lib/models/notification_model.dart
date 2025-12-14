import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId; // Quem recebe a notificação
  final String fromUserName; // Quem gerou a ação (nome para exibir rápido)
  final String type; // 'like', 'comment', 'interest', 'message'
  final String message; // Texto descritivo
  final String relatedId; // ID do post, produto ou chat relacionado
  final bool isRead;
  final Timestamp createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.fromUserName,
    required this.type,
    required this.message,
    required this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      fromUserName: data['fromUserName'] ?? 'Alguém',
      type: data['type'] ?? 'info',
      message: data['message'] ?? '',
      relatedId: data['relatedId'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
