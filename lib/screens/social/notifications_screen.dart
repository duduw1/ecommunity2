import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/notification_model.dart';
import 'package:ecommunity/repositories/notification_repository.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatDateTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Faça login para ver as notificações."));
    }

    final NotificationRepository repository = NotificationRepository();
    final ProductRepository productRepository = ProductRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Notificações")),
      body: StreamBuilder<List<AppNotification>>(
        stream: repository.getUserNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhuma notificação por enquanto.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification, repository, productRepository);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, AppNotification notification, NotificationRepository repo, ProductRepository productRepo) {
    
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'message':
        icon = Icons.message;
        iconColor = Colors.green;
        break;
      case 'interest':
        icon = Icons.volunteer_activism;
        iconColor = Colors.amber;
        break;
      case 'rate_item': // Novo tipo
        icon = Icons.star;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (direction) {
        // Implementar delete se necessário
      },
      child: Container(
        color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(text: notification.fromUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: " ${notification.message}"),
              ],
            ),
          ),
          subtitle: Text(
            _formatDateTime(notification.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () {
            repo.markAsRead(notification.id);
            
            if (notification.type == 'rate_item') {
               _showRateItemDialog(context, notification, productRepo);
            }
            // Outras navegações...
          },
        ),
      ),
    );
  }

  void _showRateItemDialog(BuildContext context, AppNotification notification, ProductRepository productRepo) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Avaliar Item Recebido'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Como estava o estado do item que você recebeu?'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setStateDialog(() => rating = index + 1);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comentário (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await productRepo.rateItem(notification.relatedId, rating, commentController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Obrigado pela avaliação!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                      }
                    }
                  },
                  child: const Text('Enviar Avaliação'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
