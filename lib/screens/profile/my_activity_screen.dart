import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:ecommunity/screens/marketplace/product_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  final ProductRepository _productRepository = ProductRepository();
  String? _userId;
  bool _isLoading = true;

  List<Product> _donatedProducts = [];
  List<Product> _receivedProducts = [];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<List<Product>>([
        _productRepository.getProductsByDonator(_userId!),
        _productRepository.getProductsReceivedBy(_userId!),
      ]);

      if (mounted) {
        setState(() {
          _donatedProducts = results[0];
          _receivedProducts = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar atividades: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minha Atividade'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Itens Doados'),
              Tab(text: 'Itens Recebidos'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildProductList(_donatedProducts, isDonated: true),
                  _buildProductList(_receivedProducts, isDonated: false),
                ],
              ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products, {required bool isDonated}) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          isDonated ? 'Você ainda não doou itens.' : 'Você ainda não recebeu itens.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          leading: product.imageUrl.isNotEmpty
              ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.image, size: 50),
          title: Text(product.title),
          subtitle: Text(isDonated ? 'Doado em ${product.donatedAt?.toDate()}' : 'Recebido em ${product.donatedAt?.toDate()}'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }
}
