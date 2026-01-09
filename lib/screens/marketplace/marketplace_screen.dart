import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:ecommunity/repositories/user_repository.dart';
import 'package:ecommunity/screens/marketplace/edit_product_screen.dart';
import 'package:ecommunity/screens/marketplace/product_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_product_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ProductRepository _repository = ProductRepository();
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Set<String> _interestedProductIds = {};

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final fetchedProducts = await _repository.getAvailableProducts();
      if (_currentUserId != null) {
        final myInterests = await _userRepository.getUserInterests(_currentUserId!);
        _interestedProductIds = myInterests.map((p) => p.id).toSet();
      }
      if (mounted) {
        setState(() {
          _products = fetchedProducts;
          _filteredProducts = fetchedProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  void _updateProductInLists(Product updatedProduct) {
    final findAndUpdate = (List<Product> list) {
      final index = list.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        list[index] = updatedProduct;
      }
    };
    setState(() {
      findAndUpdate(_products);
      findAndUpdate(_filteredProducts);
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.title.toLowerCase().contains(query) ||
               product.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  Future<void> _deleteProduct(Product product) async {
    // ... (restante do código permanece o mesmo)
  }

  void _showManageProductDialog(Product product) {
     // ... (restante do código permanece o mesmo)
  }

  void _showSelectReceiverDialog(Product product) {
     // ... (restante do código permanece o mesmo)
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
    ).then((_) => _fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'marketplace_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          ).then((value) {
            // Otimização para adicionar item
            if (value is Product) {
              setState(() {
                _products.insert(0, value);
                _filterProducts(); // Re-aplica o filtro
              });
            }
          });
        },
        tooltip: 'Doar um produto',
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // ... (restante do código permanece o mesmo)
        if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleSearch,
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Pesquisar por título ou descrição...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('Doações da Comunidade'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
          tooltip: 'Pesquisar',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchProducts,
          tooltip: 'Atualizar',
        ),
      ],
    );
  }

  Widget _buildBody() {
    // ... (restante do código permanece o mesmo)
        if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_products.isEmpty) {
      return const Center(child: Text('Nenhum produto para doação no momento.'));
    }
    if (_filteredProducts.isEmpty && _isSearching) {
      return const Center(child: Text('Nenhum produto encontrado.'));
    }
    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_filteredProducts[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    bool isOwner = _currentUserId == product.donatorId;
    bool isInterested = _interestedProductIds.contains(product.id);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Container(height: 200, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.image, size: 50)),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => EditProductScreen(product: product)),
                                );
                                if (result is Product) {
                                  _updateProductInLists(result);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showManageProductDialog(product),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Doador(a): ${product.donatorName}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openProductDetail(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInterested ? Colors.green : null,
                        foregroundColor: isInterested ? Colors.white : null,
                      ),
                      child: Text(
                          isOwner 
                              ? 'Ver Detalhes' 
                              : (isInterested ? 'Interessado (Ver Detalhes)' : 'Tenho Interesse')
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
