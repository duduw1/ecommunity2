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
      setState(() { _isLoading = true; });
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
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
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
    try {
      await _repository.deleteProduct(product);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${product.title}" foi excluído.')),
        );
      }
      _fetchProducts();
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir produto: $e')),
        );
      }
    }
  }

  void _showManageProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gerenciar Produto'),
        content: const Text('O item foi doado ou você deseja apenas excluí-lo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteProduct(product);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showSelectReceiverDialog(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Marcar como Doado'),
          ),
        ],
      ),
    );
  }

  void _showSelectReceiverDialog(Product product) {
    final emailController = TextEditingController();
    int selectedRating = 5;

    // Guardar o ScaffoldMessenger do contexto PAI para usar depois que o dialog fechar
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Quem recebeu a doação?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Digite o e-mail da pessoa que recebeu o item.'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail do recebedor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  const Text("Avalie o recebedor:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  Center(child: Text("$selectedRating/5 estrelas", style: TextStyle(color: Colors.grey[600]))),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    // Normaliza para lowercase para facilitar a busca
                    final email = emailController.text.trim().toLowerCase(); 
                    if (email.isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Digite um email.')));
                      return;
                    }

                    Navigator.pop(dialogContext); // Fecha dialog
                    messenger.showSnackBar(const SnackBar(content: Text('Processando doação...')));

                    try {
                      // Busca usuário pelo email (case sensitive pode ser problema, então tentamos tratar)
                      // O ideal é que todos emails no banco estejam salvos padronizados.
                      // Aqui vamos tentar buscar exatamente como digitado (já com toLowerCase)
                      
                      // Nota: Se o banco tem emails com maiúsculas, 'getUserByEmail' pode falhar se usarmos lowercase aqui.
                      // Vou tentar buscar primeiro com lowercase. Se falhar, poderia tentar original, mas vamos assumir padrão.
                      
                      final user = await _userRepository.getUserByEmail(email);
                      
                      if (user == null) {
                        messenger.showSnackBar(const SnackBar(content: Text('Usuário não encontrado com este e-mail. Verifique a grafia.')));
                        return;
                      }

                      if (user.id == product.donatorId) {
                        messenger.showSnackBar(const SnackBar(content: Text('Você não pode doar para si mesmo!')));
                        return;
                      }

                      // Marca como doado
                      await _repository.markAsDonated(
                        productId: product.id, 
                        receiverId: user.id, 
                        donatorId: product.donatorId,
                        donatorName: product.donatorName,
                        ratingToReceiver: selectedRating,
                      );
                      
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Doação registrada! Avaliação enviada e +50 pontos ganhos! 🎉'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      _fetchProducts(); // Atualiza lista
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
                    }
                  },
                  child: const Text('Confirmar Doação'),
                ),
              ],
            );
          }
        );
      },
    );
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
          ).then((_) => _fetchProducts());
        },
        tooltip: 'Doar um produto',
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => EditProductScreen(product: product)),
                                ).then((_) => _fetchProducts());
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
