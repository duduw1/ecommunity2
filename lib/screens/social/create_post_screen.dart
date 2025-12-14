import 'dart:io';

import 'package:ecommunity/repositories/post_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postTextController = TextEditingController();
  final _postRepository = PostRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isPosting = false;
  File? _selectedImage;

  @override
  void dispose() {
    _postTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child(fileName);
      
      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Erro upload imagem: $e");
      return null;
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Você precisa estar logado.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      // 1. Busca dados do usuário (Nome)
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final String userName = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Anônimo'
          : 'Anônimo';

      // 2. Upload da imagem (se houver)
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          throw Exception("Falha no upload da imagem");
        }
      }

      // 3. Salva o Post
      await _postRepository.addPost(
        userId: user.uid,
        userName: userName,
        text: _postTextController.text.trim(),
        imageUrl: imageUrl,
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
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                foregroundColor: _isPosting ? colorScheme.onSurface.withOpacity(0.38) : colorScheme.primary,
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                    )
                  : const Text('PUBLICAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  if ((value == null || value.trim().isEmpty) && _selectedImage == null) {
                    return 'Escreva algo ou adicione uma foto.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              if (_selectedImage != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    IconButton(
                      icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.green),
              onPressed: _pickImage,
              tooltip: 'Adicionar Foto',
            ),
            const Text("Adicionar Foto", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
