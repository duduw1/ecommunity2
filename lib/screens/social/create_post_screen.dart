import 'package:ecommunity/repositories/post_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';     // Import Auth
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postTextController = TextEditingController();

  // Instance of repository
  final _postRepository = PostRepository();

  bool _isPosting = false;

  @override
  void dispose() {
    _postTextController.dispose();
    super.dispose();
  }

  /// Handles post submission logic
  Future<void> _submitPost() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;

    // 2. Get Current User from Firebase Auth
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Você precisa estar logado.')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      // 3. Fetch User Profile to get the Name
      // We want to store the author's name inside the post document
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final String userName = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Anônimo'
          : 'Anônimo';

      // 4. Send to Repository
      // I am assuming your PostRepository takes these parameters.
      // If it takes a Map, you can adjust it similar to the AddProductScreen example.
      await _postRepository.addPost(
        userId: user.uid,
        userName: userName, // Pass the name so it appears in the feed
        text: _postTextController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicação criada com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao criar publicação: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get colors from theme to ensure visibility on light/dark mode
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Publicação'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isPosting ? null : _submitPost,
              style: TextButton.styleFrom(
                // Use primary color for text, or grey if disabled
                foregroundColor: _isPosting ? colorScheme.onSurface.withOpacity(0.38) : colorScheme.primary,
              ),
              child: _isPosting
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
                  : const Text('PUBLICAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _postTextController,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'No que você está pensando?',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey)
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A publicação não pode estar vazia.';
                  }
                  if (value.length > 280) {
                    return 'A publicação não pode ter mais de 280 caracteres.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}