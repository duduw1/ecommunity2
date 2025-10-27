import 'dart:typed_data'; // Importa Uint8List
import 'package:ecommunity/models/user_model.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:ecommunity/providers/auth_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  Uint8List? _imageBytes; // Para exibição e upload cross-platform
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

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tirar Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? selectedImage = await picker.pickImage(
        source: source,
        imageQuality: 80, // Comprime a imagem para 80% da qualidade original
        maxWidth: 800,    // Redimensiona a largura máxima para 800px
      );
      if (selectedImage != null) {
        final bytes = await selectedImage.readAsBytes();
        setState(() {
          _imageFile = selectedImage;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma imagem.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_imageFile?.name ?? 'image.jpg'}';
      final Reference storageRef = FirebaseStorage.instance.ref().child('product_images').child(fileName);

      // Usa putData, que funciona em todas as plataformas
      final UploadTask uploadTask = storageRef.putData(_imageBytes!);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();
      print('Upload da imagem concluído: $imageUrl');

      final User? currentUser = SessionManager().currentUser;
      if (currentUser == null) {
        throw Exception('Sessão de usuário não encontrada.');
      }

      final Map<String, dynamic> productData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'donatorId': currentUser.id,
        'donatorName': currentUser.name,
      };

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
              GestureDetector(
                onTap: _showImagePickerOptions,
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
              // --- O resto do formulário permanece igual ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título do Item'),
                validator: (value) => value!.trim().isEmpty ? 'Título é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value!.trim().isEmpty ? 'Descrição é obrigatória.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Sua Cidade/Bairro'),
                validator: (value) => value!.trim().isEmpty ? 'Localização é obrigatória.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
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
