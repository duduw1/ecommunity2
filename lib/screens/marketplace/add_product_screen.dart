import 'dart:typed_data';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to get user name
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productRepository = ProductRepository();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = ['Móveis', 'Eletrônicos', 'Roupas', 'Livros', 'Outros'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? selectedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (selectedImage != null) {
        final bytes = await selectedImage.readAsBytes();
        setState(() {
          _imageFile = selectedImage;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _submitForm() async {
    // 1. Validate inputs
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma imagem.')),
      );
      return;
    }

    // 2. Direct Auth Check (No SessionManager)
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 3. Fetch current User Data from Firestore to get the Name
      // We do this to ensure we have the correct display name associated with the UID
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      final String userName = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Anônimo'
          : 'Anônimo';

      // 4. Upload Image to Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${firebaseUser.uid}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child('product_images').child(fileName);

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final UploadTask uploadTask = storageRef.putData(_imageBytes!, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();

      // 5. Prepare Product Data
      final Map<String, dynamic> productData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'donatorId': firebaseUser.uid, // Use Auth UID directly
        'donatorName': userName,       // Use fetched name
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 6. Save to Firestore via Repository
      await _productRepository.addProduct(productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto adicionado com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Erro ao submeter o formulário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar produto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doar um Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageBytes == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Clique para adicionar uma foto'),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título do Item', border: OutlineInputBorder()),
                validator: (value) => value!.trim().isEmpty ? 'Título é obrigatório.' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value!.trim().isEmpty ? 'Descrição é obrigatória.' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Sua Cidade/Bairro', border: OutlineInputBorder()),
                validator: (value) => value!.trim().isEmpty ? 'Localização é obrigatória.' : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione uma Categoria'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Categoria é obrigatória.' : null,
              ),
              const SizedBox(height: 32),

              // Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text('Doar Item', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}