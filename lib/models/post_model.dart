import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName; // <--- NEW: Store author name to avoid extra lookups
  final String text;
  final Timestamp createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.userName, // <--- Required
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName, // <--- Save it
      'text': text,
      'createdAt': createdAt,
    };
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anônimo', // <--- Load it (default to Anonymous if missing)
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}