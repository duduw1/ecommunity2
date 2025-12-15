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
  List<Product> _myReceived = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productRepository.getProductsByDonator(_userId),
        _userRepository.getUserInterests(_userId),
        _productRepository.getProductsReceivedBy(_userId!),
      ]);

      if (mounted) {
        setState(() {
          _myDonations = results[0];
          _myInterests = results[1];
          _myReceived = results[2];
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
            Tab(text: 'Doações', icon: Icon(Icons.volunteer_activism)),
            Tab(text: 'Interesses', icon: Icon(Icons.favorite)),
            Tab(text: 'Recebidos', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_myDonations, type: 'donation'),
                _buildProductList(_myInterests, type: 'interest'),
                _buildProductList(_myReceived, type: 'received'),
              ],
            ),
    );
  }

  Widget _buildProductList(List<Product> products, {required String type}) {
    String emptyMessage;
    IconData emptyIcon;

    if (type == 'donation') {
      emptyMessage = 'Você ainda não fez doações.';
      emptyIcon = Icons.volunteer_activism;
    } else if (type == 'interest') {
      emptyMessage = 'Você não tem interesses registrados.';
      emptyIcon = Icons.favorite_border;
    } else {
      emptyMessage = 'Você ainda não recebeu doações.';
      emptyIcon = Icons.inventory_2_outlined;
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        String subtitle;
        
        if (type == 'donation') {
          subtitle = 'Status: ${product.status}';
        } else if (type == 'received') {
          subtitle = 'Doador: ${product.donatorName}';
        } else {
          subtitle = 'Doador: ${product.donatorName}';
        }

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
            subtitle: Text(subtitle),
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
