import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/marketplace/product_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductRepository _productRepository = ProductRepository();
  final UserRepository _userRepository = UserRepository();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  List<Product> _myDonations = [];
  List<Product> _myInterests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      // Busca Doações e Interesses em paralelo
      final results = await Future.wait([
        _productRepository.getProductsByDonator(_userId!),
        _userRepository.getUserInterests(_userId!),
      ]);

      if (mounted) {
        setState(() {
          _myDonations = results[0];
          _myInterests = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar atividades: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Atividades'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Minhas Doações', icon: Icon(Icons.volunteer_activism)),
            Tab(text: 'Meus Interesses', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_myDonations, isDonation: true),
                _buildProductList(_myInterests, isDonation: false),
              ],
            ),
    );
  }

  Widget _buildProductList(List<Product> products, {required bool isDonation}) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDonation ? Icons.volunteer_activism : Icons.favorite_border,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isDonation
                  ? 'Você ainda não fez doações.'
                  : 'Você não tem interesses registrados.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.image)),
            ),
            title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isDonation ? product.status : 'Doador: ${product.donatorName}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
