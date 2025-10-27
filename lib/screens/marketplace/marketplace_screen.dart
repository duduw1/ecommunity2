import 'package:ecommunity/models/product_model.dart';
import 'package:ecommunity/repositories/product_repository.dart';
import 'package:flutter/material.dart';

import 'add_product_Screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ProductRepository _repository = ProductRepository();

  // MODIFICAÇÃO PRINCIPAL: Controlamos o estado manualmente.
  bool _isLoading =
      true; // Inicia como true para mostrar o spinner ao abrir a tela.
  List<Product> _products = []; // A lista de produtos começa vazia.

  @override
  void initState() {
    super.initState();
    // Inicia a busca de dados assim que a tela é criada.
    _fetchProducts();
  }

  /// Busca os produtos do repositório e atualiza o estado da tela.
  Future<void> _fetchProducts() async {
    // Garante que o spinner seja exibido se a função for chamada novamente (ex: refresh).
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final fetchedProducts = await _repository.getAvailableProducts();
      // Atualiza a lista de produtos e desativa o loading.
      setState(() {
        _products = fetchedProducts;
        _isLoading = false;
      });
    } catch (e) {
      // Em caso de erro, para o loading e mostra uma mensagem.
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doações da Comunidade'),
        actions: [
          // O IconButton de refresh agora simplesmente chama _fetchProducts.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      // O corpo agora é construído com base no estado _isLoading.
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'marketplace_fab', // Um nome único para este botão

        onPressed: () {
          // Navega para a tela de adicionar produto
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              )
              .then((_) {
                // BÔNUS: Atualiza a lista após voltar da tela de adição.
                _fetchProducts();
              });
        },
        tooltip: 'Doar um produto',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Método auxiliar para construir o corpo da tela com base no estado.
  Widget _buildBody() {
    // 1. Se estiver carregando, mostra o spinner.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Se a lista estiver vazia após o carregamento, mostra a mensagem.
    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchProducts, // Permite "puxar para atualizar"
        child: const Center(
          child: SingleChildScrollView(
            // Garante que a mensagem seja rolável em telas pequenas
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Nenhum produto para doação no momento.\nSeja o primeiro!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    // 3. Se tivermos produtos, mostra a lista.
    return RefreshIndicator(
      onRefresh: _fetchProducts, // Adiciona o gesto de "puxar para atualizar"
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_products[index]);
        },
      ),
    );
  }

  /// Constrói o card para cada produto (sem alterações aqui).
  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              product.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print("Image.network ERRO: $error");

                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 50,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin_circle_outlined,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Doador(a): ${product.donatorName} em ${product.location}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navegar para uma tela de detalhes do produto.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Você demonstrou interesse em: ${product.title}',
                          ),
                        ),
                      );
                    },
                    child: const Text('Tenho Interesse'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
